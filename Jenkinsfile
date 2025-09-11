pipeline{
    agent{
        docker{
            image 'bryan949/poc-agent:0.2.5'
            args '-v /var/run/docker.sock:/var/run/docker.sock \
                  --privileged \
                  --env KOPS_STATE_STORE=${KOPS_STATE_STORE}'
            alwaysPull true
        }
    }
    options {
        skipDefaultCheckout(true)  // Skip automatic checkout
    }
    stages{
        stage('Manual Checkout and Build') {
            steps {
                sh '''
                    # Clone fresh without using Jenkins Git plugin
                    cd ${WORKSPACE}
                    rm -rf * .git
                    git clone ${GIT_URL} .

                    # Build
                    mvn -Dmaven.repo.local=/tmp/m2 clean verify
                '''
            }
        }
        stage('Build and push docker image'){
            steps{
                sh '''
                    # Files are already in workspace, no unstash needed
                    cp /var/lib/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /var/lib/restaurant-resources/context.xml .
                    cp /var/lib/restaurant-resources/server.xml .

                    docker build -t bryan949/poc-tables .
                    docker push bryan949/poc-tables:latest
                '''
            }
        }
    }
}