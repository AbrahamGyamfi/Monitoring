#!/bin/bash
set -e

echo "ValidateService: Checking application health..."
cd /home/ec2-user/taskflow

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "ERROR: Containers are not running"
    exit 1
fi

# Check backend health endpoint
MAX_RETRIES=12
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "ValidateService: Backend is healthy"
        exit 0
    fi
    echo "Waiting for backend to be ready... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo "ERROR: Backend health check failed"
exit 1
