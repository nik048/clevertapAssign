pipeline{
    agent any

    environment {
        version = "1.0"
    }

    stages{
        stage('Build Wordpress docker image'){
            steps{
                sh "docker build -t nik048/wordpress-task:$BUILD_NUMBER -f Dockerfile ."    
            }
            
        }
        
        stage('Push image'){           
            steps{
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push nik048/wordpress-task:$BUILD_NUMBER"
            }
        }
    }

    post{
        always { 
            cleanWs()
        }
    }
}
