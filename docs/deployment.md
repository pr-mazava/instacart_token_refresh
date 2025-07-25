# Deployment Guide

## Production Deployment Options

This guide covers various deployment strategies for the Instacart Token Refresh Utility in production environments.

---

## Table of Contents

- [Local Deployment](#local-deployment)
- [Docker Deployment](#docker-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [AWS Deployment](#aws-deployment)
- [Google Cloud Deployment](#google-cloud-deployment)
- [Azure Deployment](#azure-deployment)
- [CI/CD Integration](#cicd-integration)
- [Security Considerations](#security-considerations)
- [Monitoring & Logging](#monitoring--logging)

---

## Local Deployment

### Basic Setup

```bash
# Clone repository
git clone <repository-url>
cd instacart-token-refresh

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Run the utility
python instacart_refresh_token.py
```

### Scheduled Execution

#### Using Cron (Linux/macOS)

```bash
# Edit crontab
crontab -e

# Add weekly execution (Sundays at 2 AM)
0 2 * * 0 /path/to/venv/bin/python /path/to/instacart_refresh_token.py

# Add with logging
0 2 * * 0 /path/to/venv/bin/python /path/to/instacart_refresh_token.py >> /var/log/instacart_tokens.log 2>&1
```

#### Using Windows Task Scheduler

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (weekly)
4. Set action: Start a program
5. Program: `C:\path\to\python.exe`
6. Arguments: `C:\path\to\instacart_refresh_token.py`
7. Start in: `C:\path\to\project\directory`

---

## Docker Deployment

### Basic Dockerfile

```dockerfile
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1001 tokenuser && \
    chown -R tokenuser:tokenuser /app
USER tokenuser

# Run the application
CMD ["python", "instacart_refresh_token.py"]
```

### Build and Run

```bash
# Build image
docker build -t instacart-token-refresh .

# Run with environment file
docker run --env-file .env instacart-token-refresh

# Run with mounted volume for output
docker run --env-file .env -v $(pwd)/output:/app/output instacart-token-refresh
```

### Docker Compose

```yaml
version: '3.8'

services:
  token-refresh:
    build: .
    env_file: .env
    volumes:
      - ./output:/app/output
      - ./logs:/app/logs
    restart: unless-stopped
    
  # Optional: Run on schedule
  token-refresh-cron:
    build: .
    env_file: .env
    volumes:
      - ./output:/app/output
      - ./logs:/app/logs
    command: >
      sh -c "
        echo '0 2 * * 0 python /app/instacart_refresh_token.py' | crontab - &&
        crond -f
      "
    restart: unless-stopped
```

---

## Kubernetes Deployment

### ConfigMap for Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: instacart-config
data:
  CLIENTS: "CLIENT1,CLIENT2,BRANDX"
  # Add non-sensitive configuration
```

### Secret for Credentials

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: instacart-secrets
type: Opaque
data:
  CLIENT1_CLIENT_ID: <base64-encoded-value>
  CLIENT1_CLIENT_SECRET: <base64-encoded-value>
  CLIENT1_REFRESH_TOKEN: <base64-encoded-value>
  # Add other client credentials
```

### CronJob Deployment

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: instacart-token-refresh
spec:
  schedule: "0 2 * * 0"  # Weekly on Sunday at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: token-refresh
            image: your-registry/instacart-token-refresh:latest
            envFrom:
            - configMapRef:
                name: instacart-config
            - secretRef:
                name: instacart-secrets
            volumeMounts:
            - name: token-storage
              mountPath: /app/output
            resources:
              requests:
                memory: "128Mi"
                cpu: "100m"
              limits:
                memory: "256Mi"
                cpu: "200m"
          volumes:
          - name: token-storage
            persistentVolumeClaim:
              claimName: token-storage-pvc
          restartPolicy: OnFailure
```

### Persistent Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: token-storage-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

---

## AWS Deployment

### Lambda Function

```python
# lambda_function.py
import json
import boto3
import os
from instacart_refresh_token import main

def lambda_handler(event, context):
    # Get credentials from Secrets Manager
    secrets_client = boto3.client('secretsmanager')
    
    try:
        secret_value = secrets_client.get_secret_value(
            SecretId='instacart-api-credentials'
        )
        
        credentials = json.loads(secret_value['SecretString'])
        
        # Set environment variables
        for key, value in credentials.items():
            os.environ[key] = value
        
        # Run token refresh
        main()
        
        # Store tokens in S3
        s3_client = boto3.client('s3')
        # Upload token files...
        
        return {
            'statusCode': 200,
            'body': json.dumps('Token refresh completed')
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
```

### CloudFormation Template

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Instacart Token Refresh Lambda'

Resources:
  InstacartTokenRefreshRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: SecretsManagerAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - secretsmanager:GetSecretValue
                Resource: !Ref InstacartCredentials
        - PolicyName: S3Access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:PutObject
                  - s3:GetObject
                Resource: !Sub "${TokenBucket}/*"

  InstacartTokenRefreshFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: instacart-token-refresh
      Runtime: python3.9
      Handler: lambda_function.lambda_handler
      Code:
        ZipFile: |
          # Lambda function code here
      Role: !GetAtt InstacartTokenRefreshRole.Arn
      Timeout: 300
      MemorySize: 256

  TokenRefreshSchedule:
    Type: AWS::Events::Rule
    Properties:
      Description: "Weekly token refresh"
      ScheduleExpression: "cron(0 2 ? * SUN *)"
      State: ENABLED
      Targets:
        - Arn: !GetAtt InstacartTokenRefreshFunction.Arn
          Id: "TokenRefreshTarget"

  InstacartCredentials:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: instacart-api-credentials
      Description: "Instacart API credentials"
      SecretString: !Sub |
        {
          "CLIENTS": "CLIENT1,CLIENT2",
          "CLIENT1_CLIENT_ID": "your_client1_id",
          "CLIENT1_CLIENT_SECRET": "your_client1_secret",
          "CLIENT1_REFRESH_TOKEN": "your_client1_token"
        }

  TokenBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "instacart-tokens-${AWS::AccountId}"
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
```

### ECS Fargate Deployment

```yaml
# task-definition.json
{
  "family": "instacart-token-refresh",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::account:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "token-refresh",
      "image": "your-account.dkr.ecr.region.amazonaws.com/instacart-token-refresh:latest",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/instacart-token-refresh",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "secrets": [
        {
          "name": "CLIENTS",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:instacart-credentials:CLIENTS::"
        }
      ]
    }
  ]
}
```

---

## Google Cloud Deployment

### Cloud Functions

```python
# main.py
import functions_framework
from google.cloud import secretmanager
import os
import json
from instacart_refresh_token import main

@functions_framework.http
def token_refresh(request):
    try:
        # Get credentials from Secret Manager
        client = secretmanager.SecretManagerServiceClient()
        name = "projects/your-project/secrets/instacart-credentials/versions/latest"
        
        response = client.access_secret_version(request={"name": name})
        credentials = json.loads(response.payload.data.decode("UTF-8"))
        
        # Set environment variables
        for key, value in credentials.items():
            os.environ[key] = value
        
        # Run token refresh
        main()
        
        return {'status': 'success', 'message': 'Tokens refreshed'}
        
    except Exception as e:
        return {'status': 'error', 'message': str(e)}, 500
```

### Cloud Scheduler

```bash
# Create scheduled job
gcloud scheduler jobs create http instacart-token-refresh \
  --schedule="0 2 * * 0" \
  --uri="https://region-project.cloudfunctions.net/token_refresh" \
  --http-method=POST \
  --time-zone="UTC"
```

### Cloud Run

```yaml
# service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: instacart-token-refresh
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/maxScale: "1"
    spec:
      containers:
      - image: gcr.io/your-project/instacart-token-refresh
        env:
        - name: GOOGLE_CLOUD_PROJECT
          value: "your-project"
        resources:
          limits:
            memory: "512Mi"
            cpu: "1000m"
```

---

## Azure Deployment

### Azure Functions

```python
# function_app.py
import azure.functions as func
import logging
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential
import os
import json
from instacart_refresh_token import main

app = func.FunctionApp()

@app.timer_trigger(schedule="0 2 * * 0", arg_name="myTimer", run_on_startup=False)
def token_refresh_timer(myTimer: func.TimerRequest) -> None:
    try:
        # Get credentials from Key Vault
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url="https://your-vault.vault.azure.net/", credential=credential)
        
        credentials_secret = client.get_secret("instacart-credentials")
        credentials = json.loads(credentials_secret.value)
        
        # Set environment variables
        for key, value in credentials.items():
            os.environ[key] = value
        
        # Run token refresh
        main()
        
        logging.info("Token refresh completed successfully")
        
    except Exception as e:
        logging.error(f"Token refresh failed: {e}")
        raise
```

### Container Instances

```yaml
# container-group.yaml
apiVersion: 2019-12-01
location: eastus
name: instacart-token-refresh
properties:
  containers:
  - name: token-refresh
    properties:
      image: your-registry.azurecr.io/instacart-token-refresh:latest
      resources:
        requests:
          cpu: 0.5
          memoryInGb: 1
      environmentVariables:
      - name: AZURE_KEY_VAULT_URL
        value: https://your-vault.vault.azure.net/
  osType: Linux
  restartPolicy: Never
type: Microsoft.ContainerInstance/containerGroups
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy Instacart Token Refresh

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * 0'  # Weekly deployment

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
    
    - name: Run token refresh
      env:
        CLIENTS: ${{ secrets.CLIENTS }}
        CLIENT1_CLIENT_ID: ${{ secrets.CLIENT1_CLIENT_ID }}
        CLIENT1_CLIENT_SECRET: ${{ secrets.CLIENT1_CLIENT_SECRET }}
        CLIENT1_REFRESH_TOKEN: ${{ secrets.CLIENT1_REFRESH_TOKEN }}
      run: |
        python instacart_refresh_token.py
    
    - name: Upload tokens to S3
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      run: |
        aws s3 cp *.txt s3://your-token-bucket/tokens/
```

### GitLab CI

```yaml
stages:
  - deploy

token_refresh:
  stage: deploy
  image: python:3.9
  
  before_script:
    - pip install -r requirements.txt
  
  script:
    - python instacart_refresh_token.py
    - aws s3 cp *.txt s3://your-token-bucket/tokens/
  
  variables:
    CLIENTS: $CLIENT_LIST
    CLIENT1_CLIENT_ID: $CLIENT1_ID
    CLIENT1_CLIENT_SECRET: $CLIENT1_SECRET
    CLIENT1_REFRESH_TOKEN: $CLIENT1_TOKEN
  
  only:
    - schedules
    - main
```

### Azure DevOps

```yaml
trigger:
- main

schedules:
- cron: "0 2 * * 0"
  displayName: Weekly token refresh
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.9'
    
- script: |
    pip install -r requirements.txt
  displayName: 'Install dependencies'
  
- script: |
    python instacart_refresh_token.py
  displayName: 'Refresh tokens'
  env:
    CLIENTS: $(CLIENTS)
    CLIENT1_CLIENT_ID: $(CLIENT1_CLIENT_ID)
    CLIENT1_CLIENT_SECRET: $(CLIENT1_CLIENT_SECRET)
    CLIENT1_REFRESH_TOKEN: $(CLIENT1_REFRESH_TOKEN)
```

---

## Security Considerations

### Credential Management

```bash
# Use dedicated secret management services
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name instacart-api-credentials \
  --secret-string file://credentials.json

# Azure Key Vault
az keyvault secret set \
  --vault-name your-vault \
  --name instacart-credentials \
  --file credentials.json

# Google Secret Manager
gcloud secrets create instacart-credentials \
  --data-file=credentials.json
```

### Network Security

```yaml
# Example: VPC configuration for ECS
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      
  PrivateSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Instacart token refresh security group
      VpcId: !Ref VPC
      SecurityGroupEgress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
```

### IAM Policies

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:region:account:secret:instacart-credentials*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::token-bucket/tokens/*"
    }
  ]
}
```

---

## Monitoring & Logging

### CloudWatch Monitoring

```python
import boto3
import json

def lambda_handler(event, context):
    cloudwatch = boto3.client('cloudwatch')
    
    try:
        # Your token refresh logic
        main()
        
        # Send success metric
        cloudwatch.put_metric_data(
            Namespace='InstacartTokenRefresh',
            MetricData=[
                {
                    'MetricName': 'TokenRefreshSuccess',
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )
        
    except Exception as e:
        # Send failure metric
        cloudwatch.put_metric_data(
            Namespace='InstacartTokenRefresh',
            MetricData=[
                {
                    'MetricName': 'TokenRefreshFailure',
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )
        raise
```

### Prometheus Metrics

```python
from prometheus_client import Counter, Histogram, start_http_server
import time

# Metrics
REQUEST_COUNT = Counter('instacart_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('instacart_request_duration_seconds', 'Request duration')

@REQUEST_DURATION.time()
def refresh_tokens():
    start_time = time.time()
    try:
        # Token refresh logic
        main()
        REQUEST_COUNT.labels(method='POST', endpoint='oauth').inc()
    except Exception as e:
        REQUEST_COUNT.labels(method='POST', endpoint='oauth').inc()
        raise
```

### Structured Logging

```python
import structlog
import sys

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

def main():
    logger.info("Starting token refresh", client_count=len(clients))
    
    for client in clients:
        try:
            refresh_client_token(client)
            logger.info("Token refreshed successfully", client=client.name)
        except Exception as e:
            logger.error("Token refresh failed", client=client.name, error=str(e))
```

---

## Performance Optimization

### Connection Pooling

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

def create_session():
    session = requests.Session()
    
    # Configure retry strategy
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504]
    )
    
    # Configure adapter with connection pooling
    adapter = HTTPAdapter(
        pool_connections=10,
        pool_maxsize=20,
        max_retries=retry_strategy
    )
    
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    
    return session
```

### Async Processing

```python
import asyncio
import aiohttp

async def refresh_client_tokens(clients):
    async with aiohttp.ClientSession() as session:
        tasks = []
        
        for client in clients:
            task = refresh_single_client(session, client)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for client, result in zip(clients, results):
            if isinstance(result, Exception):
                logger.error(f"Failed to refresh {client.name}: {result}")
            else:
                logger.info(f"Successfully refreshed {client.name}")

async def refresh_single_client(session, client):
    # Async token refresh logic
    pass
```

---

For additional deployment support and questions, contact: paul@mazavaltd.com

*#AnalyzeResponsibly*