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
                sh '''
                    docker login --username=$DOCKER_USER --password=$DOCKER_PASS
                    cp /root/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /root/jenkins/restaurant-resources/context.xml .
                    cp /root/jenkins/restaurant-resources/server.xml .
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
	                kubectl config set-context --current --namespace dev
	            '''
            }
        }
        stage('deploy services to cluster'){
            steps{
                script{
                    sh 'git clone https://github.com/bconnelly/Restaurant-k8s-components.git'

                    def fileString = sh(script: 'find Restaurant-k8s-components -type f -path ./Restaurant-k8s-components/.git -prune -o -name *.yaml -print', returnStdout: true)
                    echo fileString
                    def files = fileString.split("\n")
                    for(file in files){
                        sh 'yq e \'.metadata.namespace = \"dev\"\' ' + file
                    }

                    sh '''
                        kubectl apply -f /root/jenkins/restaurant-resources/fullstack-secrets.yaml
                        kubectl apply -f Restaurant-k8s-components/ --recursive
                        kubectl get deployment
                        kubectl rollout restart deployment tables-deployment
                    '''
                    sh '''
                        if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
                    '''
                }
            }
        }
        stage('integration testing'){
            steps{
                script{
                    sh '''
                        export LOAD_BALANCER="acb6d1c82bd774ba19f49b67f1d39a1c-6b63e6a07fb802ff.elb.us-east-1.amazonaws.com"
                        export SERVICE_PATH="RestaurantService"
                        export CUSTOMER_NAME=$RANDOM

                        if [ "$(curl -X POST --head --write-out %{http_code} --silent --output /dev/null -d \
                        "firstName=$CUSTOMER_NAME&address=someaddress&cash=1.23" $LOAD_BALANCER/$SERVICE_PATH/seatCustomer)" != 200 ]; then exit 1; fi
                        if [ "$(curl --head --write-out %{http_code} --silent --output /dev/null $LOAD_BALANCER/$SERVICE_PATH/getOpenTables)" != 200 ]; then exit 1; fi
                        if [ "$(curl -X POST --head --write-out %{http_code} --silent --output /dev/null -d \
                        "firstName=$CUSTOMER_NAME&tableNumber=1&dish=food&bill=1.23" $LOAD_BALANCER/$SERVICE_PATH/submitOrder)" != 200 ]; then exit 1; fi
                        if [ "$(curl --head --write-out %{http_code} --silent --output /dev/null $LOAD_BALANCER/$SERVICE_PATH/getOpenTables)" != 200 ]; then exit 1; fi
                    '''
                }
            }
        }
        stage('cleanup'){
            steps{
                script{
                    sh 'docker rmi bryan949/fullstack-tables'
                    sh 'docker image prune'
                }
            }
        }
    }
    post{
        always{

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