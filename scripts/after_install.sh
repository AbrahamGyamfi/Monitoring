#!/bin/bash
set -e

echo "AfterInstall: Logging into ECR..."
cd /home/ec2-user/taskflow

# Get AWS region and account ID from environment or metadata
REGION=$(aws configure get region || echo "eu-west-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

echo "AfterInstall: Pulling Docker images..."
# Read image tags from deployment metadata
if [ -f .deployment_metadata ]; then
    source .deployment_metadata
    docker pull ${ECR_REGISTRY}/taskflow-backend:${IMAGE_TAG}
    docker pull ${ECR_REGISTRY}/taskflow-frontend:${IMAGE_TAG}
else
    echo "Warning: No deployment metadata found, using latest tag"
    docker pull ${ECR_REGISTRY}/taskflow-backend:latest
    docker pull ${ECR_REGISTRY}/taskflow-frontend:latest
fi

echo "AfterInstall: Complete"
