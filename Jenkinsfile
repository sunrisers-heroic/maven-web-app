pipeline {
    agent any

    environment {
        // Git commit hash for versioning
        GIT_COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        
        // Artifact version using build number
        VERSION = "1.0.\${env.BUILD_NUMBER}"
        
        // Nexus settings
        NEXUS_SERVER = "44.211.221.99"
        NEXUS_PORT = "8081"
        REPOSITORY = "maven-releases"
        GROUP_ID = "com.app.raghu"
        ARTIFACT_ID = "01-maven-web-app"
        FILE_PATH = "target/01-maven-web-app.war"
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

        // Stage 3: Upload WAR to Nexus v3.81
        stage('Upload WAR to Nexus') {
            steps {
                nexusArtifactUploader(
                    artifacts: [
                        [artifactId: "${ARTIFACT_ID}", file: "${FILE_PATH}", type: "war"]
                    ],
                    credentialsId: "nexus-maven-hub",
                    groupId: "${GROUP_ID}",
                    nexusUrl: "${NEXUS_SERVER}:${NEXUS_PORT}",
                    protocol: "http",
                    repository: "${REPOSITORY}",
                    version: "${VERSION}"
                )
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: WAR uploaded to Nexus v3.81!"
        }
        failure {
            echo "❌ FAILURE: Something went wrong during build or upload."
        }
    }
}
