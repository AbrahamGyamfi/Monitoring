#!/bin/bash
set -e

echo "AfterInstall: Setting up application..."
cd /home/ec2-user/taskflow

# Get AWS region and account ID from instance metadata
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "eu-west-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "697863031884")
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

export IMAGE_TAG="latest"
export REGISTRY_URL="${ECR_REGISTRY}"

echo "AfterInstall: Using ECR Registry: ${ECR_REGISTRY}"
echo "AfterInstall: Using IMAGE_TAG: ${IMAGE_TAG}"

# Login to ECR
echo "AfterInstall: Logging into ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

echo "AfterInstall: Pulling Docker images..."
docker pull ${ECR_REGISTRY}/taskflow-backend:${IMAGE_TAG} || echo "Warning: Could not pull backend image"
docker pull ${ECR_REGISTRY}/taskflow-frontend:${IMAGE_TAG} || echo "Warning: Could not pull frontend image"

# Save environment for application_start.sh
echo "REGISTRY_URL=${ECR_REGISTRY}" > /home/ec2-user/taskflow/.env
echo "IMAGE_TAG=${IMAGE_TAG}" >> /home/ec2-user/taskflow/.env

echo "AfterInstall: Complete"
