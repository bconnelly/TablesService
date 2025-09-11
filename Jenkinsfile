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
        stage('Clone and Build in Temp') {
            steps {
                sh '''
                    # Work in a completely fresh directory
                    cd /tmp
                    rm -rf /tmp/build-${BUILD_NUMBER} || true
                    mkdir -p /tmp/build-${BUILD_NUMBER}
                    cd /tmp/build-${BUILD_NUMBER}

                    # Clone fresh (replace with your actual repo URL)
                    git clone https://github.com/YOUR_ORG/YOUR_REPO.git .

                    # Or if you need to use the workspace code, copy it without .git
                    # cp -r ${WORKSPACE}/* . 2>/dev/null || true
                    # find . -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true

                    # Build
                    mkdir -p /root/.m2
                    mvn -Dmaven.repo.local=/root/.m2/repository clean verify

                    # Copy resources
                    cp /home/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /home/jenkins/restaurant-resources/context.xml .
                    cp /home/jenkins/restaurant-resources/server.xml .

                    # Build and push Docker image
                    docker build -t bryan949/poc-tables .
                    docker push bryan949/poc-tables:latest

                    # Clean up
                    cd /
                    rm -rf /tmp/build-${BUILD_NUMBER}
                '''
            }
        }
    }
}