#!/bin/bash
set -e

echo "ApplicationStart: Starting containers..."
cd /home/ec2-user/taskflow

# Get AWS region and account ID
REGION=$(aws configure get region || echo "eu-west-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Read image tag from deployment metadata
if [ -f .deployment_metadata ]; then
    source .deployment_metadata
else
    IMAGE_TAG="latest"
fi

# Start containers with docker-compose
REGISTRY_URL=${ECR_REGISTRY} IMAGE_TAG=${IMAGE_TAG} docker-compose up -d

echo "ApplicationStart: Waiting for containers to be healthy..."
sleep 10

echo "ApplicationStart: Complete"
