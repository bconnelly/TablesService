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
    stages{
        stage('Complete Cleanup and Setup') {
            steps {
                sh '''
                    # Nuclear cleanup
                    chmod -R 777 ${WORKSPACE} || true
                    rm -rf ${WORKSPACE}/* || true
                    rm -rf ${WORKSPACE}/.git || true

                    # Create .m2 directory with full permissions
                    mkdir -p /home/jenkins/.m2/repository
                    chmod -R 777 /home/jenkins/.m2

                    # Set git config to be permissive
                    git config --global --add safe.directory '*'
                '''
            }
        }
        stage('Maven build and test'){
            steps{
                sh '''
                    chmod -R 777 ${WORKSPACE} || true
                    mvn -Dmaven.repo.local=/home/jenkins/.m2/repository clean verify
                    chmod -R 777 ${WORKSPACE} || true
                '''
                // Don't use stash - copy files directly instead
                sh 'tar czf /tmp/build-output.tar.gz target/'
            }
        }
        stage('Build and push docker image'){
            steps{
                sh '''
                    # Extract build artifacts
                    tar xzf /tmp/build-output.tar.gz

                    cp /var/lib/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /var/lib/jenkins/restaurant-resources/context.xml .
                    cp /var/lib/jenkins/restaurant-resources/server.xml .

                    docker build -t bryan949/poc-tables .
                    docker push bryan949/poc-tables:latest

                    rm tomcat-users.xml context.xml server.xml
                '''
            }
        }
    }
}