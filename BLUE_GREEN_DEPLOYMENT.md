# Blue/Green Deployment with CodeDeploy

## Architecture

```
                    Load Balancer (ALB)
                           |
                    --------|--------
                   |                 |
              Blue Instance    Green Instance
              (Running v1)     (Deploying v2)
                   |                 |
              Port 80              Port 80
```

## Deployment Flow

1. **Initial State**: Both Blue and Green instances running same version
2. **Deploy**: CodeDeploy deploys to Green instance only
3. **Health Check**: Validates Green instance health
4. **Traffic Switch**: Load balancer routes traffic to Green
5. **Blue Becomes Standby**: Ready for next deployment

## Instances

| Instance | Role | Status |
|----------|------|--------|
| Blue | Current production | Running |
| Green | Next deployment target | Running |

## Load Balancer

- **Type**: Application Load Balancer (ALB)
- **Port**: 80 (HTTP)
- **Health Check**: `/health` endpoint every 30s
- **Target Group**: Both instances registered

## CodeDeploy Configuration

```hcl
deployment_style {
  deployment_type   = "BLUE_GREEN"
  deployment_option = "WITH_TRAFFIC_CONTROL"
}
```

- Automatically manages traffic switching
- Rollback on health check failure
- Zero-downtime deployments

## Deployment Process

1. Jenkins builds and pushes images to ECR
2. Jenkins triggers CodeDeploy deployment
3. CodeDeploy agent on Green instance:
   - Stops old containers
   - Pulls new images
   - Starts new containers
   - Validates health
4. Load balancer switches traffic to Green
5. Blue instance becomes standby

## Rollback

If Green instance fails health check:
- Traffic remains on Blue
- Green deployment marked as failed
- No manual intervention needed

## Accessing Instances

**Via Load Balancer (Recommended):**
```bash
curl http://<ALB_DNS_NAME>
```

**Direct Access:**
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<BLUE_IP>
ssh -i ~/.ssh/id_rsa ec2-user@<GREEN_IP>
```

## Monitoring

Check deployment status:
```bash
aws deploy get-deployment --deployment-id d-XXXXXXXXX
```

View target health:
```bash
aws elbv2 describe-target-health --target-group-arn <TG_ARN>
```
