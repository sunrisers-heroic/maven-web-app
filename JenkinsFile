pipeline {
    agent any

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main',
                     url: 'https://github.com/sunrisers-heroic/maven-web-app.git', 
                     credentialsId: 'github-credentials'
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: Code successfully cloned from GitHub!"
        }
        failure {
            echo "❌ FAILURE: Could not clone from GitHub."
        }
    }
}
