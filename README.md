# TaskFlow - Task Management with Complete Observability & Security Stack

[![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)](https://www.terraform.io/)
[![Jenkins](https://img.shields.io/badge/CI%2FCD-Jenkins-red)](https://jenkins.io/)
[![Docker](https://img.shields.io/badge/Container-Docker-blue)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-orange)](https://aws.amazon.com/)
[![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-orange)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Visualization-Grafana-yellow)](https://grafana.com/)

A production-ready task management application with complete observability, monitoring, and security implementation using modern DevOps practices.

## Project Overview

TaskFlow demonstrates enterprise-grade DevOps practices including:

- **Infrastructure as Code**: Modular Terraform for AWS provisioning
- **CI/CD Pipeline**: Jenkins with containerized testing and ECR deployment
- **Observability Stack**: Prometheus + Grafana + CloudWatch monitoring
- **Security**: CloudTrail audit logging + GuardDuty threat detection
- **Containerization**: Multi-stage Docker builds with health checks
- **Metrics Exposure**: Prometheus-format metrics at `/metrics` endpoint

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Jenkins Server │     │   App Server     │     │ Monitoring      │
│  - CI/CD        │────▶│  - TaskFlow App  │◀────│  - Prometheus   │
│  - Pipeline     │     │  - Node Exporter │     │  - Grafana      │
└─────────────────┘     └──────────────────┘     │  - Alerts       │
                               │                  └─────────────────┘
                               ▼
                        ┌─────────────────┐
                        │  AWS Services   │
                        │  - CloudWatch   │
                        │  - CloudTrail   │
                        │  - GuardDuty    │
                        │  - ECR          │
                        └─────────────────┘
```

## Technology Stack

### Application
- **Frontend**: React 18, CSS3
- **Backend**: Node.js, Express.js
- **Testing**: Jest, Supertest, React Testing Library

### Infrastructure & DevOps
- **IaC**: Terraform (modular architecture)
- **CI/CD**: Jenkins with declarative pipeline
- **Containers**: Docker, Docker Compose
- **Cloud**: AWS (EC2, ECR, S3, IAM)

### Observability & Security
- **Metrics**: Prometheus, Node Exporter
- **Visualization**: Grafana
- **Logging**: CloudWatch Logs
- **Audit**: CloudTrail
- **Threat Detection**: GuardDuty
- **Alerts**: Prometheus Alertmanager

## Quick Start

### Prerequisites
- Terraform >= 1.0
- AWS CLI configured
- SSH key pair (`~/.ssh/id_rsa.pub`)
- Docker & Docker Compose

### Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### Verify Deployment
```bash
./deploy-and-verify.sh
```

### Access Services
- **App**: http://APP_IP
- **Grafana**: http://MONITORING_IP:3000 (admin/admin)
- **Prometheus**: http://MONITORING_IP:9090
- **Jenkins**: http://JENKINS_IP:8080

## Terraform Infrastructure

### Modular Structure
```
terraform/
├── main.tf                    # Root module
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
└── modules/
    ├── networking/            # Security groups, SSH keys
    ├── compute/               # EC2 instances
    ├── deployment/            # App deployment provisioner
    ├── monitoring/            # Prometheus + Grafana
    └── security/              # CloudTrail, GuardDuty, IAM
```

### Resources Provisioned
- 3 EC2 instances (Jenkins, App, Monitoring)
- Security group with required ports
- IAM roles for CloudWatch
- S3 bucket for CloudTrail logs (encrypted, 90-day lifecycle)
- CloudWatch log groups
- Imported existing CloudTrail and GuardDuty

## Observability Stack

### Metrics Exposed
The backend exposes Prometheus metrics at `/metrics`:
- `http_requests_total` - Total HTTP requests
- `http_errors_total` - Total HTTP errors
- `http_request_duration_ms` - Average latency
- `http_error_rate_percent` - Error rate percentage
- `tasks_total` - Total tasks count

### Prometheus Scrape Targets
- **taskflow-backend**: `APP_IP:5000/metrics`
- **node-exporter**: `APP_IP:9100/metrics`
- **prometheus**: `localhost:9090`

### Alerts Configured
1. **HighErrorRate**: Triggers when error rate > 5% for 2 minutes
2. **HighLatency**: Triggers when latency > 1000ms for 5 minutes
3. **ServiceDown**: Triggers when backend unreachable for 1 minute

### Grafana Dashboards
Create dashboards with these queries:
```promql
# Request Rate
rate(http_requests_total[5m])

# Error Rate
http_error_rate_percent

# Latency
http_request_duration_ms

# System Metrics (from Node Exporter)
node_cpu_seconds_total
node_memory_MemAvailable_bytes
```

## Security Implementation

### CloudWatch Logs
- Docker containers stream logs to CloudWatch
- Log Group: `/aws/taskflow/docker`
- Retention: 7 days

### CloudTrail
- Tracks all AWS API calls
- S3 Bucket: `taskflow-cloudtrail-logs`
- Encryption: AES256
- Lifecycle: 90 days retention
- Multi-region trail enabled

### GuardDuty
- Threat detection enabled
- Monitors for suspicious activity
- Findings available in AWS Console

## CI/CD Pipeline

### Jenkins Pipeline Stages
1. **Checkout** - Clone from GitHub
2. **Build** - Docker images (parallel)
3. **Test** - Unit tests in containers
4. **Quality** - ESLint + image verification
5. **Integration** - API endpoint tests
6. **Push** - Upload to ECR
7. **Deploy** - SSH to EC2 with docker-compose
8. **Health Check** - Verify deployment

### Containerized Testing
All tests run inside Docker containers:
```bash
# Backend (16 tests)
docker run --rm -v $(pwd):/app -w /app node:18-alpine sh -c 'npm install && npm test'

# Frontend (8 tests)
docker run --rm -v $(pwd):/app -w /app node:18-alpine sh -c 'npm install --legacy-peer-deps && CI=true npm test'
```

## API Endpoints

### Application
- `POST /api/tasks` - Create task
- `GET /api/tasks` - List tasks
- `PATCH /api/tasks/:id` - Update status
- `PUT /api/tasks/:id` - Edit task
- `DELETE /api/tasks/:id` - Delete task

### Monitoring
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Verification

### Test Metrics Endpoint
```bash
curl http://APP_IP:5000/metrics
```

### Test Alerts
```bash
# Generate errors to trigger alert
for i in {1..100}; do curl http://APP_IP:5000/api/invalid; done
```

### Check CloudWatch Logs
```bash
aws logs tail /aws/taskflow/docker --follow
```

### Check CloudTrail
```bash
aws cloudtrail lookup-events --max-results 10
```

### Check GuardDuty
```bash
aws guardduty list-detectors
aws guardduty list-findings --detector-id DETECTOR_ID
```

## Cleanup

```bash
./cleanup.sh
# OR
cd terraform && terraform destroy
```

## Project Structure

```
monitoring/
├── terraform/                 # Infrastructure as Code
│   ├── modules/              # Modular Terraform
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── backend/                   # Node.js API
│   ├── server.js
│   ├── server-metrics.js     # With Prometheus metrics
│   └── Dockerfile
├── frontend/                  # React UI
│   ├── src/
│   └── Dockerfile
├── monitoring/                # Observability stack
│   ├── config/
│   │   ├── prometheus.yml
│   │   ├── alert_rules.yml
│   │   └── grafana-datasource.yml
│   └── docker-compose.yml
├── userdata/                  # EC2 initialization scripts
│   ├── jenkins-userdata.sh
│   ├── app-userdata.sh
│   └── monitoring-userdata.sh
├── Jenkinsfile               # CI/CD pipeline
├── docker-compose.prod.yml   # Production deployment
└── README.md
```

## Cost Estimate

Monthly AWS costs (approximate):
- EC2 t3.micro (App): ~$7
- EC2 t3.micro (Jenkins): ~$7
- EC2 t3.small (Monitoring): ~$15
- CloudWatch Logs: ~$2
- CloudTrail: ~$2
- GuardDuty: ~$5
- S3 Storage: ~$1
- **Total**: ~$39/month

## Learning Outcomes

This project demonstrates:
1. Infrastructure as Code with Terraform modules
2. Complete observability stack implementation
3. Security best practices (CloudTrail, GuardDuty, encryption)
4. Prometheus metrics exposure and scraping
5. Grafana dashboard creation
6. Alert configuration and management
7. CloudWatch integration
8. CI/CD with containerized testing
9. Multi-tier application deployment
10. AWS service integration

## Default Credentials

- **Grafana**: admin/admin (change on first login)
- **Jenkins**: Get initial password via SSH:
  ```bash
  ssh -i ~/.ssh/id_rsa ec2-user@JENKINS_IP
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```

## Troubleshooting

### Prometheus Not Scraping
```bash
# Check connectivity from monitoring server
ssh -i ~/.ssh/id_rsa ec2-user@MONITORING_IP
curl http://APP_IP:5000/metrics
```

### App Not Running
```bash
# Check containers on app server
ssh -i ~/.ssh/id_rsa ec2-user@APP_IP
docker ps
docker logs taskflow-backend-prod
```

### CloudWatch Logs Missing
```bash
# Verify IAM role attached
aws ec2 describe-instances --instance-ids INSTANCE_ID \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

## License

MIT License - Educational project

---

**Author**: Abraham Gyamfi  
**Date**: February 2026  
**Version**: 2.0.0 (with Observability & Security)
