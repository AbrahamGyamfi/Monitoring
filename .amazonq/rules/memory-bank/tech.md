# TaskFlow - Technology Stack

## Programming Languages

### JavaScript/Node.js
- **Version**: Node.js 18 (LTS)
- **Runtime**: V8 JavaScript engine
- **Usage**: Backend API server and frontend React application

### Shell Script
- **Version**: Bash 4+
- **Usage**: User data scripts, deployment automation, cleanup scripts

### HCL (HashiCorp Configuration Language)
- **Version**: Terraform 1.0+
- **Usage**: Infrastructure as Code definitions

## Backend Technologies

### Core Framework
- **express** ^4.18.2 - Fast, minimalist web framework for Node.js
- **cors** ^2.8.5 - Cross-Origin Resource Sharing middleware
- **uuid** ^9.0.0 - RFC4122 UUID generation

### Testing
- **jest** ^29.5.0 - JavaScript testing framework with coverage
- **jest-junit** ^16.0.0 - JUnit XML reporter for CI/CD integration
- **supertest** ^6.3.3 - HTTP assertion library for API testing

### Development Tools
- **nodemon** ^2.0.22 - Auto-restart server on file changes
- **eslint** ^8.40.0 - JavaScript linting and code quality
- **prettier** ^2.8.8 - Code formatting

### Metrics & Monitoring
- **Custom Prometheus Client**: In-memory metrics collection
  - Counter metrics for requests and errors
  - Gauge metrics for latency and error rates
  - Prometheus text format exposition

## Frontend Technologies

### Core Framework
- **react** ^18.2.0 - Component-based UI library
- **react-dom** ^18.2.0 - React rendering for web
- **react-scripts** 5.0.1 - Create React App build tooling

### Testing
- **@testing-library/react** ^13.4.0 - React component testing utilities
- **@testing-library/jest-dom** ^5.16.5 - Custom Jest matchers for DOM
- **@testing-library/user-event** ^14.4.3 - User interaction simulation

### Build System
- **Webpack** (via react-scripts) - Module bundler
- **Babel** (via react-scripts) - JavaScript transpiler
- **ESLint** (via react-scripts) - Linting with react-app config

## Infrastructure & DevOps

### Infrastructure as Code
- **Terraform** >= 1.0
  - Provider: AWS (~> 5.0)
  - State management: Local (supports remote backends)
  - Modules: 5 custom modules (networking, compute, deployment, monitoring, security)

### CI/CD
- **Jenkins** 2.x
  - Declarative pipeline syntax
  - Plugins: configuration-as-code, credentials-binding, aws-credentials, git, github, workflow-aggregator, pipeline-stage-view, docker-workflow, ssh-agent, job-dsl, timestamper, ws-cleanup
  - Configuration as Code (JCasC) with YAML

### Containerization
- **Docker** 20+
  - Multi-stage builds
  - Alpine-based images (node:18-alpine, nginx:alpine)
  - BuildKit support
- **Docker Compose** 2.x
  - Service orchestration
  - Environment variable substitution
  - Health checks

### Container Registry
- **AWS ECR** (Elastic Container Registry)
  - Private Docker image repository
  - Image versioning with build numbers
  - Automated authentication via AWS CLI

## Monitoring & Observability

### Metrics Collection
- **Prometheus** 2.x
  - Pull-based metrics scraping
  - PromQL query language
  - Time-series database
  - Scrape interval: 15 seconds
  - Targets: backend (port 5000), node-exporter (port 9100), prometheus (port 9090)

### Visualization
- **Grafana** 9.x
  - Dashboard creation and management
  - Prometheus datasource integration
  - 16-panel dashboards (infrastructure + application)
  - Default credentials: admin/admin

### System Metrics
- **Node Exporter** 1.x
  - Hardware and OS metrics
  - CPU, memory, disk, network statistics
  - Prometheus-compatible exposition format

### Alerting
- **Prometheus Alertmanager**
  - Alert rule evaluation
  - Configured alerts:
    - HighErrorRate: >5% for 2 minutes (Critical)
    - HighLatency: >1000ms for 5 minutes (Warning)
    - ServiceDown: Backend unreachable for 1 minute (Critical)

## Cloud Services (AWS)

### Compute
- **EC2** (Elastic Compute Cloud)
  - Instance types: t3.micro (Jenkins, App), t3.small (Monitoring)
  - AMI: Amazon Linux 2
  - User data scripts for initialization

### Logging
- **CloudWatch Logs**
  - Log group: `/aws/taskflow/docker`
  - Retention: 7 days
  - Streams: taskflow-backend-prod, taskflow-frontend-prod
  - IAM role-based authentication

### Audit & Compliance
- **CloudTrail**
  - Multi-region trail
  - S3 bucket storage with encryption (AES256)
  - Lifecycle policy: 90-day retention
  - Events: EC2, S3, IAM, ECR API calls

### Security
- **GuardDuty**
  - Threat detection service
  - Coverage: VPC Flow Logs, CloudTrail events, DNS logs
  - Real-time findings and alerts

### Storage
- **S3** (Simple Storage Service)
  - CloudTrail log storage
  - Server-side encryption (AES256)
  - Lifecycle management

### Identity & Access
- **IAM** (Identity and Access Management)
  - EC2 instance roles
  - Policies for CloudWatch Logs access
  - Least-privilege access patterns

## Web Server

### Production Server
- **Nginx** (Alpine)
  - Static file serving for React frontend
  - Reverse proxy configuration
  - Port 80 HTTP serving

### Development Server
- **Express.js** built-in server (Backend)
- **Webpack Dev Server** via react-scripts (Frontend)

## Development Commands

### Backend
```bash
npm install              # Install dependencies
npm start               # Start production server (node server.js)
npm run dev             # Start development server (nodemon)
npm test                # Run Jest tests with coverage
npm run test:watch      # Run tests in watch mode
npm run lint            # Run ESLint
npm run format          # Run Prettier
```

### Frontend
```bash
npm install --legacy-peer-deps  # Install dependencies
npm start                       # Start development server (port 3000)
npm run build                   # Create production build
npm test                        # Run tests (CI mode)
npm run test:watch              # Run tests in watch mode
```

### Infrastructure
```bash
terraform init          # Initialize Terraform
terraform plan          # Preview infrastructure changes
terraform apply         # Apply infrastructure changes
terraform destroy       # Destroy infrastructure
terraform output        # Show output values
```

### Docker
```bash
docker build -t image:tag .                    # Build image
docker run -p 5000:5000 image:tag             # Run container
docker-compose up -d                           # Start services
docker-compose down                            # Stop services
docker-compose ps                              # List services
docker-compose logs -f service                 # View logs
```

### Deployment
```bash
./deploy-and-verify.sh  # Deploy and verify infrastructure
./cleanup.sh            # Destroy all resources
```

## Build Systems

### Backend Build
- **Docker multi-stage build**:
  1. Build stage: Install dependencies, copy source
  2. Production stage: Copy artifacts, set NODE_ENV=production
  - Base image: node:18-alpine
  - Exposed port: 5000
  - Health check: curl localhost:5000/health

### Frontend Build
- **Docker multi-stage build**:
  1. Build stage: npm install, npm run build (creates optimized bundle)
  2. Production stage: nginx serves static files
  - Base image: node:18-alpine (build), nginx:alpine (production)
  - Exposed port: 80
  - Nginx configuration: reverse proxy to backend

### CI/CD Build
- **Jenkins pipeline**:
  - Parallel builds for backend and frontend
  - Containerized testing (no host dependencies)
  - Image tagging: BUILD_NUMBER and latest
  - ECR push with AWS credentials
  - SSH deployment to EC2

## Dependencies Management

### Package Managers
- **npm** (Node Package Manager) - JavaScript dependencies
- **apt-get** / **yum** - System package management (Amazon Linux 2)

### Dependency Files
- `backend/package.json` - Backend dependencies
- `backend/package-lock.json` - Locked backend versions
- `frontend/package.json` - Frontend dependencies
- `frontend/package-lock.json` - Locked frontend versions
- `terraform/.terraform.lock.hcl` - Terraform provider versions

## Version Control
- **Git** - Source code management
- **GitHub** - Remote repository hosting
- Jenkins webhook integration for automated builds

## Testing Frameworks

### Backend Testing
- **Jest** - Test runner and assertion library
- **Supertest** - HTTP endpoint testing
- Coverage reporting with jest-junit XML output
- 16 test cases covering all API endpoints

### Frontend Testing
- **Jest** (via react-scripts) - Test runner
- **React Testing Library** - Component testing
- **jest-dom** - DOM-specific matchers
- **user-event** - User interaction simulation
- 8 test cases for component rendering

## Environment Configuration
- **Environment Variables**: Used for configuration (AWS region, credentials, IPs)
- **Terraform Variables**: Input variables for infrastructure customization
- **Docker Environment**: Runtime configuration via docker-compose
- **Jenkins Credentials**: Secure credential storage with JCasC
