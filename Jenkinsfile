pipeline {
    agent any

    environment {
        // Use full path to mvn
        MAVEN_CMD = "/opt/maven/bin/mvn"
        MAVEN_SETTINGS = "maven.settings.xml" // Ensure this file is in the project root or configured globally

        // Credentials IDs configured in Jenkins
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CRED = credentials('github-credentials') // Username with password
        DOCKER_CRED = credentials('docker-hub-credentials') // Username with password

        // Project info
        DOCKER_IMAGE_NAME = "maven-web-app"
        DOCKER_REGISTRY = "sunrisersheroic/${DOCKER_IMAGE_NAME}"

        // Kubernetes Deployment specific info
        // IMPORTANT: This port MUST match the port your Tomcat application listens on inside the Docker container.
        // Your Dockerfile sets Tomcat's port to 8090.
        APP_CONTAINER_PORT = 8090 // <<< CORRECTED to 8090 to match Dockerfile
        K8S_SERVICE_NODEPORT = 30090 // NodePort for external access (choose 30000-32767)
    }

    stages {
        // Stage 1: Clone Repository
        stage('Clone Repository') {
            steps {
                echo "Cloning GitHub repository..."
                sh '''
                    # Clean up previous clone to ensure a fresh start
                    rm -rf maven-web-app || true
                    # Clone the repository using GitHub credentials
                    git clone https://$GITHUB_CRED_USR:$GITHUB_CRED_PSW@github.com/sunrisers-heroic/maven-web-app.git maven-web-app
                    # Change into the cloned directory
                    cd maven-web-app
                    # Checkout the 'main' branch
                    git checkout main
                '''
            }
        }

        // Stage 2: Build with Maven
        stage('Build with Maven') {
            steps {
                echo "Building project with Maven..."
                sh """
                    # Change into the project directory
                    cd maven-web-app
                    # Execute Maven clean and package goals using the specified settings file
                    ${MAVEN_CMD} -s ${MAVEN_SETTINGS} clean package
                """
                echo "✅ Build completed!"
            }
        }

        // Stage 3: SonarQube Analysis
        stage('SonarQube Analysis') {
            steps {
                echo "Running SonarQube analysis..."
                // Execute SonarQube analysis within the configured SonarQube environment
                withSonarQubeEnv('SonarQube') { // 'SonarQube' is the name of your SonarQube server configuration in Jenkins
                    sh """
                        # Change into the project directory
                        cd maven-web-app
                        # Run SonarQube analysis with Maven, using the SonarQube token
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
                    # Change into the project directory
                    cd maven-web-app
                    # Attempt to deploy the artifact to Nexus. '|| echo' prevents pipeline failure if deploy fails.
                    ${MAVEN_CMD} -s ${MAVEN_SETTINGS} deploy || echo "⚠️ Skipping Nexus deploy for now or it failed. Check Maven logs."
                """
                echo "✅ Artifact deployment attempted."
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded — starting Docker image build and Kubernetes deployment..."

            script {
                // Extract the project version from pom.xml to use as Docker image tag
                // This command reads the version tag from pom.xml
                def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true).trim()
                // Set BUILD_VERSION environment variable, defaulting to "latest" if not found
                env.BUILD_VERSION = pomVersion ?: "latest"
                echo "Detected Version: ${BUILD_VERSION}"
            }

            // Build Docker image using the Dockerfile in the current context
            sh """
                # Change into the directory containing the Dockerfile and target WAR
                cd maven-web-app
                # Build the Docker image, tagging it with the detected version
                docker build -t ${DOCKER_REGISTRY}:${BUILD_VERSION} .
                # Also tag the image with 'latest' for easy reference
                docker tag ${DOCKER_REGISTRY}:${BUILD_VERSION} ${DOCKER_REGISTRY}:latest
            """

            // Push Docker image to Docker Hub using Jenkins credentials
            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USR', passwordVariable: 'DOCKER_PSW')]) {
                sh """
                    # Log in to Docker Hub
                    docker login -u ${DOCKER_USR} -p ${DOCKER_PSW}
                    # Push the versioned image
                    docker push ${DOCKER_REGISTRY}:${BUILD_VERSION}
                    # Push the 'latest' tagged image
                    docker push ${DOCKER_REGISTRY}:latest
                """
            }
            echo "✅ Docker image pushed to Docker Hub!"

            // --- Kubernetes Deployment starts here ---
            echo "Deploying ${DOCKER_REGISTRY}:${BUILD_VERSION} to Kubernetes..."

            // --- Clean up existing Kubernetes resources before deploying ---
            echo "Attempting to delete existing Kubernetes Deployment and Service (if any)..."
            sh 'kubectl delete deployment sunrisers-heroic-webapp-deployment --ignore-not-found=true || true'
            sh 'kubectl delete service sunrisers-heroic-webapp-service --ignore-not-found=true || true'
            echo "Existing resources cleanup attempted."
            // --- End cleanup ---

            // Define and apply the Kubernetes Deployment using kubectl apply -f -
            // This creates/updates the deployment for your web application
            sh '''
                cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sunrisers-heroic-webapp-deployment
  labels:
    app: sunrisers-heroic-webapp
spec:
  replicas: 2 # You can adjust the number of desired application instances
  selector:
    matchLabels:
      app: sunrisers-heroic-webapp
  template:
    metadata:
      labels:
        app: sunrisers-heroic-webapp
      annotations:
        # This annotation forces a rolling update of pods on every pipeline run,
        # even if the image tag is 'latest' and its content changed, or to simply restart pods.
        # The timestamp changes on every run.
        kubectl.kubernetes.io/restartedAt: "''' + new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC')) + '''"
    spec:
      containers:
      - name: sunrisers-heroic-webapp-container
        # Use the Docker image built and pushed in the previous steps
        image: ''' + "${DOCKER_REGISTRY}:${BUILD_VERSION}" + '''
        ports:
        - containerPort: ''' + "${APP_CONTAINER_PORT}" + ''' # This is the port the container exposes (8090)
EOF
            '''

            // Define and apply the Kubernetes Service
            // This creates a NodePort service to expose your application externally
            sh '''
                cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: sunrisers-heroic-webapp-service
spec:
  selector:
    app: sunrisers-heroic-webapp
  type: NodePort # Exposes the service on a port on each Node's IP
  ports:
    - protocol: TCP
      port: 80 # The port the service itself will listen on
      targetPort: ''' + "${APP_CONTAINER_PORT}" + ''' # The port on the pod that the service forwards to (8090)
      nodePort: ''' + "${K8S_SERVICE_NODEPORT}" + ''' # The static port on the Node's IP (e.g., 30090)
EOF
            '''
            echo "Deployment and Service applied. Waiting for deployment rollout to complete..."
            # Wait for the deployment to be stable before marking the stage as complete
            sh 'kubectl rollout status deployment/sunrisers-heroic-webapp-deployment --timeout=5m'
            echo "✅ Application deployment initiated on Kubernetes cluster!"
            // --- Kubernetes Deployment ends here ---
        }

        failure {
            echo "❌ Pipeline failed! Attempting fallback Docker build..."

            script {
                // Try to get version even after failure for logging/debugging purposes
                def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true, allowEmptyStdout: true).trim()
                env.BUILD_VERSION = pomVersion ?: "latest"
                echo "Using version: ${BUILD_VERSION}"
            }

            // Attempt fallback Docker build (e.g., if SonarQube failed but code compiled)
            sh """
                cd maven-web-app
                docker build -t ${DOCKER_REGISTRY}:${BUILD_VERSION} . || echo "Failed to build Docker image during fallback"
            """

            echo "⚠️ If Docker build failed during fallback, check logs above for details."
        }

        always {
            echo "Pipeline finished."
        }
    }
}
