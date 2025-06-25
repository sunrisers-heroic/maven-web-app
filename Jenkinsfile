pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'M3'  // Make sure you have Maven installed in Jenkins
        MAVEN_CMD = "\$MAVEN_HOME/bin/mvn"
        MAVEN_SETTINGS = "maven.settings.xml"  // Optional if using custom settings

        // Credentials
        GITHUB_CRED = credentials('github-credentials')
        DOCKER_CRED = credentials('docker-hub-credentials')

        // Project info
        DOCKER_IMAGE_NAME = "maven-web-app"
        DOCKER_REGISTRY = "sunrisersheroic/\${DOCKER_IMAGE_NAME}"
        APP_NAME = "myapp"
    }

    stages {
        // Stage 1: Clone Repository
        stage('Clone Repository') {
            steps {
                echo "Cloning GitHub repository..."
                sh '''
                    rm -rf maven-web-app || true
                    git clone https://$GITHUB_CRED_USR:$GITHUB_CRED_PSW@github.com/sunrisers-heroic/maven-web-app.git  maven-web-app
                    cd maven-web-app
                    git checkout main
                '''
            }
        }

        // Stage 2: Build with Maven
        stage('Build WAR File') {
            steps {
                echo "Building WAR file with Maven..."
                sh """
                    cd maven-web-app
                    ${MAVEN_CMD} -s \${MAVEN_SETTINGS} clean package
                """
                echo "✅ WAR file generated!"
            }
        }

        // Stage 3: Create Docker Image with WAR
        stage('Build Docker Image') {
            steps {
                script {
                    def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true).trim()
                    env.BUILD_VERSION = pomVersion ?: "latest"
                    echo "Detected Version: \${BUILD_VERSION}"

                    env.WAR_FILENAME = sh(script: 'cd maven-web-app && ls target/*.war', returnStdout: true).trim().replaceAll(".*/", "")
                    echo "WAR file name: \${WAR_FILENAME}"
                }

                echo "Creating Docker image..."
                sh '''
                    cd maven-web-app

                    # Write Dockerfile dynamically
                    cat << EOF > Dockerfile
FROM tomcat:9.0
RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/${WAR_FILENAME} /usr/local/tomcat/webapps/
EXPOSE 8080
CMD ["catalina.sh", "run"]
EOF

                    docker build -t sunrisersheroic/maven-web-app:${BUILD_VERSION} .
                    docker tag sunrisersheroic/maven-web-app:${BUILD_VERSION} sunrisersheroic/maven-web-app:latest
                '''
            }
        }

        // Stage 4: Push to Docker Hub
        stage('Push Docker Image') {
            steps {
                echo "Logging into Docker Hub..."
                sh '''
                    docker login -u $DOCKER_CRED_USR -p $DOCKER_CRED_PSW
                    docker push sunrisersheroic/maven-web-app:${BUILD_VERSION}
                    docker push sunrisersheroic/maven-web-app:latest
                '''
                echo "✅ Docker image pushed to Docker Hub"
            }
        }

        // Stage 5: Deploy Locally or Remotely via SSH
        stage('Deploy Docker Container') {
            when {
                expression { env.DEPLOY == "true" }  // Only deploy if triggered manually
            }
            steps {
                script {
                    sshagent(['docker-server-ssh']) {
                        sh '''
                            echo "Connecting to Docker server..."

                            ssh -o StrictHostKeyChecking=no ec2-user@<your-docker-server-ip> << 'SSH_EOF'
                                echo "Removing old containers..."
                                docker stop maven-web-app || true
                                docker rm maven-web-app || true

                                echo "Pulling latest WAR image..."
                                docker pull sunrisersheroic/maven-web-app:latest

                                echo "Starting new WAR container..."
                                docker run -d \
                                    --name maven-web-app \
                                    -p 8090:8080 \
                                    sunrisersheroic/maven-web-app:latest

                                echo "Container logs:"
                                docker logs maven-web-app
SSH_EOF
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded — WAR and Docker image created!"
        }
        failure {
            echo "❌ Pipeline failed but WAR/Docker image may still exist locally."
        }
    }
}
