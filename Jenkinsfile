pipeline {
    agent any

    environment {
        // Use full path to mvn
        MAVEN_CMD = "/opt/maven/bin/mvn"
        MAVEN_SETTINGS = "maven.settings.xml"

        // Credentials IDs - Ensure these are configured in Jenkins
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CRED = credentials('github-credentials') // Assumes GITHUB_CRED_USR, GITHUB_CRED_PSW are exposed
        // DOCKER_CRED is handled via withCredentials in the post block

        // Project and Docker image info
        DOCKER_IMAGE_NAME = "maven-web-app"
        DOCKER_REGISTRY_REPO = "sunrisersheroic" // Your Docker Hub username or organization
        DOCKER_FULL_IMAGE_NAME = "${DOCKER_REGISTRY_REPO}/${DOCKER_IMAGE_NAME}"

        APP_CONTAINER_PORT = 8080 // <<< IMPORTANT: Confirm this is the port your Maven web app listens on
        K8S_SERVICE_NODEPORT = 30080 // <<< IMPORTANT: NodePort for external access (choose 30000-32767)
    }

    stages {
        // Stage 1: Clone Repository
        stage('Clone Repository') {
            steps {
                echo "Cloning GitHub repository..."
                sh '''
                    rm -rf maven-web-app || true
                    git clone https://$GITHUB_CRED_USR:$GITHUB_CRED_PSW@github.com/sunrisers-heroic/maven-web-app.git maven-web-app
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
                    ${MAVEN_CMD} -s ${MAVEN_SETTINGS} clean package
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
                        ${MAVEN_CMD} -s ${MAVEN_SETTINGS} sonar:sonar -Dsonar.login=${SONAR_TOKEN}
                    """
                }
                echo "✅ Code analysis completed!"
            }
        }

        // Stage 4: Deploy to Nexus (optional)
        stage('Deploy to Nexus') {
            steps {
                echo "Deploying artifact to Nexus..."
                sh """
                    cd maven-web-app
                    ${MAVEN_CMD} -s ${MAVEN_SETTINGS} deploy || echo "⚠️ Skipping Nexus deploy for now"
                """
                echo "✅ Artifact deployment attempted."
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded — starting Docker image build and Kubernetes deployment..."

            script {
                // Manually extract version from pom.xml using shell
                def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true).trim()
                env.BUILD_VERSION = pomVersion ?: "latest"
                echo "Detected Application Version: ${BUILD_VERSION}"
            }

            // Build Docker image using local WAR file
            sh """
                cd maven-web-app
                docker build -t ${DOCKER_FULL_IMAGE_NAME}:${BUILD_VERSION} .
                docker tag ${DOCKER_FULL_IMAGE_NAME}:${BUILD_VERSION} ${DOCKER_FULL_IMAGE_NAME}:latest
            """

            // Push to Docker Hub securely
            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USR', passwordVariable: 'DOCKER_PSW')]) {
                sh """
                    docker login -u ${DOCKER_USR} -p ${DOCKER_PSW}
                    docker push ${DOCKER_FULL_IMAGE_NAME}:${BUILD_VERSION}
                    docker push ${DOCKER_FULL_IMAGE_NAME}:latest
                """
            }
            echo "✅ Docker image pushed to Docker Hub!"

            // --- Kubernetes Deployment starts here ---
            echo "Deploying ${DOCKER_FULL_IMAGE_NAME}:${BUILD_VERSION} to Kubernetes..."

            // Define and apply the Kubernetes Deployment
            sh '''
                cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sunrisers-heroic-webapp-deployment
  labels:
    app: sunrisers-heroic-webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sunrisers-heroic-webapp
  template:
    metadata:
      labels:
        app: sunrisers-heroic-webapp
    spec:
      containers:
      - name: sunrisers-heroic-webapp-container
        image: ''' + "${DOCKER_FULL_IMAGE_NAME}:${BUILD_VERSION}" + ''' # Use the built and pushed image
        ports:
        - containerPort: ''' + "${APP_CONTAINER_PORT}" + ''' # Internal port of your app
EOF
            '''

            // Define and apply the Kubernetes Service
            sh '''
                cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: sunrisers-heroic-webapp-service
spec:
  selector:
    app: sunrisers-heroic-webapp
  type: NodePort # Expose via NodePort on all Kubernetes nodes
  ports:
    - protocol: TCP
      port: 80 # Service port (internal cluster access)
      targetPort: ''' + "${APP_CONTAINER_PORT}" + ''' # Must match containerPort
      nodePort: ''' + "${K8S_SERVICE_NODEPORT}" + ''' # External port on K8s nodes (30000-32767)
EOF
            '''
            echo "Kubernetes Deployment and Service applied. Checking status..."
            sh 'kubectl get deployment sunrisers-heroic-webapp-deployment'
            sh 'kubectl get service sunrisers-heroic-webapp-service'
            sh 'kubectl get pods -l app=sunrisers-heroic-webapp --watch & sleep 10 && kill $!' # Watch pods briefly
            echo "✅ Application deployment initiated on Kubernetes worker nodes!"
            // --- Kubernetes Deployment ends here ---

        } // End of post.success block

        failure {
            echo "❌ Pipeline failed! Review the console output for errors in any stage."

            // Attempt fallback Docker build for debugging
            script {
                // Try to get version even after failure
                def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true, allowEmptyStdout: true).trim()
                env.BUILD_VERSION = pomVersion ?: "latest"
                echo "Attempting fallback Docker build for version: ${BUILD_VERSION}"
            }
            sh """
                cd maven-web-app
                docker build -t ${DOCKER_FULL_IMAGE_NAME}:${BUILD_VERSION} . || echo "Fallback Docker image build failed."
            """
        }

        always {
            echo "Pipeline finished."
        }
    }
}
