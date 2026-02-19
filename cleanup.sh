#!/bin/bash
set -e

echo "🧹 Cleaning up TaskFlow Monitoring Resources"
echo "⚠️  Note: GuardDuty and CloudTrail will NOT be deleted"
echo ""

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

# Destroy Terraform resources (excludes GuardDuty and CloudTrail)
echo "🗑️  Destroying Terraform resources..."
echo "    - EC2 instances (Jenkins, App, Monitoring)"
echo "    - Security groups"
echo "    - IAM roles and policies"
echo "    - CloudWatch log groups"
echo "    - S3 bucket (CloudTrail logs)"
echo ""
echo "    ✓ Keeping: GuardDuty detector"
echo "    ✓ Keeping: CloudTrail trail"
echo ""

cd terraform
terraform destroy -auto-approve

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Resources preserved:"
echo "  - GuardDuty detector: 8eccab93586c4b21dc5166f92a396f54"
echo "  - CloudTrail trail: taskflow-trail"
echo ""
echo "To manually delete if needed:"
echo "  aws guardduty delete-detector --detector-id 8eccab93586c4b21dc5166f92a396f54 --region eu-west-1"
echo "  aws cloudtrail delete-trail --name taskflow-trail --region eu-west-1"
