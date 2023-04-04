pipeline{
    agent{
        docker{
            image 'bryan949/fullstack-agent:0.1'
            args '-v /root/.m2:/root/.m2 \
                  -v /root/jenkins/restaurant-resources/:/root/jenkins/restaurant-resources/ \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  --privileged --env KOPS_STATE_STORE=' + env.KOPS_STATE_STORE + ' --env DOCKER_USER=' + \
                  env.DOCKER_USER + ' --env DOCKER_PASS=' + env.DOCKER_PASS
            alwaysPull true
        }
    }
    stages{
        stage('maven build and test, docker build and push'){
            steps{
                echo 'packaging and testing:'
                sh '''
                    mvn verify
                    ls -alF
                '''
//                 stash includes: 'target/TablesService.war', name: 'war'
                stash name: 'tables-repo'

            }
        }
        stage('build docker images'){
            steps{
                unstash 'tables-repo'
                sh '''
                    ls -alF
                    cat /root/jenkins/restaurant-resources/dockerhub-pass | docker login --username=$DOCKER_USER --password-stdin
                    cp /root/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /root/jenkins/restaurant-resources/context.xml .
                    cp /root/jenkins/restaurant-resources/server.xml .
                    cp target/TablesService.war .

                    docker build -t bryan949/fullstack-tables .
                    docker push bryan949/fullstack-tables:latest

                    rm tomcat-users.xml
                    rm context.xml
                    rm server.xml
                    rm TablesService.war
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
                    yq -i '.metadata.namespace = "rc"' /root/jenkins/restaurant-resources/fullstack-secrets.yaml > /dev/null

                    kubectl apply -f /root/jenkins/restaurant-resources/fullstack-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components/tables/
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
                '''
                stash includes: 'Restaurant-k8s-components/', name: 'k8s-components'
            }
        }
        stage('integration testing'){
//         gh auth login --with-token < /root/jenkins/restaurant-resources/github-pass
            steps{
                unstash 'tables-repo'
                withCredentials([gitUsernamePassword(credentialsId: 'GITHUB_USERPASS', gitToolName: 'Default')]) {
                    sh '''
                        git config --global user.name "bconnelly"
                        ls -alF
                        git checkout rc
                        git checkout master
                        git merge rc
                        git push origin master
                    '''
                }

                sh '''
                    export LOAD_BALANCER="a886fa07e7d52403b85d9b8e2b9f6966-682684080.us-east-1.elb.amazonaws.com"
                    export SERVICE_PATH="RestaurantService"
                    export CUSTOMER_NAME=$RANDOM

                    SEAT_CUSTOMER_RESULT=$(curl -X POST -s -o /dev/null -w '%{http_code}' -d "firstName=$CUSTOMER_NAME&address=someaddress&cash=1.23" $LOAD_BALANCER/$SERVICE_PATH/seatCustomer)
                     if [ "$SEAT_CUSTOMER_RESULT" != 200 ]; then echo "$SEAT_CUSTOMER_RESULT" && exit 1; fi

                    GET_OPEN_TABLES_RESULT="$(curl -s -o /dev/null -w %{http_code} $LOAD_BALANCER/$SERVICE_PATH/getOpenTables)"
                    if [ "$GET_OPEN_TABLES_RESULT" != 200 ]; then echo "$GET_OPEN_TABLES_RESULT" && exit 1; fi

                    SUBMIT_ORDER_RESULT="$(curl -X POST -s -o /dev/null -w %{http_code} -d "firstName=$CUSTOMER_NAME&tableNumber=1&dish=food&bill=1.23" $LOAD_BALANCER/$SERVICE_PATH/submitOrder)"
                    if [ "$SUBMIT_ORDER_RESULT" != 200 ]; then echo "$SUBMIT_ORDER_RESULT" && exit 1; fi

                    BOOT_CUSTOMER_RESULT="$(curl --limit-rate 1G -X POST -s -o /dev/null -w %{http_code} -d "firstName=$CUSTOMER_NAME" $LOAD_BALANCER/$SERVICE_PATH/bootCustomer)"
                    if [ "$BOOT_CUSTOMER_RESULT" != 200 ]; then echo "$GET_OPEN_TABLES_RESULT" && exit 1; fi
                '''

            }
        }
        stage('deploy to cluster - prod namespace'){
            steps{
                unstash 'k8s-components'
                sh '''
                    find Restaurant-k8s-components -type f -path ./Restaurant-k8s-components -prune -o -name *.yaml -print | while read line; do yq -i '.metadata.namespace = "prod"' $line > /dev/null; done
                    yq -i '.metadata.namespace = "prod"' /root/jenkins/restaurant-resources/fullstack-secrets.yaml > /dev/null

                    kubectl config set-context --current --namespace prod
                    kubectl apply -f /root/jenkins/restaurant-resources/fullstack-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components/tables/
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then echo "PROD FAILURE"; fi
                '''
            }
        }
    }
    post{
        failure{
            unstash 'tables-repo'
            sh '''
                ls -alF
                git checkout rc
                git checkout master
                git rev-list --left-right master...rc | while read line
                do
                    COMMIT=$(echo $line | sed 's/[^0-9a-f]*//g')
                    git revert $COMMIT --no-edit
                done
                git merge rc
                git push origin master
            '''
        }
        always{
            sh '''
                docker rmi bryan949/fullstack-tables
                docker image prune
            '''

            cleanWs(cleanWhenAborted: true,
                    cleanWhenFailure: true,
                    cleanWhenNotBuilt: true,
                    cleanWhenSuccess: true,
                    cleanWhenUnstable: true,
                    cleanupMatrixParent: true,
                    deleteDirs: true,
                    disableDeferredWipeout: true)
        }
    }
}