pipeline {
    agent any

    environment {
        // Name of the settings.xml file you uploaded in Jenkins UI
        MAVEN_SETTINGS = "settings.xml"

        // Credentials from Jenkins Credentials Store
        SONAR_TOKEN = credentials('sonarqube-token') // Secret text credential ID
        GITHUB_CRED = credentials('github-credentials') // GitHub username/password credential ID

        // GitHub repo URL
        GITHUB_REPO = "https://github.com/sunrisers-heroic/maven-web-app.git" 
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
                echo "Building project with Maven using custom settings..."
                sh """
                    cd maven-web-app
                    mvn -s \${MAVEN_SETTINGS} clean package
                """
            }
        }

        // Stage 3: Run SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."
                withSonarQubeEnv('SonarQube') { // Ensure this matches your Sonar server name
                    sh """
                        cd maven-web-app
                        mvn -s \${MAVEN_SETTINGS} sonar:sonar -Dsonar.login=${SONAR_TOKEN}
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
                    mvn -s \${MAVEN_SETTINGS} deploy
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
