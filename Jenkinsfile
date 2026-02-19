pipeline {
    agent any
    
    environment {
        // AWS ECR Configuration
        AWS_REGION = 'eu-west-1'
        AWS_ACCOUNT_ID = '697863031884'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        AWS_CREDENTIALS_ID = 'aws-credentials'
        
        // Docker images
        BACKEND_IMAGE = "${ECR_REGISTRY}/taskflow-backend"
        FRONTEND_IMAGE = "${ECR_REGISTRY}/taskflow-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // EC2 Deployment Server
        EC2_CREDENTIALS_ID = 'ec2-ssh-key'
        EC2_HOST = '54.170.165.207'
        EC2_USER = 'ec2-user'
        
        // Application
        APP_NAME = 'taskflow'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '📥 Checking out code...'
                    checkout scm
                    
                    // Get git commit info
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                    
                    echo "Commit: ${env.GIT_COMMIT_MSG}"
                    echo "Author: ${env.GIT_AUTHOR}"
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend') {
                    steps {
                        script {
                            echo '🔨 Building backend Docker image...'
                            dir('backend') {
                                sh """
                                    docker build \
                                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                        --build-arg VCS_REF=\${GIT_COMMIT} \
                                        --build-arg BUILD_NUMBER=\${BUILD_NUMBER} \
                                        -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                                        -t ${BACKEND_IMAGE}:latest \
                                        .
                                """
                            }
                        }
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        script {
                            echo '🔨 Building frontend Docker image...'
                            dir('frontend') {
                                sh """
                                    docker build \
                                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                        --build-arg VCS_REF=\${GIT_COMMIT} \
                                        --build-arg BUILD_NUMBER=\${BUILD_NUMBER} \
                                        -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                                        -t ${FRONTEND_IMAGE}:latest \
                                        .
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Run Unit Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        script {
                            echo '🧪 Running backend unit tests...'
                            dir('backend') {
                                sh """
                                    # Run backend tests in Node container
                                    docker run --rm -v \$(pwd):/app -w /app node:18-alpine sh -c '
                                        npm install
                                        npm test
                                    '
                                """
                            }
                        }
                    }
                }
                
                stage('Frontend Tests') {
                    steps {
                        script {
                            echo '🧪 Running frontend unit tests...'
                            dir('frontend') {
                                sh """
                                    # Run frontend tests in Node container
                                    docker run --rm -v \$(pwd):/app -w /app node:18-alpine sh -c '
                                        npm install --legacy-peer-deps
                                        CI=true npm test -- --passWithNoTests
                                    '
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('Backend Lint') {
                    steps {
                        script {
                            echo '🔍 Running backend linting...'
                            dir('backend') {
                                sh """
                                    # Run linting in Node container
                                    docker run --rm -v \$(pwd):/app -w /app node:18-alpine sh -c '
                                        npm install
                                        npm run lint || echo "Linting warnings found"
                                    '
                                """
                            }
                        }
                    }
                }
                
                stage('Test Images') {
                    steps {
                        script {
                            echo '🐳 Testing Docker images...'
                            
                            // Test backend
                            sh """
                                echo "Testing backend image..."
                                docker run --rm ${BACKEND_IMAGE}:${IMAGE_TAG} node --version
                                docker run --rm ${BACKEND_IMAGE}:${IMAGE_TAG} npm --version
                            """
                            
                            // Test frontend
                            sh """
                                echo "Testing frontend image..."
                                docker run --rm ${FRONTEND_IMAGE}:${IMAGE_TAG} nginx -v
                            """
                        }
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    echo '🔗 Running integration tests...'
                    
                    // Start containers temporarily for testing
                    sh """
                        # Start backend in background
                        docker run -d --name test-backend-${BUILD_NUMBER} \
                            -p 5001:5000 ${BACKEND_IMAGE}:${IMAGE_TAG}
                        
                        # Wait for backend to be ready
                        sleep 5
                        
                        # Test health endpoint
                        curl -f http://localhost:5001/health || exit 1
                        
                        # Test GET tasks
                        curl -f http://localhost:5001/api/tasks || exit 1
                        
                        # Test POST task
                        curl -X POST http://localhost:5001/api/tasks \
                            -H 'Content-Type: application/json' \
                            -d '{"title":"Test Task","priority":"high"}' || exit 1
                        
                        # Test GET tasks again (should have 1 task)
                        TASKS=\$(curl -s http://localhost:5001/api/tasks)
                        echo "Tasks: \$TASKS"
                        
                        # Cleanup
                        docker stop test-backend-${BUILD_NUMBER}
                        docker rm test-backend-${BUILD_NUMBER}
                        
                        echo "✅ Integration tests passed!"
                    """
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    echo '📤 Pushing images to AWS ECR...'
                    
                    // Login to ECR using AWS CLI (credentials already configured)
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    """
                    
                    // Push backend images
                    sh """
                        docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                        docker push ${BACKEND_IMAGE}:latest
                    """
                    
                    // Push frontend images
                    sh """
                        docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                        docker push ${FRONTEND_IMAGE}:latest
                    """
                    
                    echo "✅ Images pushed successfully to ECR!"
                    echo "Backend: ${BACKEND_IMAGE}:${IMAGE_TAG}"
                    echo "Frontend: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                script {
                    echo '🚀 Deploying to EC2...'
                    
                    // Create deployment directory
                    sh """
                        ssh -i /var/lib/jenkins/.ssh/taskflow-key.pem -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                            mkdir -p ~/taskflow
                        '
                    """
                    
                    // Copy docker-compose file
                    sh """
                        scp -i /var/lib/jenkins/.ssh/taskflow-key.pem -o StrictHostKeyChecking=no \
                            docker-compose.prod.yml \
                            ${EC2_USER}@${EC2_HOST}:~/taskflow/docker-compose.yml
                    """
                    
                    // Deploy application
                    sh """
                        ssh -i /var/lib/jenkins/.ssh/taskflow-key.pem -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                            cd ~/taskflow
                            
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            
                            # Pull latest images
                            docker pull ${BACKEND_IMAGE}:${IMAGE_TAG}
                            docker pull ${FRONTEND_IMAGE}:${IMAGE_TAG}
                            
                            # Stop existing containers
                            docker-compose down || true
                            
                            # Start new containers
                            IMAGE_TAG=${IMAGE_TAG} docker-compose up -d
                            
                            # Wait for services to be healthy
                            sleep 10
                            
                            # Check container status
                            docker-compose ps
                            
                            # Verify application is running
                            curl -f http://localhost/health || exit 1
                            
                            echo "✅ Deployment successful!"
                        '
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo '🏥 Running health checks...'
                    
                    def healthStatus = sh(
                        script: """
                            ssh -i /var/lib/jenkins/.ssh/taskflow-key.pem -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                                curl -s http://localhost/health | grep healthy
                            '
                        """,
                        returnStatus: true
                    )
                    
                    if (healthStatus == 0) {
                        echo "✅ Application is healthy!"
                    } else {
                        error "❌ Health check failed!"
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo '🧹 Cleaning up...'
                // Clean up Docker images on Jenkins server
                sh """
                    docker image prune -f
                    docker container prune -f
                """
            }
        }
        
        success {
            echo '✅ =================================='
            echo '✅ PIPELINE COMPLETED SUCCESSFULLY!'
            echo '✅ =================================='
            echo "Backend Image: ${BACKEND_IMAGE}:${IMAGE_TAG}"
            echo "Frontend Image: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
            echo "Deployed to: http://${EC2_HOST}"
        }
        
        failure {
            echo '❌ =================================='
            echo '❌ PIPELINE FAILED!'
            echo '❌ =================================='
        }
    }
}
