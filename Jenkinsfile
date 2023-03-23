pipeline{
    agent{
        docker{
            image 'bryan949/fullstack-agent:0.1'
            args '-v /root/.m2:/root/.m2 \
            -v /root/jenkins/restaurant-resources/k8s-components:/root/jenkins/restaurant-resources/k8s-components \
             --privileged --env KOPS_STATE_STORE=' + env.KOPS_STATE_STORE// + ' --env AWS_ACCESS_KEY_ID=' + env.AWS_ACCESS_KEY_ID + ' --env AWS_SECRET_ACCESS_KEY=' + env.AWS_SECRET_ACCESS_KEY
            alwaysPull true
        }
    }
    stages{
        stage('git clone'){
            steps{
                sh '''
                    docker version
                    git clone https://github.com/bconnelly/Restaurant-k8s-components.git
                    pwd
                    ls -alF
                '''

//                 pwd
//                 ls -alF
//                 git clone https://github.com/bconnelly/TablesService.git
//
//                 pwd
//                 ls -alF
//                 git clone https://github.com/bconnelly/Restaurant-k8s-components.git

//                 cleanWs()
//                 git branch: "master", url: "https://github.com/bconnelly/TablesService.git"
//                 sh 'pwd'
//                 sh 'ls -alF'
//                 sh 'cd .. && mkdir Restaurant-k8s-components && cd Restaurant-k8s-components'
//                 git branch: "master", url:"https://github.com/bconnelly/Restaurant-k8s-components.git"
//                 sh 'pwd'
//                 sh 'ls -alF'
            }
        }
        stage('maven build and test'){
            steps{
                echo 'Packaging and testing:'
                sh 'pwd && ls -alF'
                sh 'mvn verify'
            }
        }
        stage('build docker images'){
            steps{
                sh '''
                    docker build -t bryan949/fullstack-tables .
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
                    echo fileString
                    def files = fileString.split("\n")
                    for(file in files){
                        sh 'yq e \\\'.metadata.namespace = \\"dev\\" \\\'$file\\\''
                    }
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
    post{
        always{

            cleanWs(cleanWhenAborted: true,
                    cleanWhenFailure: true,
                    cleanWhenNotBuilt: true,
                    cleanWhenSuccess: true,
                    cleanWhenUnstable: true,
                    cleanupMatrixParent: true,
                    deleteDirs: true,
                    disableDeferredWipeout: true
//                     pattern: [[pattern: '.gitignore', type: 'INCLUDE'],
//                               [pattern: ]]
            )
        }
    }
}