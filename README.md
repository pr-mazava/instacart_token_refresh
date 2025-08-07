# Instacart API Token Refresh Utility

<p align="center">
  <img src="assets/images/mazava_blk.png" alt="Mazava Consulting" width="400"/>
</p>

<p align="center">
  <strong>Professional data solutions that actually work.</strong><br>
  #AnalyzeResponsibly
</p>

---

## Overview

The **Instacart Token Refresh Utility** is a production-grade script designed to simplify OAuth token management for the Instacart Ads API. This tool automates the process of converting authorization codes to refresh tokens, enabling seamless integration with any analytics platform, data warehouse, or custom application.

### Why This Tool Exists

Managing OAuth tokens for the Instacart Ads API can be complex, especially when working with multiple client accounts or building automated data pipelines. This utility streamlines the token generation process, making it easier to build robust integrations with any destination system.

### Key Features

- **Multi-Client Support** - Handle multiple Instacart client accounts simultaneously
- **Environment Variable Configuration** - Secure credential management via `.env` files
- **Automated Token Exchange** - Convert authorization codes to refresh tokens seamlessly
- **Dual Output Format** - Save tokens in both JSON (complete response) and TXT (token only) formats
- **Interactive Mode** - Prompts for missing credentials when not found in environment
- **Error Handling** - Comprehensive error reporting and validation
- **Platform Agnostic** - Use with any analytics platform or data integration tool

---

## Quick Start

### Prerequisites

```bash
pip install requests python-dotenv
```

### Basic Usage

1. **Clone and Setup**
```bash
gh repo clone pr-mazava/instacart_token_refresh
cd instacart-token-refresh
```

2. **Configure Environment Variables**
```bash
cp .env.example .env
# Edit .env with your client credentials
```

3. **Run the Script**
```bash
python instacart_refresh_token.py
```

---

## Configuration

### Environment Variables

Create a `.env` file in the project root with the following structure:

```bash
# Comma-separated list of your client names (use any names you prefer)
CLIENTS=CLIENT1,CLIENT2,BRANDX,BRANDY

# Client 1 Configuration
CLIENT1_CLIENT_ID=your_client1_client_id
CLIENT1_CLIENT_SECRET=your_client1_client_secret
CLIENT1_REDIRECT_URI=https://your-redirect-uri.com
CLIENT1_AUTH_CODE=your_authorization_code

# Client 2 Configuration  
CLIENT2_CLIENT_ID=your_client2_client_id
CLIENT2_CLIENT_SECRET=your_client2_client_secret
CLIENT2_REDIRECT_URI=https://your-redirect-uri.com
CLIENT2_AUTH_CODE=your_authorization_code

# Brand X Configuration
BRANDX_CLIENT_ID=your_brandx_client_id
BRANDX_CLIENT_SECRET=your_brandx_client_secret
BRANDX_REDIRECT_URI=https://your-redirect-uri.com
BRANDX_AUTH_CODE=your_authorization_code

# Brand Y Configuration
BRANDY_CLIENT_ID=your_brandy_client_id
BRANDY_CLIENT_SECRET=your_brandy_client_secret
BRANDY_REDIRECT_URI=https://your-redirect-uri.com
BRANDY_AUTH_CODE=your_authorization_code
```

### Required Variables Per Client

| Variable | Description | Example |
|----------|-------------|---------|
| `{CLIENT}_CLIENT_ID` | Instacart API Client ID | `CG4Peb1YDAQvnILXSFvGKeLJePudmhL...` |
| `{CLIENT}_CLIENT_SECRET` | Instacart API Client Secret | `f3czM4o5_N8Pxig5qhzD4JzOjW2svXa...` |
| `{CLIENT}_REDIRECT_URI` | OAuth redirect URI | `https://your-app.com/callback` |
| `{CLIENT}_AUTH_CODE` | Authorization code from OAuth flow | `abc123def456...` |

### Getting Your Instacart API Credentials

1. **Register Your Application** with Instacart Ads API
2. **Obtain Client ID and Secret** from your Instacart developer dashboard
3. **Set Up Redirect URI** (can be any valid URI you control)
4. **Generate Authorization Code** through Instacart's OAuth flow

---

## Usage Examples

### Example 1: Full Environment Configuration

```bash
# All credentials in .env file
python instacart_refresh_token.py
```

**Output:**
```
==== CLIENT1 ====
Requesting token for CLIENT1...
Result for CLIENT1 written to: client1_refresh_token_20250123_1430.json
Refresh token for CLIENT1 saved to: client1_refresh_token_20250123_1430.txt

CLIENT1 Success! Refresh token (also saved to file):
{
  "access_token": "...",
  "refresh_token": "nc42QIfvTNXhwcwZoU-FMO2PaTeriUJ_pGFHhjuQLv0",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### Example 2: Interactive Mode

```bash
# Missing credentials will prompt for input
python instacart_refresh_token.py
```

**Interactive Prompts:**
```
==== BRANDX ====
BRANDX Client ID: X0cQTq5vo-sOOUof8pqPjAF3w4r4CnS8Skg4a7WH3JI
BRANDX Client Secret: IPxzDLvO5kAIphmfulPj8u4LXpBWi4B4Ud1jHByf-yg
BRANDX Redirect URI: https://your-app.com/callback
BRANDX Auth Code: your_authorization_code_here
```

### Example 3: Single Client Setup

```bash
# Minimal setup for one client
CLIENTS=MYCLIENT
MYCLIENT_CLIENT_ID=your_client_id
MYCLIENT_CLIENT_SECRET=your_client_secret
MYCLIENT_REDIRECT_URI=https://your-app.com/callback
MYCLIENT_AUTH_CODE=your_auth_code
```

---

## Output Files

The script generates timestamped files for each client:

### JSON Format (Complete Response)
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "nc42QIfvTNXhwcwZoU-FMO2PaTeriUJ_pGFHhjuQLv0",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "ads:read"
}
```

### TXT Format (Token Only)
```
nc42QIfvTNXhwcwZoU-FMO2PaTeriUJ_pGFHhjuQLv0
```

### File Naming Convention
```
{client_name}_refresh_token_{timestamp}.json
{client_name}_refresh_token_{timestamp}.txt
```

**Example:**
- `myclient_refresh_token_20250123_1430.json`
- `myclient_refresh_token_20250123_1430.txt`

---

## Integration Examples

### Using Tokens with Popular Analytics Platforms

#### Salesforce Marketing Cloud Intelligence (Datorama)
```python
import datorama
import requests
import json

# Load refresh token
refresh_token = "your_refresh_token_from_file"

# Authenticate with Instacart API
auth_payload = {
    "client_id": "your_client_id",
    "client_secret": "your_client_secret",
    "refresh_token": refresh_token,
    "grant_type": "refresh_token"
}

response = requests.post(
    "https://api.ads.instacart.com/oauth/token",
    data=json.dumps(auth_payload),
    headers={"Content-Type": "application/json"}
)

access_token = response.json()["access_token"]

# Fetch data from Instacart API
# Then save to Datorama
datorama.save_csv(csv_data)
```

#### Tableau Web Data Connector
```javascript
// Tableau WDC using refresh token
(function() {
    var myConnector = tableau.makeConnector();
    
    myConnector.getSchema = function(schemaCallback) {
        // Define your schema
    };
    
    myConnector.getData = function(table, doneCallback) {
        // Use refresh token to get access token
        var refreshToken = "your_refresh_token_here";
        
        // Authenticate and fetch data
        $.post("https://api.ads.instacart.com/oauth/token", {
            client_id: "your_client_id",
            client_secret: "your_client_secret", 
            refresh_token: refreshToken,
            grant_type: "refresh_token"
        }).done(function(authData) {
            // Use authData.access_token for API calls
        });
    };
    
    tableau.registerConnector(myConnector);
})();
```

#### Power BI Custom Connector
```powerquery
// Power BI M query using refresh token
let
    RefreshToken = "your_refresh_token_here",
    
    AuthResponse = Json.Document(
        Web.Contents("https://api.ads.instacart.com/oauth/token",
            [
                Headers = [#"Content-Type" = "application/json"],
                Content = Json.FromValue([
                    client_id = "your_client_id",
                    client_secret = "your_client_secret",
                    refresh_token = RefreshToken,
                    grant_type = "refresh_token"
                ])
            ]
        )
    ),
    
    AccessToken = AuthResponse[access_token],
    
    // Use AccessToken for subsequent API calls
    ApiData = Json.Document(
        Web.Contents("https://api.ads.instacart.com/api/v2/your-endpoint",
            [Headers = [Authorization = "Bearer " & AccessToken]]
        )
    )
in
    ApiData
```

#### Python ETL Pipeline
```python
import pandas as pd
import requests
import json
from sqlalchemy import create_engine

class InstacartETL:
    def __init__(self, refresh_token, client_id, client_secret):
        self.refresh_token = refresh_token
        self.client_id = client_id
        self.client_secret = client_secret
        self.access_token = None
        
    def authenticate(self):
        """Get access token using refresh token"""
        auth_payload = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "refresh_token": self.refresh_token,
            "grant_type": "refresh_token"
        }
        
        response = requests.post(
            "https://api.ads.instacart.com/oauth/token",
            data=json.dumps(auth_payload),
            headers={"Content-Type": "application/json"}
        )
        
        self.access_token = response.json()["access_token"]
        
    def extract_data(self):
        """Extract data from Instacart API"""
        headers = {"Authorization": f"Bearer {self.access_token}"}
        response = requests.get(
            "https://api.ads.instacart.com/api/v2/reports/products",
            headers=headers
        )
        return response.json()
        
    def transform_data(self, raw_data):
        """Transform data for analytics"""
        df = pd.DataFrame(raw_data)
        # Your transformation logic here
        return df
        
    def load_data(self, df, connection_string):
        """Load data to your data warehouse"""
        engine = create_engine(connection_string)
        df.to_sql('instacart_data', engine, if_exists='append', index=False)

# Usage
etl = InstacartETL(
    refresh_token="your_token_here",
    client_id="your_client_id", 
    client_secret="your_client_secret"
)
etl.authenticate()
data = etl.extract_data()
transformed = etl.transform_data(data)
etl.load_data(transformed, "postgresql://user:pass@host:port/db")
```

---

## Security Best Practices

### Environment Variable Security
```bash
# Add .env to your .gitignore
echo ".env" >> .gitignore

# Set restrictive permissions
chmod 600 .env
```

### Token Storage
- Store refresh tokens securely
- Use different tokens for development/production
- Rotate tokens regularly
- Never commit tokens to version control
- Never share tokens in plain text communications

### Production Recommendations
- Use secret management systems (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault)
- Implement token rotation schedules
- Monitor token usage and expiration
- Use separate credentials for each environment
- Encrypt token storage at rest

---

## Advanced Configuration

### Custom Client Names

Add new clients by updating the `CLIENTS` environment variable:

```bash
CLIENTS=BRAND1,BRAND2,AGENCY_CLIENT_A,AGENCY_CLIENT_B

# Then add each client's credentials
BRAND1_CLIENT_ID=your_brand1_client_id
BRAND1_CLIENT_SECRET=your_brand1_client_secret
BRAND1_REDIRECT_URI=https://your-app.com/callback
BRAND1_AUTH_CODE=your_brand1_auth_code

AGENCY_CLIENT_A_CLIENT_ID=your_agency_client_id
AGENCY_CLIENT_A_CLIENT_SECRET=your_agency_client_secret
AGENCY_CLIENT_A_REDIRECT_URI=https://agency-platform.com/callback
AGENCY_CLIENT_A_AUTH_CODE=your_agency_auth_code
```

### Common Redirect URI Patterns

#### Analytics Platforms
```bash
# Salesforce Marketing Cloud Intelligence (Datorama)
REDIRECT_URI=https://app.datorama.com

# Tableau Server
REDIRECT_URI=https://your-tableau-server.com/oauth/callback

# Power BI
REDIRECT_URI=https://app.powerbi.com/oauth/callback

# Custom Analytics Dashboard
REDIRECT_URI=https://your-dashboard.com/api/oauth/callback
```

#### Development & Testing
```bash
# Local development
REDIRECT_URI=http://localhost:3000/callback

# Development environment
REDIRECT_URI=https://dev-analytics.yourcompany.com/callback

# Staging environment  
REDIRECT_URI=https://staging-analytics.yourcompany.com/callback
```

### Batch Processing for Agencies

```bash
#!/bin/bash
# refresh_all_client_tokens.sh

# Development Environment
export ENV=development
export CLIENTS=CLIENT_A_DEV,CLIENT_B_DEV
python instacart_refresh_token.py

# Production Environment  
export ENV=production
export CLIENTS=CLIENT_A_PROD,CLIENT_B_PROD
python instacart_refresh_token.py
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `No CLIENTS found in .env` | Missing or empty `CLIENTS` variable | Set `CLIENTS=CLIENT1,CLIENT2...` in `.env` |
| `Error 400: Invalid grant` | Expired authorization code | Generate new authorization code through Instacart OAuth |
| `Error 401: Unauthorized` | Invalid client credentials | Verify `CLIENT_ID` and `CLIENT_SECRET` in Instacart dashboard |
| `Error 400: Invalid redirect URI` | Mismatched redirect URI | Ensure URI matches your Instacart app configuration exactly |

### Authorization Code Expiration

Authorization codes typically expire quickly (10-15 minutes). If you get "invalid grant" errors:

1. Generate a fresh authorization code
2. Run the script immediately  
3. Consider automating the OAuth flow for production use

### Debug Mode

Enable detailed error output:

```python
# Add to script for debugging
import logging
logging.basicConfig(level=logging.DEBUG)
```

### API Rate Limits

The script includes automatic delays between requests to respect Instacart's rate limits. For high-volume operations:

- Add longer delays between client requests
- Implement exponential backoff
- Monitor API response headers for rate limit information

---

## Integration Patterns

### Pattern 1: Scheduled Data Pipeline

```python
# scheduled_instacart_pipeline.py
import schedule
import time
from your_etl_module import InstacartETL

def run_daily_sync():
    """Daily data synchronization"""
    clients = ["CLIENT1", "CLIENT2", "CLIENT3"]
    
    for client in clients:
        try:
            # Load refresh token
            with open(f"{client.lower()}_refresh_token_latest.txt", 'r') as f:
                refresh_token = f.read().strip()
            
            # Run ETL process
            etl = InstacartETL(refresh_token, client_config[client])
            etl.run_pipeline()
            
            print(f"Completed sync for {client}")
            
        except Exception as e:
            print(f"Failed sync for {client}: {e}")
            # Send alert/notification

# Schedule daily at 2 AM
schedule.every().day.at("02:00").do(run_daily_sync)

while True:
    schedule.run_pending()
    time.sleep(60)
```

### Pattern 2: Real-time API Gateway

```python
# api_gateway.py
from flask import Flask, jsonify, request
import redis
import json

app = Flask(__name__)
cache = redis.Redis(host='localhost', port=6379, db=0)

class TokenManager:
    def __init__(self):
        self.refresh_tokens = self.load_refresh_tokens()
    
    def load_refresh_tokens(self):
        """Load refresh tokens from secure storage"""
        # Implementation depends on your storage solution
        pass
    
    def get_access_token(self, client_id):
        """Get cached access token or refresh if needed"""
        cached_token = cache.get(f"access_token:{client_id}")
        
        if cached_token:
            return cached_token.decode('utf-8')
        
        # Refresh token and cache for 50 minutes (tokens expire in 60)
        new_token = self.refresh_access_token(client_id)
        cache.setex(f"access_token:{client_id}", 3000, new_token)
        return new_token

@app.route('/api/instacart/<client_id>/reports')
def get_reports(client_id):
    """Proxy endpoint for Instacart reports"""
    token_manager = TokenManager()
    access_token = token_manager.get_access_token(client_id)
    
    # Proxy request to Instacart API
    # Return data to your analytics platform
    
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Pattern 3: Multi-Platform Distribution

```python
# multi_platform_sync.py
import asyncio
import aiohttp
from dataclasses import dataclass
from typing import List

@dataclass
class Platform:
    name: str
    endpoint: str
    auth_header: str
    transform_func: callable

class MultiPlatformSync:
    def __init__(self, instacart_token):
        self.instacart_token = instacart_token
        self.platforms = [
            Platform("Tableau", "https://tableau.com/api/data", "Bearer", self.transform_for_tableau),
            Platform("PowerBI", "https://powerbi.com/api/datasets", "Bearer", self.transform_for_powerbi),
            Platform("Looker", "https://looker.com/api/data", "Bearer", self.transform_for_looker),
        ]
    
    async def sync_to_platform(self, session, platform, data):
        """Sync data to a specific platform"""
        transformed_data = platform.transform_func(data)
        
        async with session.post(
            platform.endpoint,
            headers={"Authorization": platform.auth_header},
            json=transformed_data
        ) as response:
            if response.status == 200:
                print(f"Synced to {platform.name}")
            else:
                print(f"Failed to sync to {platform.name}")
    
    async def sync_all_platforms(self, instacart_data):
        """Sync to all platforms concurrently"""
        async with aiohttp.ClientSession() as session:
            tasks = [
                self.sync_to_platform(session, platform, instacart_data)
                for platform in self.platforms
            ]
            await asyncio.gather(*tasks)

# Usage
sync_manager = MultiPlatformSync("your_instacart_token")
await sync_manager.sync_all_platforms(your_instacart_data)
```

---

## Production Deployment

### Docker Support

```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY . .

# Create non-root user for security
RUN useradd -m -u 1001 tokenuser
USER tokenuser

# Run token refresh
CMD ["python", "instacart_refresh_token.py"]
```

### Kubernetes Deployment

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
            env:
            - name: CLIENTS
              valueFrom:
                secretKeyRef:
                  name: instacart-config
                  key: clients
            - name: CLIENT1_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: instacart-secrets
                  key: client1-id
            # Add other environment variables
            volumeMounts:
            - name: token-storage
              mountPath: /app/tokens
          volumes:
          - name: token-storage
            persistentVolumeClaim:
              claimName: token-storage-pvc
          restartPolicy: OnFailure
```

### AWS Lambda Deployment

```python
# lambda_function.py
import json
import boto3
import os
from instacart_refresh_token import main

def lambda_handler(event, context):
    """AWS Lambda handler for token refresh"""
    
    # Get credentials from AWS Secrets Manager
    secrets_client = boto3.client('secretsmanager')
    
    try:
        # Get secret containing all client credentials
        secret_value = secrets_client.get_secret_value(
            SecretId='instacart-api-credentials'
        )
        
        credentials = json.loads(secret_value['SecretString'])
        
        # Set environment variables from secrets
        for key, value in credentials.items():
            os.environ[key] = value
        
        # Run token refresh
        main()
        
        # Store new tokens back to S3 or Secrets Manager
        s3_client = boto3.client('s3')
        # Upload token files to S3
        
        return {
            'statusCode': 200,
            'body': json.dumps('Token refresh completed successfully')
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Token refresh failed: {str(e)}')
        }
```

---

## Use Cases

### Marketing Agencies
- **Multi-Client Management:** Handle dozens of client accounts efficiently
- **Cross-Platform Reporting:** Distribute data to multiple analytics tools
- **Automated Dashboards:** Set up recurring data pulls for client reporting
- **Credential Isolation:** Keep each client's tokens separate and secure

### Enterprise Brands
- **Multi-Brand Portfolios:** Manage tokens for different product lines
- **Development/Production:** Separate environments with different credentials
- **Team Collaboration:** Shared token management for data teams
- **Compliance:** Audit trails and secure token rotation

### Data Engineers
- **Pipeline Automation:** Integrate with existing ETL workflows
- **Error Handling:** Robust token refresh with fallback mechanisms
- **Monitoring:** Track token usage and expiration across systems
- **Scalability:** Handle high-volume data processing

### Analytics Platforms
- **Custom Connectors:** Build platform-specific Instacart integrations
- **Real-time Data:** Stream Instacart data to dashboards
- **Data Warehouses:** ETL processes for data lake architectures
- **Business Intelligence:** Automated reporting and insights

---

## Support & Community

### Documentation
- [Instacart Ads API Documentation](https://docs.ads.instacart.com/)
- [OAuth 2.0 Authorization Code Flow](https://oauth.net/2/grant-types/authorization-code/)

### Open Source Community
This tool is open source and community-driven. Contributions welcome!

**Feature Requests & Issues**
- Open GitHub issues for bugs or feature requests
- Include detailed reproduction steps for bugs
- Suggest improvements for better platform integrations

### Mazava Consulting
- **Email:** paul@mazavaltd.com
- **Company:** Mazava Consulting  
- **Tagline:** #AnalyzeResponsibly

*Data solutions that actually work.*

### Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

**Areas for Contribution:**
- Additional platform integrations
- Enhanced error handling
- Security improvements
- Performance optimizations
- Documentation updates

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

© 2025 Mazava Consulting. Released as open source for the data community.

---

<p align="center">
  <sub>Built For Impact by <a href="https://mazavaltd.com">Mazava Consulting</a> for the data community</sub><br>
  <sub>For support, try turning it off and on again, or email us for actual help.</sub><br>
  <sub><strong>#AnalyzeResponsibly</strong></sub>
</p>
