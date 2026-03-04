# TaskFlow - Project Structure

## Directory Organization

```
monitoring/
├── backend/                   # Node.js Express API server
├── frontend/                  # React 18 web application
├── terraform/                 # Infrastructure as Code
├── monitoring/                # Observability stack configuration
├── jenkins/                   # Jenkins Configuration as Code
├── userdata/                  # EC2 initialization scripts
├── Screenshots/               # Documentation images
├── Jenkinsfile               # CI/CD pipeline definition
├── docker-compose.prod.yml   # Production deployment config
├── deploy-and-verify.sh      # Deployment automation script
├── cleanup.sh                # Infrastructure teardown script
├── README.md                 # Comprehensive documentation
└── PROJECT_REPORT.md         # Implementation report
```

## Core Components

### Backend (`/backend`)
**Purpose**: RESTful API server with Prometheus metrics integration

**Key Files**:
- `server.js` - Basic Express server with task management endpoints
- `server-metrics.js` - Enhanced server with Prometheus metrics collection
- `server.test.js` - Jest unit tests (16 test cases)
- `Dockerfile` - Multi-stage build for production container
- `package.json` - Dependencies: express, cors, uuid, jest, supertest

**API Endpoints**:
- `GET /health` - Health check endpoint
- `GET /metrics` - Prometheus metrics endpoint
- `GET /api/tasks` - List all tasks
- `POST /api/tasks` - Create new task
- `PATCH /api/tasks/:id` - Update task status
- `PUT /api/tasks/:id` - Edit task details
- `DELETE /api/tasks/:id` - Delete task

**Metrics Exposed**:
- `http_requests_total` - Total HTTP requests counter
- `http_errors_total` - Total HTTP errors counter
- `http_request_duration_ms` - Average response time gauge
- `http_error_rate_percent` - Real-time error rate gauge
- `tasks_total` - Total tasks in system gauge

### Frontend (`/frontend`)
**Purpose**: React-based user interface for task management

**Structure**:
```
frontend/
├── public/
│   └── index.html            # HTML template
├── src/
│   ├── components/           # React components
│   │   ├── TaskForm.js       # Task creation form
│   │   ├── TaskItem.js       # Individual task display
│   │   └── TaskList.js       # Task list container
│   ├── App.js                # Main application component
│   ├── App.css               # Application styles
│   ├── App.test.js           # React component tests (8 tests)
│   ├── index.js              # React entry point
│   ├── index.css             # Global styles
│   └── setupTests.js         # Testing configuration
├── Dockerfile                # Multi-stage build with nginx
├── nginx.conf                # Nginx reverse proxy config
└── package.json              # Dependencies: react 18, testing-library
```

### Terraform Infrastructure (`/terraform`)
**Purpose**: Modular Infrastructure as Code for AWS resources

**Root Module**:
- `main.tf` - Module composition and resource orchestration
- `variables.tf` - Input variables (region, instance types, SSH keys)
- `outputs.tf` - Output values (IPs, URLs, resource IDs)
- `terraform.tfvars.example` - Example variable values

**Modules** (`/terraform/modules`):

1. **networking** - Security groups and SSH key management
   - Security group with ports: 22, 80, 5000, 8080, 9090, 9100, 3000
   - SSH key pair registration

2. **compute** - EC2 instance provisioning
   - Jenkins server (t3.micro)
   - Application server (t3.micro)
   - Monitoring server (t3.small)
   - User data script execution

3. **deployment** - Application deployment automation
   - Docker and Docker Compose installation
   - Application code deployment via provisioners
   - Service startup and health checks

4. **monitoring** - Observability stack setup
   - Prometheus configuration and deployment
   - Grafana installation with datasources
   - Node Exporter setup
   - Alert rules configuration

5. **security** - AWS security services integration
   - CloudWatch log groups and IAM roles
   - S3 bucket for CloudTrail logs (encrypted, lifecycle policy)
   - CloudTrail trail configuration (imported existing)
   - GuardDuty detector (imported existing)

### Monitoring Stack (`/monitoring`)
**Purpose**: Prometheus and Grafana observability configuration

**Configuration Files** (`/monitoring/config`):
- `prometheus.yml` - Prometheus scrape configuration (3 targets: backend, node-exporter, prometheus)
- `alert_rules.yml` - Alert definitions (HighErrorRate, HighLatency, ServiceDown)
- `grafana-datasource.yml` - Grafana Prometheus datasource configuration
- `grafana-dashboard-infrastructure.json` - System metrics dashboard
- `grafana-dashboard-Infra_&_App.json` - Combined infrastructure and application dashboard

**Deployment**:
- `docker-compose.yml` - Prometheus, Grafana, and Node Exporter containers

### User Data Scripts (`/userdata`)
**Purpose**: EC2 instance initialization and configuration

- `jenkins-userdata.sh` - Jenkins installation with Configuration as Code (JCasC)
  - Plugin installation (configuration-as-code, credentials, git, docker-workflow, etc.)
  - Automated admin user creation
  - AWS credentials configuration
  - Systemd service setup

- `app-userdata.sh` - Application server setup
  - Docker and Docker Compose installation
  - AWS CLI configuration
  - CloudWatch Logs agent setup
  - IAM role attachment for log streaming

- `monitoring-userdata.sh` - Monitoring server initialization
  - Docker installation
  - Prometheus and Grafana deployment
  - Node Exporter setup
  - Alert configuration

### CI/CD Pipeline (`/Jenkinsfile`)
**Purpose**: Automated build, test, and deployment pipeline

**8 Pipeline Stages**:
1. **Checkout** - Clone repository and extract git metadata
2. **Build Docker Images** - Parallel build of backend and frontend containers
3. **Run Unit Tests** - Parallel execution of backend (16 tests) and frontend (8 tests)
4. **Code Quality** - ESLint linting and Docker image verification
5. **Integration Tests** - API endpoint testing with temporary containers
6. **Push to ECR** - Upload versioned images to AWS ECR
7. **Deploy to EC2** - SSH deployment with docker-compose
8. **Health Check** - Verify application health endpoint

**Features**:
- Parallel execution for faster builds
- Containerized testing (no host dependencies)
- Automated ECR authentication
- SSH-based deployment with health verification
- Automatic cleanup of Docker resources

## Architectural Patterns

### Multi-Tier Architecture
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Jenkins Server │     │   App Server     │     │ Monitoring      │
│  - CI/CD        │────▶│  - Backend API   │◀────│  - Prometheus   │
│  - Pipeline     │     │  - Frontend UI   │     │  - Grafana      │
│  - Testing      │     │  - Node Exporter │     │  - Alerts       │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │  AWS Services   │
                        │  - CloudWatch   │
                        │  - CloudTrail   │
                        │  - GuardDuty    │
                        │  - ECR          │
                        │  - S3           │
                        └─────────────────┘
```

### Containerization Strategy
- **Multi-stage Docker builds**: Separate build and runtime stages for smaller images
- **Alpine base images**: Minimal footprint (node:18-alpine, nginx:alpine)
- **Layer optimization**: Strategic COPY ordering for cache efficiency
- **Production configuration**: Environment-specific docker-compose files

### Observability Pattern
- **Metrics Collection**: Prometheus pull-based scraping (15s intervals)
- **Visualization**: Grafana dashboards with 16 panels
- **Alerting**: Prometheus Alertmanager with configurable thresholds
- **Logging**: CloudWatch Logs with structured log streams
- **Audit Trail**: CloudTrail for API call tracking

### Security Layers
1. **Network**: Security groups with minimal port exposure
2. **Access**: IAM roles with least-privilege policies
3. **Logging**: CloudWatch Logs with 7-day retention
4. **Audit**: CloudTrail with encrypted S3 storage
5. **Threat Detection**: GuardDuty monitoring VPC, DNS, and CloudTrail

## Component Relationships

### Data Flow
1. User interacts with React frontend (port 80)
2. Frontend makes API calls to backend (port 5000)
3. Backend processes requests and updates in-memory task store
4. Backend exposes metrics at `/metrics` endpoint
5. Prometheus scrapes metrics every 15 seconds
6. Grafana queries Prometheus for visualization
7. Alert Manager evaluates rules and triggers alerts
8. CloudWatch Logs agent streams container logs to AWS

### Deployment Flow
1. Developer pushes code to GitHub
2. Jenkins webhook triggers pipeline
3. Pipeline builds Docker images
4. Tests run in isolated containers
5. Images pushed to AWS ECR with version tags
6. SSH deployment to EC2 with docker-compose
7. Health checks verify successful deployment
8. Monitoring automatically picks up new containers

## Configuration Management
- **Terraform**: Infrastructure state management with remote backend support
- **Jenkins CasC**: Declarative Jenkins configuration in YAML
- **Docker Compose**: Service orchestration with environment variables
- **Environment Variables**: Externalized configuration for different environments
