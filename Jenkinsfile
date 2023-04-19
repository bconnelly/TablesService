pipeline{
    agent{
        docker{
            image 'bryan949/fullstack-agent:0.3'
            args '-v /root/.m2:/root/.m2 \
                  -v /root/jenkins/restaurant-resources/:/root/jenkins/restaurant-resources/ \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  --privileged --env KOPS_STATE_STORE=${KOPS_STATE_STORE} \
                  --env DOCKER_USER=${DOCKER_USER} --env DOCKER_PASS=${DOCKER_PASS}'
            alwaysPull true
        }
    }
    environment{
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
    }
    stages{
        stage('maven build and test, docker build and push'){
            steps{
                sh '''
                    mvn verify
                '''
                stash name: 'tables-repo', useDefaultExcludes: false

            }
        }
        stage('build docker images'){
            steps{
                unstash 'tables-repo'
                sh '''
                    cat /root/jenkins/restaurant-resources/dockerhub-pass | docker login --username=$DOCKER_USER --password-stdin
                    cp /root/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /root/jenkins/restaurant-resources/context.xml .
                    cp /root/jenkins/restaurant-resources/server.xml .

                    docker build -t bryan949/fullstack-tables .
                    docker push bryan949/fullstack-tables:latest

                    rm tomcat-users.xml
                    rm context.xml
                    rm server.xml
                '''
            }
        }
        stage('configure cluster connection'){
            steps{
    	        sh '''
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

                    find Restaurant-k8s-components/tables -type f -path ./Restaurant-k8s-components/tables -prune -o -name *.yaml -print | while read line; do yq -i '.metadata.namespace = "rc"' $line > /dev/null; done
                    yq -i '.metadata.namespace = "rc"' /root/jenkins/restaurant-resources/fullstack-secrets.yaml > /dev/null
                    yq -i '.metadata.namespace = "rc"' Restaurant-k8s-components/fullstack-config.yaml > /dev/null
                    yq -i '.metadata.namespace = "rc"' Restaurant-k8s-components/mysql-external-service.yaml > /dev/null

                    kubectl apply -f /root/jenkins/restaurant-resources/fullstack-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components/tables/
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then echo "failed to deploy to rc namespace" && exit 1; fi
                '''
                stash includes: 'Restaurant-k8s-components/', name: 'k8s-components'
                stash includes: 'Restaurant-k8s-components/tests.py,Restaurant-k8s-components/tests.sh', name: 'tests'
            }
        }
        stage('sanity tests'){
            steps{
                unstash 'tests'
                sh '''
                    ./Restaurant-k8s-components/tests.sh ${RC_LB}
                    exit_status=$?
                    if [ "${exit_status}" -ne 0 ];
                    then
                        echo "exit ${exit_status}"
                    fi
                    '''

                withCredentials([gitUsernamePassword(credentialsId: 'GITHUB_USERPASS', gitToolName: 'Default')]) {
                    sh '''
                        git checkout rc
                        git checkout master
                        git merge rc
                        git push origin master
                    '''
                }
            }
        }
        stage('deploy to cluster - prod namespace'){
            steps{
                unstash 'k8s-components'

                sh '''
                    find Restaurant-k8s-components/tables -type f -path ./Restaurant-k8s-components/tables -prune -o -name *.yaml -print | while read line; do yq -i '.metadata.namespace = "prod"' $line > /dev/null; done
                    yq -i '.metadata.namespace = "prod"' /root/jenkins/restaurant-resources/fullstack-secrets.yaml > /dev/null
                    yq -i '.metadata.namespace = "prod"' Restaurant-k8s-components/fullstack-config.yaml > /dev/null
                    yq -i '.metadata.namespace = "prod"' Restaurant-k8s-components/mysql-external-service.yaml > /dev/null

                    kubectl config set-context --current --namespace prod
                    kubectl apply -f /root/jenkins/restaurant-resources/fullstack-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components/tables/
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then echo "PROD FAILURE"; fi
                '''
            }
        }
        stage('sanity tests - prod'){
            steps{
                unstash 'tables-repo'
                sh '''
                    ./Restaurant-k8s-components/tests.sh ${PROD_LB}
                    exit_status=$?
                    if [ "${exit_status}" -ne 0 ];
                    then
                        echo "PROD FAILURE, MANUAL INSPECTION NECESSARY - exit ${exit_status}"
                    fi
                    '''
            }
        }
    }
    post{
        failure{
            unstash 'tables-repo'
            withCredentials([gitUsernamePassword(credentialsId: 'GITHUB_USERPASS', gitToolName: 'Default')]) {
                sh '''
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
//