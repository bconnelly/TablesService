pipeline{
    agent{
        docker{
            image 'bryan949/poc-agent:0.2.5'
            args '-v /var/run/docker.sock:/var/run/docker.sock \
                  --privileged \
                  -u root:root \
                  --env KOPS_STATE_STORE=${KOPS_STATE_STORE}'
            alwaysPull true
        }
    }
    environment{
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }
    stages{
        stage('Setup Git Config'){
            steps{
                sh '''
                    # Configure git to trust the workspace
                    git config --global --add safe.directory ${WORKSPACE}
                    git config --global --add safe.directory '*'

                    # Ensure proper ownership
                    chown -R root:root ${WORKSPACE} || true
                '''
            }
        }
        stage('Maven build and test'){
            steps{
                sh '''
                    # Use root's .m2 directory since we're running as root
                    mkdir -p /root/.m2
                    mvn -Dmaven.repo.local=/root/.m2/repository clean verify
                '''
                // Exclude problematic directories from stash
                stash name: 'tables-repo', excludes: '.git/**,.mvn/**,target/**', useDefaultExcludes: false
            }
        }
        stage('Build and push docker image'){
            steps{
                unstash 'tables-repo'
                sh '''
                    cp /home/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /home/jenkins/restaurant-resources/context.xml .
                    cp /home/jenkins/restaurant-resources/server.xml .

                    docker build -t bryan949/poc-tables .
                    docker push bryan949/poc-tables:latest

                    rm tomcat-users.xml
                    rm context.xml
                    rm server.xml
                '''
            }
        }
        stage('Configure cluster connection'){
            steps{
    	        sh '''
	                kops export kubecfg --admin --name poc.k8s.local
	                if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
	                kubectl config set-context --current --namespace rc
	            '''
            }
        }
        stage('Deploy services to cluster - rc namespace'){
            steps{
                sh '''
                    # Clean up any previous clone
                    rm -rf Restaurant-k8s-components
                    git clone https://github.com/bconnelly/Restaurant-k8s-components.git

                    find Restaurant-k8s-components/tables -type f -path ./Restaurant-k8s-components/tables -prune -o -name *.yaml -print | while read line; do yq -i '.metadata.namespace = "rc"' $line > /dev/null; done
                    yq -i '.metadata.namespace = "rc"' /home/jenkins/restaurant-resources/poc-secrets.yaml > /dev/null
                    yq -i '.metadata.namespace = "rc"' Restaurant-k8s-components/poc-config.yaml > /dev/null
                    yq -i '.metadata.namespace = "rc"' Restaurant-k8s-components/mysql-external-service.yaml > /dev/null

                    kubectl apply -f /home/jenkins/restaurant-resources/poc-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components/poc-config.yaml
                    kubectl apply -f Restaurant-k8s-components/mysql-external-service.yaml
                    kubectl apply -f Restaurant-k8s-components/tables/
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then echo "failed to deploy to rc namespace" && exit 1; fi
                    sleep 3
                '''
                stash includes: 'Restaurant-k8s-components/tables/**', name: 'k8s-components'
                stash includes: 'Restaurant-k8s-components/tests.py,Restaurant-k8s-components/poc-config.yaml,Restaurant-k8s-components/mysql-external-service.yaml', name: 'tests'
            }
        }
        stage('sanity tests'){
            steps{
                unstash 'tests'
                sh '''
                    python Restaurant-k8s-components/tests.py ${RC_LB}
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
        stage('Deploy to cluster - prod namespace'){
            steps{
                unstash 'k8s-components'

                sh '''
                    # Re-clone to get fresh files if needed
                    rm -rf Restaurant-k8s-components-prod
                    git clone https://github.com/bconnelly/Restaurant-k8s-components.git Restaurant-k8s-components-prod

                    find Restaurant-k8s-components-prod/tables -type f -path ./Restaurant-k8s-components-prod/tables -prune -o -name *.yaml -print | while read line; do yq -i '.metadata.namespace = "prod"' $line > /dev/null; done
                    yq -i '.metadata.namespace = "prod"' /home/jenkins/restaurant-resources/poc-secrets.yaml > /dev/null
                    yq -i '.metadata.namespace = "prod"' Restaurant-k8s-components-prod/poc-config.yaml > /dev/null
                    yq -i '.metadata.namespace = "prod"' Restaurant-k8s-components-prod/mysql-external-service.yaml > /dev/null

                    kubectl config set-context --current --namespace prod
                    kubectl apply -f /home/jenkins/restaurant-resources/poc-secrets.yaml
                    kubectl apply -f Restaurant-k8s-components-prod/tables/
                    kubectl apply -f Restaurant-k8s-components-prod/poc-config.yaml
                    kubectl apply -f Restaurant-k8s-components-prod/mysql-external-service.yaml
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then echo "PROD FAILURE"; fi
                    sleep 3
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
            cleanWs(cleanWhenAborted: true,
                    cleanWhenFailure: true,
                    cleanWhenNotBuilt: true,
                    cleanWhenSuccess: true,
                    cleanWhenUnstable: true,
                    cleanupMatrixParent: true,
                    deleteDirs: true,
                    disableDeferredWipeout: true)

            script{
                sh 'docker rmi bryan949/poc-tables || true'
                sh 'docker image prune -f || true'
            }
        }
    }
}