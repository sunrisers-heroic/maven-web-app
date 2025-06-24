pipeline {
    agent any

    stages {
        // Stage 1: Clone Code from GitHub
        stage('Clone Repository') {
            steps {
                git branch: 'main',
                     url: 'https://github.com/sunrisers-heroic/maven-web-app.git', 
                     credentialsId: 'github-credentials'
            }
        }

        // Stage 2: Build WAR using Maven
        stage('Build WAR with Maven') {
            steps {
                script {
                    def mavenHome = tool name: "M3", type: "maven"
                    sh "${mavenHome}/bin/mvn clean package"
                }
            }
        }

        // Stage 3: Upload WAR to Nexus
        stage('Upload WAR to Nexus') {
            steps {
                nexusArtifactUploader(
                    artifacts: [
                        [artifactId: '01-maven-web-app', file: 'target/01-maven-web-app.war', type: 'war']
                    ],
                    credentialsId: 'nexus-maven-hub',
                    groupId: 'com.app.raghu',
                    nexusUrl: '44.211.221.99:8081',  // Your Nexus server IP
                    protocol: 'http',
                    repository: 'maven-releases'       // Or 'maven-snapshots' for dev builds
                )
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: Application built and uploaded to Nexus!"
        }
        failure {
            echo "❌ FAILURE: Something went wrong during build or upload."
        }
    }
}
