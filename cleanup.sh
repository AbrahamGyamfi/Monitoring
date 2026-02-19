#!/bin/bash
set -e

echo "🧹 Cleaning up TaskFlow Monitoring Resources"

# Stop monitoring containers
MONITORING_IP=$(cd terraform && terraform output -raw monitoring_public_ip 2>/dev/null || echo "")

if [ -n "$MONITORING_IP" ]; then
    echo "🛑 Stopping monitoring containers..."
    ssh -i taskflow-key.pem ec2-user@$MONITORING_IP << 'EOF'
cd ~/monitoring
docker-compose down -v
docker system prune -af
EOF
fi

# Destroy Terraform resources
echo "🗑️  Destroying Terraform resources..."
cd terraform
terraform destroy -auto-approve

echo "✅ Cleanup complete!"
