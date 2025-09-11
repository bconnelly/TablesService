pipeline{
    agent{
        docker{
            image 'bryan949/poc-agent:0.2.5'
            args '-v /var/run/docker.sock:/var/run/docker.sock \
                  --privileged \
                  -u $(id -u):$(id -g) \
                  --env KOPS_STATE_STORE=${KOPS_STATE_STORE}'
            alwaysPull true
        }
    }
    environment{
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
    }
    stages{
        stage('Maven build and test'){
            steps{
                sh '''
                    # Use a maven repo directory that the current user can write to
                    mkdir -p ${WORKSPACE}/.m2/repository
                    mvn -Dmaven.repo.local=${WORKSPACE}/.m2/repository clean verify
                '''
                // Only stash what we need for Docker build, exclude .git and .m2
                stash name: 'tables-repo',
                      includes: 'target/**, pom.xml, Dockerfile, src/**',
                      excludes: '.git/**, .m2/**'
            }
        }
        stage('Build and push docker image'){
            steps{
                unstash 'tables-repo'
                sh '''
                    cp /home/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /home/jenkins/restaurant-resources/context.xml .
                    cp /home/jenkins/restaurant-resources/server.xml .

                    # Ensure we have the WAR file
                    if [ ! -f TablesService.war ]; then
                        cp target/*.war TablesService.war || echo "WAR file not found in expected location"
                    fi

                    docker build -t bryan949/poc-tables .
                    docker push bryan949/poc-tables:latest

                    rm -f tomcat-users.xml context.xml server.xml
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
                    # Clone in a subdirectory to avoid conflicts
                    rm -rf k8s-temp || true
                    git clone https://github.com/bconnelly/Restaurant-k8s-components.git k8s-temp

                    cd k8s-temp
                    find tables -type f -name "*.yaml" | while read line; do
                        yq -i '.metadata.namespace = "rc"' "$line" > /dev/null
                    done

                    # Handle files that need to be copied from jenkins resources
                    cp /home/jenkins/restaurant-resources/k8s-components/poc-secrets.yaml .
                    yq -i '.metadata.namespace = "rc"' poc-secrets.yaml > /dev/null
                    yq -i '.metadata.namespace = "rc"' poc-config.yaml > /dev/null
                    yq -i '.metadata.namespace = "rc"' mysql-external-service.yaml > /dev/null

                    kubectl apply -f poc-secrets.yaml
                    kubectl apply -f poc-config.yaml
                    kubectl apply -f mysql-external-service.yaml
                    kubectl apply -f tables/
                    kubectl get deployment
                    kubectl rollout restart deployment tables-deployment

                    if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then
                        echo "failed to deploy to rc namespace" && exit 1
                    fi
                    sleep 3
                '''
                dir('k8s-temp') {
                    stash includes: 'tables/**', name: 'k8s-components'
                    stash includes: 'tests.py,poc-config.yaml,mysql-external-service.yaml', name: 'tests'
                }
            }
        }
        stage('sanity tests'){
            steps{
                dir('test-dir') {
                    unstash 'tests'
                    sh '''
                        python tests.py ${RC_LB}
                        exit_status=$?
                        if [ "${exit_status}" -ne 0 ]; then
                            echo "exit ${exit_status}"
                            exit ${exit_status}
                        fi
                    '''
                }

                // Git operations in the main workspace
                withCredentials([gitUsernamePassword(credentialsId: 'GITHUB_USERPASS', gitToolName: 'Default')]) {
                    sh '''
                        git config --global user.email "jenkins@example.com"
                        git config --global user.name "Jenkins"
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
                dir('prod-deploy') {
                    unstash 'k8s-components'
                    unstash 'tests'  // Get poc-config.yaml and mysql-external-service.yaml

                    sh '''
                        find tables -type f -name "*.yaml" | while read line; do
                            yq -i '.metadata.namespace = "prod"' "$line" > /dev/null
                        done

                        # Copy and update the secrets file
                        cp /home/jenkins/restaurant-resources/k8s-components/poc-secrets.yaml .
                        yq -i '.metadata.namespace = "prod"' poc-secrets.yaml > /dev/null
                        yq -i '.metadata.namespace = "prod"' poc-config.yaml > /dev/null
                        yq -i '.metadata.namespace = "prod"' mysql-external-service.yaml > /dev/null

                        kubectl config set-context --current --namespace prod
                        kubectl apply -f poc-secrets.yaml
                        kubectl apply -f tables/
                        kubectl apply -f poc-config.yaml
                        kubectl apply -f mysql-external-service.yaml
                        kubectl get deployment
                        kubectl rollout restart deployment tables-deployment

                        if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then
                            echo "PROD FAILURE"
                        fi
                        sleep 3
                    '''
                }
            }
        }
    }
    post{
        failure{
            script {
                // Only try to unstash if the stash exists
                try {
                    unstash 'tables-repo'
                } catch (Exception e) {
                    echo "Could not unstash tables-repo: ${e.message}"
                }

                withCredentials([gitUsernamePassword(credentialsId: 'GITHUB_USERPASS', gitToolName: 'Default')]) {
                    sh '''
                        git config --global user.email "jenkins@example.com"
                        git config --global user.name "Jenkins"
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