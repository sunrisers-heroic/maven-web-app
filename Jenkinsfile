pipeline {
    agent any

    environment {
        // Use full path to mvn
        MAVEN_CMD = "/opt/maven/bin/mvn"
        MAVEN_SETTINGS = "maven.settings.xml" // Must match settings.xml in Jenkins UI

        // Credentials
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CRED = credentials('github-credentials')
        DOCKER_CRED = credentials('docker-hub-credentials')  // Add this in Jenkins

        // Project details
        DOCKER_IMAGE_NAME = "maven-web-app"
        DOCKER_REGISTRY = "docker.io/sunrisersheroic"

        // Nexus repo URL (used in wget)
        NEXUS_REPO_URL = "http://34.228.172.106:8081/repository/maven-releases"
        NEXUS_USER = "admin"
        NEXUS_PASS = "nexus123"
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
    }

    post {
        success {
            echo "✅ Pipeline succeeded — starting Docker image build..."

            script {
                // Step 1: Read version from pom.xml
                def pom = readMavenPom file: 'maven-web-app/pom.xml'
                env.BUILD_VERSION = pom.version
                echo "Detected Version: ${env.BUILD_VERSION}"
            }

            // Step 2: Download WAR from Nexus manually using wget
            sh """
                cd maven-web-app
                mkdir -p target
                wget --user=admin --password=nexus123 \\
                  -O target/app.war \\
                  \${NEXUS_REPO_URL}/com/app/raghu/01-maven-web-app/${BUILD_VERSION}/01-maven-web-app-${BUILD_VERSION}.war
            """

            // Step 3: Build Docker image
            sh """
                cd maven-web-app
                docker build -t sunrisersheroic/maven-web-app:\${BUILD_VERSION} .
                docker tag sunrisersheroic/maven-web-app:\${BUILD_VERSION} sunrisersheroic/maven-web-app:latest
            """

            // Step 4: Push to Docker Hub
            sh """
                docker login -u \${DOCKER_CRED_USR} -p \${DOCKER_CRED_PSW}
                docker push sunrisersheroic/maven-web-app:\${BUILD_VERSION}
                docker push sunrisersheroic/maven-web-app:latest
            """

            echo "✅ Docker image pushed to Docker Hub!"
        }

        failure {
            echo "❌ Pipeline failed! Docker image was not built."
        }
    }
}
