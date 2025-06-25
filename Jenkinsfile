pipeline {
    agent any

    environment {
        // Use full path to mvn
        MAVEN_CMD = "/opt/maven/bin/mvn"
        MAVEN_SETTINGS = "maven.settings.xml" // Name of settings.xml uploaded in Jenkins UI

        // Credentials
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CRED = credentials('github-credentials')
        DOCKER_CRED = credentials('docker-hub-credentials')  // Add this in Jenkins Credentials

        // GitHub repo URL
        GITHUB_REPO = "https://github.com/sunrisers-heroic/maven-web-app.git" 

        // Docker image details
        DOCKER_IMAGE_NAME = "maven-web-app"
        DOCKER_REGISTRY = "docker.io/sunrisersheroic"
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
        stage('Build with Maven') {
            steps {
                echo "Building project with Maven..."
                sh """
                    cd maven-web-app
                    ${MAVEN_CMD} -s \${MAVEN_SETTINGS} clean package
                """
                echo "✅ Build completed!"
            }
        }

        // Stage 3: SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."
                withSonarQubeEnv('SonarQube') {
                    sh """
                        cd maven-web-app
                        ${MAVEN_CMD} -s \${MAVEN_SETTINGS} sonar:sonar -Dsonar.login=${SONAR_TOKEN}
                    """
                }
                echo "✅ Code analysis completed!"
            }
        }

        // Stage 4: Deploy to Nexus
        stage('Deploy to Nexus') {
            steps {
                echo "Deploying artifact to Nexus..."
                sh """
                    cd maven-web-app
                    ${MAVEN_CMD} -s \${MAVEN_SETTINGS} deploy
                """
                echo "✅ Artifact deployed to Nexus!"
            }
        }

        // Stage 5: Build and Push Docker Image
        stage('Build and Push Docker Image') {
            steps {
                echo "Building and pushing Docker image..."

                script {
                    // Get version from pom.xml
                    def pom = readMavenPom file: 'maven-web-app/pom.xml'
                    env.BUILD_VERSION = pom.version
                    echo "Detected Version: ${env.BUILD_VERSION}"
                }

                sh """
                    cd maven-web-app
                    docker build -t sunrisersheroic/maven-web-app:${BUILD_VERSION} .
                    docker tag sunrisersheroic/maven-web-app:${BUILD_VERSION} sunrisersheroic/maven-web-app:latest
                """

                sh """
                    docker login -u ${DOCKER_CRED_USR} -p ${DOCKER_CRED_PSW}
                    docker push sunrisersheroic/maven-web-app:${BUILD_VERSION}
                    docker push sunrisersheroic/maven-web-app:latest
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs for details."
        }
    }
}
