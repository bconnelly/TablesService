pipeline{
    agent any  // Run directly on Jenkins without Docker first
    stages{
        stage('Maven build') {
            steps{
                sh 'mvn clean verify'
            }
        }
        stage('Docker build') {
            steps{
                sh '''
                    cp /var/lib/jenkins/restaurant-resources/*.xml .
                    docker build -t bryan949/poc-tables .
                    docker push bryan949/poc-tables:latest
                '''
            }
        }
    }
}