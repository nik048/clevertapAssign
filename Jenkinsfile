pipeline{
    agent any

    environment {
        version = "1.0"
    }

    stages{
            stage('Build Wordpress docker image'){
                sh "docker build -t nik048/wordpress-task:$BUILD_NUMBER -f Dockerfile ."
            }
        }
        stage('Push image'){           
            steps{
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
