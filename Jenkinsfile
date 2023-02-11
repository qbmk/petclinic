pipeline {
    agent any
    
    stages {
        
        stage('Build Artifact') {
            agent {
      	        docker {
        	    image 'eclipse-temurin:17-jdk-jammy'
                }
            }
            steps {
                git branch: 'main', url: 'https://github.com/qbmk/petclinic.git'
                sh "chmod +x mvnw"
                sh "./mvnw package -Dmaven.test.skip=true"
            }
        }
        
        stage('Test') {
            agent {
      	        docker {
        	    image 'eclipse-temurin:17-jdk-jammy'
                }
            }
            steps {
                sh "./mvnw test"
            }
        }
        
        stage ('Deploy Artifact') {
            agent {
      	        docker {
        	    image 'eclipse-temurin:17-jdk-jammy'
                }
            }
            steps {
                googleStorageUpload bucket: 'gs://petclinic-artifacts/cicd', credentialsId: 'epam-project-biba', pattern: 'target/*.jar'
          
            }
        }
        
        stage('Build container') {
            steps {
                git branch: 'main', credentialsId: 'GitHub-token', url: 'https://github.com/qbmk/spring-petclinic.git'
                sh "gsutil cp gs://petclinic-artifacts/cicd/target/*.jar target/petclinic.jar"
                sh "docker build --tag petclinic:ver$BUILD_NUMBER ."
            }
        }
        
        stage('Deploy container') {
            steps {
                sh "gcloud auth configure-docker yes"
                sh "docker tag petclinic:ver$BUILD_NUMBER gcr.io/epam-project-biba/petclinic:ver$BUILD_NUMBER"
                sh "docker push gcr.io/epam-project-biba/petclinic:ver$BUILD_NUMBER"
                sh 'docker image rm -f petclinic:ver$BUILD_NUMBER'
            }
        }

        stage ('Run container') {
            steps {
                sh '''gcloud run deploy petclinic \\
                    --image=gcr.io/epam-project-biba/petclinic:ver$BUILD_NUMBER \\
                    --tag=ver$BUILD_NUMBER \\
                    --service-account=project-sa@epam-project-biba.iam.gserviceaccount.com \\
                    --vpc-connector=projects/epam-project-biba/locations/europe-west1/connectors/petclinic-vpc-connector \\
                    --min-instances=1 \\
                    --max-instances=5 \\
                    --port=8080 \\
                    --region=europe-west1 \\
                    --ingress=all \\
                    --vpc-egress=private-ranges-only \\
                    --no-traffic \\
                    --project=epam-project-biba'''
            }
        
        }
        
        stage ('Acceptance Test') {
            steps {
               script {
                env.ResponseCode = sh(
                    script:
                    '''
                    GREEN_URL=$(gcloud run services describe petclinic --format=\'value(status.traffic[-1].url)\' --platform managed --region europe-west1)
                    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null ${GREEN_URL})
                    echo "$RESPONSE"
                    ''',
                    returnStdout: true
                ).trim()
                }
            }
        
        }
        
        stage("Blue/Green Toggle Load Balancer") {
            when {
                environment name: 'ResponseCode', value: '200'
            }
               
            steps {
                sh "gcloud run services update-traffic petclinic --to-latest --region=europe-west1"
                echo "Toggle Load Balancer"
                
            }
        }
        
        stage("Alarm Load Balancer") {
            when {
                not {
                environment name: 'ResponseCode', value: '200'
                }
            }
               
            steps {
                error 'Alarm Load Balancer'
            }
        } 
        
    }
}