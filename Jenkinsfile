pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'M3' // Make sure this matches the name in Global Tool Config
        MAVEN_CMD = "${MAVEN_HOME}/bin/mvn"
        SONAR_TOKEN = credentials('sonarqube-token') // Stored in Jenkins Credentials
        SETTINGS_FILE = "/var/lib/jenkins/settings.xml" // Your custom settings.xml path
    }

    stages {
        // Stage 1: Clone from GitHub
        stage('Clone Repository') {
            steps {
                echo "Cloning GitHub repository..."
                git branch: 'main', // Change if using 'master' or another branch
                     url: 'https://github.com/sunrisers-heroic/maven-web-app.git' 
            }
        }

        // Stage 2: Build with Maven
        stage('Build with Maven') {
            steps {
                echo "Building project with Maven..."
                sh "${MAVEN_CMD} -s ${SETTINGS_FILE} clean package"
            }
        }

        // Stage 3: Run SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."
                withSonarQubeEnv('SonarQube') { // 'SonarQube' is the server name configured in Jenkins
                    sh "${MAVEN_CMD} -s ${SETTINGS_FILE} sonar:sonar -Dsonar.login=${SONAR_TOKEN}"
                }
            }
        }

        // Stage 4: Deploy to Nexus
        stage('Deploy to Nexus') {
            steps {
                echo "Deploying artifact to Nexus..."
                sh "${MAVEN_CMD} -s ${SETTINGS_FILE} deploy"
            }
        }
    }

    // Optional: Post-build actions
    post {
        success {
            echo "✅ Pipeline succeeded!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
