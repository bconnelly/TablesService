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
    stages{
        stage('Fix Workspace') {
            steps {
                sh '''
                    # Take full ownership as root
                    chown -R root:root ${WORKSPACE} || true
                    chmod -R 777 ${WORKSPACE} || true

                    # Remove ALL git lock files and problematic files
                    find ${WORKSPACE} -name "*.lock" -delete 2>/dev/null || true
                    rm -rf ${WORKSPACE}/.git/FETCH_HEAD || true
                    rm -rf ${WORKSPACE}/.git/config.lock || true
                    rm -rf ${WORKSPACE}/.git/index.lock || true

                    # Mark directory as safe for git
                    git config --global --add safe.directory ${WORKSPACE}
                    git config --global --add safe.directory '*'
                '''
            }
        }
        stage('Maven build and test'){
            steps{
                sh '''
                    # Create .m2 directory with proper permissions
                    mkdir -p /root/.m2
                    mvn -Dmaven.repo.local=/root/.m2/repository clean verify
                '''
                // IMPORTANT: Exclude .git directory from stash
                stash name: 'tables-repo', excludes: '.git/**', useDefaultExcludes: false
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
    }
}