pipeline{
    agent{
        docker{
//             image 'docker:dind'
//             args '-v /root/.m2:/root/.m2 \
//                   -v /root/jenkins/restaurant-resources/:/root/jenkins/restaurant-resources/ \
//                   --privileged -d --name dind-agent'
            image 'bryan949/fullstack-agent:0.1'
            args '-v /root/.m2:/root/.m2 \
                  -v /root/jenkins/restaurant-resources/:/root/jenkins/restaurant-resources/ \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  --privileged --env KOPS_STATE_STORE=' + env.KOPS_STATE_STORE + \
                  ' --env DOCKER_USER=' + env.DOCKER_USER + ' --env DOCKER_PASS=' + env.DOCKER_PASS
                  // + ' --env AWS_ACCESS_KEY_ID=' + env.AWS_ACCESS_KEY_ID + ' --env AWS_SECRET_ACCESS_KEY=' + env.AWS_SECRET_ACCESS_KEY
            alwaysPull true
        }
    }
    stages{
        stage('maven build and test, docker build and push'){
            steps{
                echo 'Packaging and testing:'
                sh '''
                    mvn verify
                    ls -alF
                '''
                stash includes: 'target/TablesService.war', name: 'war'

            }
        }
        stage('build docker images'){
            steps{
                sh '''
                    docker login --username=$DOCKER_USER --password=$DOCKER_PASS
                    cp /root/jenkins/restaurant-resources/tomcat-users.xml .
                    cp /root/jenkins/restaurant-resources/context.xml .
                    cp /root/jenkins/restaurant-resources/server.xml .
                    docker build -t bryan949/fullstack-tables .
                    docker push bryan949/fullstack-tables:latest
                '''
            }
        }
        stage('configure cluster connection'){
            steps{
    	        sh '''
    	            ls -alF
	                kops export kubecfg --admin --name fullstack.k8s.local
	                if [ -z "$(kops validate cluster | grep ".k8s.local is ready")" ]; then exit 1; fi
	                kubectl config set-context --current --namespace preprod
	            '''
            }
        }
        stage('deploy services to cluster'){
            steps{
                script{
                    sh '''
                        git clone https://github.com/bconnelly/Restaurant-k8s-components.git
                    '''

                    def fileString = sh(script: 'find Restaurant-k8s-components -type f -path ./Restaurant-k8s-components/.git -prune -o -name *.yaml -print', returnStdout: true)
                    echo fileString
                    def files = fileString.split("\n")
                    for(file in files){
                        sh 'yq e \'.metadata.namespace = \"dev\"\' ' + file
                    }

                    sh '''
                        sh 'kubectl apply -f /root/jenkins/fullstack-secrets.yaml'
                        sh 'kubectl apply -f Restaurant-k8s-components/ --recursive'
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