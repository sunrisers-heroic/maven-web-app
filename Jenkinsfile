pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'M3' // Make sure this matches your Maven install name in Jenkins
        MAVEN_CMD = "${MAVEN_HOME}/bin/mvn"
        SONAR_TOKEN = credentials('sonarqube-token') // SonarQube token added as secret text
        GITHUB_CRED = credentials('github-credentials') // Your GitHub username/password credential ID
        SETTINGS_FILE = "/var/lib/jenkins/settings.xml" // Path to your settings.xml
        GITHUB_REPO = "https://github.com/sunrisers-heroic/maven-web-app.git" 
    }

    stages {
        // Stage 1: Clone from GitHub using credentials
        stage('Clone Repository') {
            steps {
                echo "Cloning GitHub repository with credentials..."
                sh '''
                    rm -rf maven-web-app || true
                    git clone https://${GITHUB_CRED_USR}:${GITHUB_CRED_PSW}@github.com/sunrisers-heroic/maven-web-app.git  maven-web-app
                    cd maven-web-app
                    git checkout main || git checkout -b main
                '''
            }
        }

        // Stage 2: Build with Maven
        stage('Build with Maven') {
            steps {
                echo "Building project with Maven..."
                sh """
                    cd maven-web-app
                    ${MAVEN_CMD} -s ${SETTINGS_FILE} clean package
                """
            }
        }

        // Stage 3: Run SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."
                withSonarQubeEnv('SonarQube') {
                    sh """
                        cd maven-web-app
                        ${MAVEN_CMD} -s ${SETTINGS_FILE} sonar:sonar -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        // Stage 4: Deploy to Nexus
        stage('Deploy to Nexus') {
            steps {
                echo "Deploying artifact to Nexus..."
                sh """
                    cd maven-web-app
                    ${MAVEN_CMD} -s ${SETTINGS_FILE} deploy
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
