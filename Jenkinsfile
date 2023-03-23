pipeline{
    agent{
        docker{
            image 'bryan949/restaurant-service:0.1'
            args '-v /root/.m2:/root/.m2 --privileged --env KOPS_STATE_STORE=' + env.KOPS_STATE_STORE + ' --env AWS_ACCESS_KEY_ID=' + env.AWS_ACCESS_KEY_ID + ' --env AWS_SECRET_ACCESS_KEY=' + env.AWS_SECRET_ACCESS_KEY
            alwaysPull true
        }
    }
    stages{
        stage('git clone'){
            steps{
                git branch: "master", url: "https://github.com/bconnelly/TablesService.git"
//                 sh '''
//                     cp /root/jenkins/restaurant-resources/tomcat-users.xml .
//                     cp /root/jenkins/restaurant-resources/context.xml .
//                     cp /root/jenkins/restaurant-resources/server.xml .
//                 '''
            }
        }
        stage('maven build and test'){
            steps{
                echo 'Packaging and testing:'
                sh 'pwd'
                sh 'mvn -f TableService/ verify'
            }
        }
        stage('build docker images'){
            steps{
                sh '''
                    docker build -t bryan949/fullstack-tables TablesService/
                    docker push bryan949/fullstack-tables:latest
                '''
            }
        }
        stage('configure cluster connection'){
            steps{
    	        sh '''
	                kops export kubecfg --admin --name fullstack.k8s.local
	                if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
	                kubectl config set-context --current --namespace preprod
	            '''
            }
        }
        stage('deploy services to cluster'){
            steps{
                script{
                    def fileString = sh(script: 'find k8s-components -type f', returnStdout: true)
                    echo filestring
                    def files = fileString.split("\n")
                    for(file in files){
                        sh 'yq e \\\'.metadata.namespace = \\"preprod\\" \\\'$file\\\''

//                yq e '.metadata.namespace = "dev"' $file
                    sh '''
                        sh 'kubectl apply -f /root/jenkins/fullstack-secrets.yaml'
                        sh 'kubectl apply -f k8s-components/ --recursive'
                    '''
                    sh '''
                        if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
                    '''
                }
            }
        }
    }
}
}