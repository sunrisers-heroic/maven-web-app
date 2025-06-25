pipeline {
    agent any

    environment {
        SETTINGS_FILE = "/var/lib/jenkins/settings.xml"
        SONAR_TOKEN = credentials('sonarqube-token') // Must be defined in Jenkins Credentials
        GITHUB_CRED = credentials('github-credentials') // Your GitHub username/password credential ID
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
                echo "Building project with Maven (using 'mvn' command)..."
                sh """
                    cd maven-web-app
                    mvn -s ${SETTINGS_FILE} clean package
                """
                echo "✅ Build completed successfully!"
            }
        }

        // Stage 3: Run SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."
                withSonarQubeEnv('SonarQube') { // Make sure 'SonarQube' server is configured in Jenkins
                    sh """
                        cd maven-web-app
                        mvn -s ${SETTINGS_FILE} sonar:sonar -Dsonar.login=${SONAR_TOKEN}
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
                    mvn -s ${SETTINGS_FILE} deploy
                """
                echo "✅ Artifact deployed to Nexus!"
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
