#!/bin/bash
set -e

echo "ApplicationStart: Starting containers..."
cd /home/ec2-user/taskflow

# Load environment variables
if [ -f .env ]; then
    source .env
else
    export REGISTRY_URL="697863031884.dkr.ecr.eu-west-1.amazonaws.com"
    export IMAGE_TAG="latest"
fi

echo "ApplicationStart: Using REGISTRY_URL=${REGISTRY_URL}"
echo "ApplicationStart: Using IMAGE_TAG=${IMAGE_TAG}"

# Start containers with docker-compose.prod.yml
if [ -f docker-compose.prod.yml ]; then
    REGISTRY_URL=${REGISTRY_URL} IMAGE_TAG=${IMAGE_TAG} docker-compose -f docker-compose.prod.yml up -d
else
    echo "ERROR: docker-compose.prod.yml not found"
    ls -la
    exit 1
fi

echo "ApplicationStart: Waiting for containers to be healthy..."
sleep 15

# Show container status
docker ps

echo "ApplicationStart: Complete"
