pipeline {
    agent any

    environment {
        // Git commit hash for versioning
        GIT_COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        
        // Artifact version using build number + git commit
        VERSION = "1.0-SNAPSHOT"
    }

    stages {
        // Stage 1: Clone Code from GitHub
        stage('Clone Repository') {
            steps {
                git branch: 'main',
                     url: 'https://github.com/sunrisers-heroic/maven-web-app.git', 
                     credentialsId: 'github-credentials'
            }
        }

        // Stage 2: Build WAR with Maven
        stage('Build WAR with Maven') {
            steps {
                script {
                    def mavenHome = tool name: "M3", type: "maven"
                    sh "${mavenHome}/bin/mvn clean package"
                }
            }
        }

        // Stage 3: Upload WAR to Nexus Snapshots
        stage('Upload WAR to Nexus Snapshots') {
            steps {
                nexusArtifactUploader(
                    artifacts: [
                        [artifactId: '01-maven-web-app', file: 'target/01-maven-web-app.war', type: 'war']
                    ],
                    credentialsId: 'nexus-maven-hub',
                    groupId: 'com.app.raghu',
                    nexusUrl: '44.211.221.99:8081',
                    protocol: 'http',
                    repository: 'maven-snapshots',
                    version: "${VERSION}"
                )
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: WAR uploaded to Nexus Snapshots!"
        }
        failure {
            echo "❌ FAILURE: Something went wrong during build or upload."
        }
    }
}
