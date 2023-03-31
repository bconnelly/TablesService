pipeline{
    agent{
        docker{
            image 'bryan949/fullstack-agent:0.1'
            args '-v /root/.m2:/root/.m2 \
                  -v /root/jenkins/restaurant-resources/:/root/jenkins/restaurant-resources/ \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  --privileged --env KOPS_STATE_STORE=' + env.KOPS_STATE_STORE + \
                  ' --env DOCKER_USER=' + env.DOCKER_USER + ' --env DOCKER_PASS=' + env.DOCKER_PASS
            alwaysPull true
        }
    }
    stages{
        stage('maven build and test, docker build and push'){
            steps{
                echo 'Packaging and testing:'
                sh '''
                    mvn verify
                    ls -alF
                '''
                stash includes: 'target/TablesService.war', name: 'war'

            }
        }
        stage('build docker images'){
            steps{
                dir(sh 'pwd'){
                    unstash: 'war'
                }
                sh '''
                    docker login --username=$DOCKER_USER --password=$DOCKER_PASS
                    cp /root/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /root/jenkins/restaurant-resources/context.xml .
                    cp /root/jenkins/restaurant-resources/server.xml .
                    ls -alF
                    docker build -t bryan949/fullstack-tables .
                    docker push bryan949/fullstack-tables:latest
                '''
            }
        }
        stage('configure cluster connection'){
            steps{
    	        sh '''
    	            ls -alF
	                kops export kubecfg --admin --name fullstack.k8s.local
	                if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
	                kubectl config set-context --current --namespace rc
	            '''
            }
        }
        stage('deploy services to cluster - rc namespace'){
            steps{
                sh '''
                    git clone https://github.com/bconnelly/Restaurant-k8s-components.git
                    find Restaurant-k8s-components -type f -path ./Restaurant-k8s-components -prune -o -name *.yaml -print | while read line; do yq -i '.metadata.namespace = "rc"' $line > /dev/null; done
                '''

//                     def fileString = sh(script: 'find Restaurant-k8s-components -type f -path ./Restaurant-k8s-components -prune -o -name *.yaml -print', returnStdout: true)
//                     echo fileString
//                     def files = fileString.split("\n")
//                     for(file in files){
//                         sh 'yq -i \'.metadata.namespace = \"rc\"\' ' + file
//                     }

                sh '''
                    yq -i '.metadata.namespace = "rc"' /root/jenkins/restaurant-resources/fullstack-secrets.yaml > /dev/null
                    kubectl apply -f /root/jenkins/restaurant-resources/fullstack-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components/ --recursive
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
                    kubectl get all --namespace rc
                '''
                stash includes: 'Restaurant-k8s-components/', name: 'k8s-components'
            }
        }
        stage('integration testing'){
            steps{
                sh '''
                    export LOAD_BALANCER="a886fa07e7d52403b85d9b8e2b9f6966-5002cd97a201173a.elb.us-east-1.amazonaws.com"
                    export SERVICE_PATH="RestaurantService"
                    export CUSTOMER_NAME=$RANDOM

                    SEAT_CUSTOMER_RESULT=$(curl -X POST -s -o /dev/null -w '%{http_code}' -d "firstName=$CUSTOMER_NAME&address=someaddress&cash=1.23" $LOAD_BALANCER/$SERVICE_PATH/seatCustomer)
                    if [ "$SEAT_CUSTOMER_RESULT" != 200 ]; then echo "$SEAT_CUSTOMER_RESULT"; fi

                    GET_OPEN_TABLES_RESULT="$(curl --head --write-out %{http_code} --silent --output /dev/null $LOAD_BALANCER/$SERVICE_PATH/getOpenTables)"
                    if [ "$GET_OPEN_TABLES_RESULT" != 200 ]; then echo "$GET_OPEN_TABLES_RESULT" && exit 1; fi

                    SUBMIT_ORDER_RESULT="$(curl -X POST --head --write-out %{http_code} --silent --output /dev/null -d "firstName=$CUSTOMER_NAME&tableNumber=1&dish=food&bill=1.23" $LOAD_BALANCER/$SERVICE_PATH/submitOrder)"
                    if [ "$SUBMIT_ORDER_RESULT" != 200 ]; then echo "$SUBMIT_ORDER_RESULT" && exit 1; fi

                    BOOT_CUSTOMER_RESULT="$(curl --head --write-out %{http_code} --silent --output /dev/null -d "firstName=$CUSTOMER_NAME" $LOAD_BALANCER/$SERVICE_PATH/bootCustomer)"
                    if [ "$BOOT_CUSTOMER_RESULT" != 200 ]; then echo "$GET_OPEN_TABLES_RESULT" && exit 1; fi
                '''
            }
        }
        stage('deploy to cluster - prod namespace'){
            steps{
                dir(.){
                    unstash: 'k8s-components'
                }

                sh '''
                    find Restaurant-k8s-components -type f -path ./Restaurant-k8s-components -prune -o -name *.yaml -print | while read line; do yq -i '.metadata.namespace = "prod"' $line > /dev/null; done
                    yq -i '.metadata.namespace = "prod"' /root/jenkins/restaurant-resources/fullstack-secrets.yaml > /dev/null

                    kubectl config set-context --current --namespace prod
                    kubectl apply -f /root/jenkins/restaurant-resources/fullstack-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components/ --recursive
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
                    kubectl get all --namespace prod
                '''
            }
        }
    }
    post{
        always{
            script{
                sh 'docker rmi bryan949/fullstack-tables'
                sh 'docker image prune'
            }

            cleanWs(cleanWhenAborted: true,
                    cleanWhenFailure: true,
                    cleanWhenNotBuilt: true,
                    cleanWhenSuccess: true,
                    cleanWhenUnstable: true,
                    cleanupMatrixParent: true,
                    deleteDirs: true,
                    disableDeferredWipeout: true
            )
        }
    }
}