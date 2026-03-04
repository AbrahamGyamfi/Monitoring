# CodeDeploy Integration Guide

## Overview
TaskFlow now uses AWS CodeDeploy for automated deployments instead of direct SSH. This provides:
- Blue/Green deployments with automatic rollback
- Centralized deployment management
- Audit trail of all deployments
- Health-based automatic rollback

## Architecture

```
Jenkins Pipeline
    ↓
Push to ECR
    ↓
CodeDeploy Create Deployment
    ↓
CodeDeploy Agent (on EC2)
    ↓
Execute appspec.yml hooks
    ↓
BeforeInstall → AfterInstall → ApplicationStart → ValidateService
```

## Deployment Lifecycle

### 1. BeforeInstall (before_install.sh)
- Stops existing Docker containers
- Cleans up old deployment files
- Prepares for new deployment

### 2. AfterInstall (after_install.sh)
- Authenticates with AWS ECR
- Pulls Docker images with specified tag
- Reads deployment metadata for image versions

### 3. ApplicationStart (application_start.sh)
- Starts Docker containers with docker-compose
- Sets environment variables (REGISTRY_URL, IMAGE_TAG)
- Waits for containers to initialize

### 4. ValidateService (validate_service.sh)
- Checks if containers are running
- Validates backend health endpoint
- Retries up to 12 times (60 seconds total)
- Fails deployment if health check fails

## Files Created

### appspec.yml
- Defines CodeDeploy deployment configuration
- Maps lifecycle hooks to shell scripts
- Specifies file locations and permissions

### scripts/
- `before_install.sh` - Pre-deployment cleanup
- `after_install.sh` - Image pulling and authentication
- `application_start.sh` - Container startup
- `validate_service.sh` - Health validation

## Terraform Modules

### codedeploy/main.tf
- Creates CodeDeploy application
- Creates deployment group with Blue/Green settings
- Creates IAM roles for CodeDeploy and EC2
- Configures auto-rollback on failure

## Jenkins Pipeline Changes

**Old (SSH-based):**
```groovy
sshagent(credentials: ["${EC2_CREDENTIALS_ID}"]) {
    ssh ec2-user@${EC2_HOST} 'docker-compose up -d'
}
```

**New (CodeDeploy-based):**
```groovy
aws deploy create-deployment \
    --application-name taskflow-app \
    --deployment-group-name taskflow-blue-green \
    --github-location repository=OWNER/REPO,commitSha=${GIT_COMMIT}
```

## Deployment Flow

1. **Jenkins builds images** and pushes to ECR
2. **Jenkins creates CodeDeploy deployment** with GitHub source
3. **CodeDeploy agent** on EC2 pulls code from GitHub
4. **CodeDeploy executes appspec.yml** hooks in order
5. **Jenkins polls deployment status** until completion
6. **Pipeline succeeds/fails** based on deployment result

## Prerequisites

### EC2 Instance Requirements
- CodeDeploy agent installed and running
- IAM instance profile with CodeDeploy permissions
- Docker and Docker Compose installed
- AWS CLI configured

### AWS Setup
- CodeDeploy application created
- Deployment group configured
- GitHub repository connected
- IAM roles with proper permissions

## Monitoring Deployments

### View deployment status:
```bash
aws deploy get-deployment \
    --deployment-id d-XXXXXXXXX \
    --query 'deploymentInfo.status'
```

### View deployment logs:
```bash
ssh ec2-user@APP_IP
tail -f /var/log/codedeploy-agent/codedeploy-agent.log
```

### View lifecycle hook output:
```bash
cat /opt/codedeploy-agent/deployment-root/*/logs/scripts.log
```

## Rollback Strategy

CodeDeploy automatically rolls back on:
- Deployment failure
- Health check timeout
- Script execution error

Manual rollback:
```bash
aws deploy stop-deployment --deployment-id d-XXXXXXXXX
```

## Environment Variables

Deployment metadata passed via `.deployment_metadata` file:
```bash
IMAGE_TAG=123
ECR_REGISTRY=123456789.dkr.ecr.eu-west-1.amazonaws.com
```

Scripts source this file to get deployment-specific values.

## Troubleshooting

### CodeDeploy agent not running
```bash
sudo systemctl status codedeploy-agent
sudo systemctl start codedeploy-agent
```

### Deployment stuck
- Check EC2 instance has internet access
- Verify IAM instance profile permissions
- Check CodeDeploy agent logs

### Health check failing
- Verify backend is accessible on port 5000
- Check Docker container logs
- Ensure docker-compose.yml is correct
