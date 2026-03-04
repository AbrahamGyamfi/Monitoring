#!/bin/bash
set -e

echo "ValidateService: Checking application health..."
cd /home/ec2-user/taskflow

# Show container status
echo "Container status:"
docker ps -a

# Check if containers are running
if [ -f docker-compose.prod.yml ]; then
    COMPOSE_STATUS=$(docker-compose -f docker-compose.prod.yml ps 2>/dev/null || echo "")
else
    COMPOSE_STATUS=$(docker-compose ps 2>/dev/null || echo "")
fi

echo "Compose status: $COMPOSE_STATUS"

# Check backend health endpoint
MAX_RETRIES=24
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -sf http://localhost:5000/health > /dev/null 2>&1; then
        echo "ValidateService: Backend is healthy!"
        
        # Also check frontend
        if curl -sf http://localhost:80/ > /dev/null 2>&1; then
            echo "ValidateService: Frontend is healthy!"
        else
            echo "Warning: Frontend not responding on port 80"
        fi
        
        exit 0
    fi
    echo "Waiting for backend to be ready... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo "ERROR: Backend health check failed after $MAX_RETRIES attempts"
echo "Container logs:"
docker logs taskflow-backend-prod 2>&1 | tail -50 || true
exit 1
