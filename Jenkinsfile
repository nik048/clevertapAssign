pipeline{
    agent any

    environment {
        version = "1.0"
		DOCKERHUB_CREDENTIALS=credentials('dockerhub-cred')
        AWS_ACCESS_KEY=credentials('aws_access_key')
        DOCKER_IMAGE = "nik048/wordpress-task"
    }

    stages{
        stage('Build Wordpress docker image'){
            steps{
                sh "docker build -t $DOCKER_IMAGE:$BUILD_NUMBER -f Dockerfile ."    
            }
            
        }
        
        stage('Push image'){           
            steps{
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push $DOCKER_IMAGE:$BUILD_NUMBER"
            }
        }
        stage('Update ecs with new image'){
            steps{
                dir('terraform'){
                    sh "sed -i -e 's/IMAGE_TAG/$BUILD_NUMBER/' ecs/task-definition/task.json"
                    sh "AWS_SECRET_ACCESS_KEY=$AWS_ACCESS_KEY_USR AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_PSW terraform init"
                    sh "AWS_SECRET_ACCESS_KEY=$AWS_ACCESS_KEY_USR AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_PSW  terraform apply -auto-approve"
                }
            }
        }
    }

    post{
        always { 
            cleanWs()
        }
    }
}
