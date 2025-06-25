pipeline {
    agent any

    environment {
        MAVEN_HOME = tool 'M3'
        MAVEN_CMD = "${MAVEN_HOME}/bin/mvn"
        SETTINGS_FILE = "/var/lib/jenkins/settings.xml"
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CRED = credentials('github-credentials')
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo "Cloning GitHub repo..."
                sh '''
                    rm -rf maven-web-app || true
                    git clone https://${GITHUB_CRED_USR}:${GITHUB_CRED_PSW}@github.com/sunrisers-heroic/maven-web-app.git  maven-web-app
                    cd maven-web-app
                    git checkout main
                '''
            }
        }

        stage('Build with Maven') {
            steps {
                echo "Building with Maven 3.9.10..."
                sh """
                    cd maven-web-app
                    ${MAVEN_CMD} -s ${SETTINGS_FILE} clean package
                """
            }
        }

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

        stage('Deploy to Nexus') {
            steps {
                echo "Deploying to Nexus..."
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
            echo "❌ Pipeline failed! Check logs."
        }
    }
}
