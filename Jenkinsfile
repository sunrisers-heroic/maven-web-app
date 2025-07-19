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
        DOCKER_REGISTRY = "sunrisersheroic/\${DOCKER_IMAGE_NAME}"
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
                    ${MAVEN_CMD} -s \${MAVEN_SETTINGS} clean package
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
                        ${MAVEN_CMD} -s \${MAVEN_SETTINGS} sonar:sonar -Dsonar.login=${SONAR_TOKEN}
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
                    ${MAVEN_CMD} -s \${MAVEN_SETTINGS} deploy || echo "⚠️ Skipping Nexus deploy for now"
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
                echo "Detected Version: \${BUILD_VERSION}"
            }

            // Build Docker image using local WAR file
            sh """
                cd maven-web-app
                docker build -t sunrisersheroic/maven-web-app:\${BUILD_VERSION} .
                docker tag sunrisersheroic/maven-web-app:\${BUILD_VERSION} sunrisersheroic/maven-web-app:latest
            """

            // Push to Docker Hub
            sh """
                docker login -u \${DOCKER_CRED_USR} -p \${DOCKER_CRED_PSW}
                docker push sunrisersheroic/maven-web-app:\${BUILD_VERSION}
                docker push sunrisersheroic/maven-web-app:latest
            """

            echo "✅ Docker image pushed to Docker Hub!"

            // -------------------------------
            // ✅ ADDING KUBERNETES DEPLOYMENT IN POST BLOCK
            // -------------------------------
            script {
                echo "Verifying Kubernetes cluster connection..."

                // Inject kubeconfig from Jenkins credentials
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBE_CONFIG')]) {
                    sh '''
                        # Write kubeconfig
                        mkdir -p ~/.kube
                        echo "$KUBE_CONFIG" > ~/.kube/config
                        chmod 600 ~/.kube/config
                    '''
                }

                // Verify Kubernetes connection
                sh 'kubectl get nodes'
                sh 'kubectl get deployments --all-namespaces'
                sh 'kubectl cluster-info'
                sh 'echo "Kubernetes connection successful!"'

                echo "Creating Kubernetes Deployment and Service for sunrisersheroic/maven-web-app..."

                // Apply Deployment
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
        image: sunrisersheroic/maven-web-app:latest
        ports:
        - containerPort: 8080
EOF
                '''

                // Apply Service
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
      targetPort: 8080
      nodePort: 30080
EOF
                '''

                echo "Deployment and Service applied. Checking status..."
                sh 'kubectl get deployment sunrisers-heroic-webapp-deployment'
                sh 'kubectl get service sunrisers-heroic-webapp-service'
                sh 'echo "✅ Your application should now be deploying on the worker nodes!"'
            }
        }

        failure {
            echo "❌ Pipeline failed but attempting fallback Docker build..."

            script {
                // Try to get version even after failure
                def pomVersion = sh(script: 'cd maven-web-app && grep -m1 "<version>.*</version>" pom.xml | sed -E "s/.*<version>(.*)<\\/version>.*/\\1/"', returnStdout: true).trim()
                env.BUILD_VERSION = pomVersion ?: "latest"
                echo "Using version: \${BUILD_VERSION}"
            }

            // Attempt fallback Docker build
            sh """
                cd maven-web-app
                docker build -t sunrisersheroic/maven-web-app:\${BUILD_VERSION} . || echo "Failed to build Docker image"
            """

            echo "⚠️ If Docker build failed, check logs above"
        }
    }
}
