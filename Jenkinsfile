pipeline {
    agent any

    environment {
        // Use full path to mvn
        MAVEN_CMD = "/opt/maven/bin/mvn"
        MAVEN_SETTINGS = "maven.settings.xml"

        // Credentials
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CRED = credentials('github-credentials')
        DOCKER_CRED = credentials('docker-hub-credentials')

        // Project info
        DOCKER_IMAGE_NAME = "maven-web-app"
        DOCKER_REGISTRY = "sunrisersheroic/${DOCKER_IMAGE_NAME}" // Corrected string interpolation for Groovy

        // Kubernetes Deployment specific info
        APP_CONTAINER_PORT = 8090 // <<< IMPORTANT: Confirm this is the port your Maven web app listens on
        K8S_SERVICE_NODEPORT = 30090 // <<< IMPORTANT: NodePort for external access (choose 30000-32767)
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

            echo "✅ Pipeline succeeded — starting Docker image build..."

            script {
                // Manually extract version from pom.xml using shell
                def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true).trim()
                env.BUILD_VERSION = pomVersion ?: "latest"
                echo "Detected Version: ${BUILD_VERSION}"
            }

            // Build Docker image using local WAR file
            sh """
                cd maven-web-app
                docker build -t ${DOCKER_REGISTRY}:${BUILD_VERSION} .
                docker tag ${DOCKER_REGISTRY}:${BUILD_VERSION} ${DOCKER_REGISTRY}:latest
            """

            // Push to Docker Hub
            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USR', passwordVariable: 'DOCKER_PSW')]) {
                sh """
                    docker login -u ${DOCKER_USR} -p ${DOCKER_PSW}
                    docker push ${DOCKER_REGISTRY}:${BUILD_VERSION}
                    docker push ${DOCKER_REGISTRY}:latest
                """
            }
            echo "✅ Docker image pushed to Docker Hub!"

            // --- Kubernetes Deployment starts here ---
            echo "Deploying ${DOCKER_REGISTRY}:${BUILD_VERSION} to Kubernetes..."

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
      annotations:
        # This annotation forces a rolling update even if the image tag is 'latest' and its content changed,
        # or if you simply want to force a restart of pods. Timestamp changes on every run.
        kubectl.kubernetes.io/restartedAt: "''' + new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC')) + '''"
    spec:
      containers:
      - name: sunrisers-heroic-webapp-container
        image: ''' + "${DOCKER_REGISTRY}:${BUILD_VERSION}" + ''' # Use the built and pushed image version
        ports:
        - containerPort: ''' + "${APP_CONTAINER_PORT}" + '''
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
  type: NodePort
  ports:
    - protocol: TCP
      port: 80
      targetPort: ''' + "${APP_CONTAINER_PORT}" + '''
      nodePort: ''' + "${K8S_SERVICE_NODEPORT}" + '''
EOF
            '''
            echo "Deployment and Service applied. Waiting for deployment rollout to complete..."
            sh 'kubectl rollout status deployment/sunrisers-heroic-webapp-deployment --timeout=5m'
            echo "✅ Application deployment initiated on Kubernetes worker nodes!"
            // --- Kubernetes Deployment ends here ---
        }

        failure {
            echo "❌ Pipeline failed but attempting fallback Docker build..."

            script {
                // Try to get version even after failure
                def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true, allowEmptyStdout: true).trim()
                env.BUILD_VERSION = pomVersion ?: "latest"
                echo "Using version: ${BUILD_VERSION}"
            }

            // Attempt fallback Docker build
            sh """
                cd maven-web-app
                docker build -t ${DOCKER_REGISTRY}:${BUILD_VERSION} . || echo "Failed to build Docker image"
            """

            echo "⚠️ If Docker build failed, check logs above"
        }

        always {
            echo "Pipeline finished."
        }
    }
}
