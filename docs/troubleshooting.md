# Troubleshooting Guide

## Common Issues and Solutions

This guide covers the most frequently encountered issues when using the Instacart Token Refresh Utility and their solutions.

---

## Table of Contents

- [Environment Configuration Issues](#environment-configuration-issues)
- [Authentication Errors](#authentication-errors)  
- [API Request Failures](#api-request-failures)
- [Network and Connectivity Issues](#network-and-connectivity-issues)
- [File System and Permissions](#file-system-and-permissions)
- [Python Environment Issues](#python-environment-issues)
- [Rate Limiting and API Quotas](#rate-limiting-and-api-quotas)
- [Debug Mode and Logging](#debug-mode-and-logging)
- [Platform-Specific Issues](#platform-specific-issues)

---

## Environment Configuration Issues

### Issue: "No CLIENTS found in .env"

**Error Message:**
```
No CLIENTS found in .env. Please set CLIENTS=Client1,Client2...
```

**Causes:**
- Missing `.env` file
- Empty or missing `CLIENTS` variable
- Incorrect variable name

**Solutions:**

1. **Create .env file:**
```bash
cp .env.example .env
```

2. **Add CLIENTS variable:**
```bash
# In .env file
CLIENTS=CLIENT1,CLIENT2,BRANDX
```

3. **Check file location:**
```bash
# Ensure .env is in the same directory as the script
ls -la .env
```

4. **Verify variable format:**
```bash
# Correct format (comma-separated, no spaces around commas)
CLIENTS=CLIENT1,CLIENT2,CLIENT3

# Incorrect format
CLIENTS=CLIENT1, CLIENT2, CLIENT3  # Spaces around commas
CLIENTS="CLIENT1,CLIENT2,CLIENT3"  # Unnecessary quotes
```

### Issue: Missing Client Credentials

**Error Message:**
```
CLIENT1 Client ID: [prompts for input]
```

**Causes:**
- Missing credential variables in `.env`
- Typos in variable names
- Client name mismatch

**Solutions:**

1. **Check variable naming:**
```bash
# Correct format
CLIENT1_CLIENT_ID=your_client_id
CLIENT1_CLIENT_SECRET=your_client_secret  
CLIENT1_REDIRECT_URI=your_redirect_uri
CLIENT1_AUTH_CODE=your_auth_code

# Must match CLIENTS list exactly
CLIENTS=CLIENT1  # This must match the prefix above
```

2. **Verify all required variables:**
```bash
# Check if all variables are set
grep "CLIENT1_" .env
```

3. **Case sensitivity:**
```bash
# Variable names are case-sensitive
CLIENT1_CLIENT_ID=correct
client1_client_id=incorrect
```

---

## Authentication Errors

### Issue: "Error 400: Invalid grant"

**Error Message:**
```
Error 400 from Instacart API:
{"error": "invalid_grant", "error_description": "The provided authorization grant is invalid"}
```

**Causes:**
- Expired authorization code
- Invalid authorization code
- Code already used
- Incorrect client credentials

**Solutions:**

1. **Generate fresh authorization code:**
   - Authorization codes expire in 10-15 minutes
   - Always generate a new code right before running the script
   - Use the exact same redirect URI as configured in your Instacart app

2. **Verify authorization flow:**
```bash
# Example authorization URL (replace with your values)
https://www.instacart.com/oauth/authorize?client_id=YOUR_CLIENT_ID&redirect_uri=YOUR_REDIRECT_URI&response_type=code&scope=ads:read

# Extract code from redirect URL
https://your-redirect-uri.com/callback?code=AUTHORIZATION_CODE_HERE
```

3. **Check redirect URI match:**
```bash
# Must match exactly (including trailing slashes)
# In Instacart app: https://app.datorama.com/
# In .env file: https://app.datorama.com/
```

### Issue: "Error 401: Unauthorized"

**Error Message:**
```
Error 401 from Instacart API:
{"error": "unauthorized", "error_description": "Invalid client credentials"}
```

**Causes:**
- Incorrect Client ID
- Incorrect Client Secret
- Credentials for wrong environment

**Solutions:**

1. **Verify credentials in Instacart dashboard:**
   - Login to Instacart Ads Manager
   - Navigate to API settings
   - Compare Client ID and Secret with your `.env` file

2. **Check for typos:**
```bash
# Common issues
CLIENT_ID=CG4Peb1YDAQvnILXSFvGKeLJePudmhLmiY2PvVquk1g    # Correct
CLIENT_ID=CG4Peb1YDAQvnILXSFvGKeLJePudmhLmiY2PvVquk1g.   # Extra period
CLIENT_ID= CG4Peb1YDAQvnILXSFvGKeLJePudmhLmiY2PvVquk1g  # Leading space
```

3. **Environment mismatch:**
   - Ensure using production credentials for production
   - Check if using sandbox/test credentials incorrectly

### Issue: "Error 400: Invalid redirect URI"

**Error Message:**
```
Error 400 from Instacart API:
{"error": "invalid_request", "error_description": "Invalid redirect URI"}
```

**Causes:**
- Redirect URI doesn't match app configuration
- URL encoding issues
- Protocol mismatch (http vs https)

**Solutions:**

1. **Exact match required:**
```bash
# In Instacart app settings: https://app.datorama.com
# In .env file: https://app.datorama.com

# These would fail:
# http://app.datorama.com      (http vs https)
# https://app.datorama.com/    (trailing slash difference)
# https://datorama.com         (missing subdomain)
```

2. **Check URL encoding:**
```bash
# If using special characters, ensure proper encoding
# Original: https://your-app.com/callback?param=value
# Encoded: https://your-app.com/callback%3Fparam%3Dvalue
```

---

## API Request Failures

### Issue: "API request failed after 5 attempts"

**Error Message:**
```
ConnectionError: API request failed after 5 attempts: HTTPSConnectionPool(host='api.ads.instacart.com', port=443)
```

**Causes:**
- Network connectivity issues
- DNS resolution problems
- Firewall blocking requests
- Instacart API downtime

**Solutions:**

1. **Check network connectivity:**
```bash
# Test basic connectivity
ping api.ads.instacart.com

# Test HTTPS connectivity
curl -I https://api.ads.instacart.com/oauth/token
```

2. **DNS resolution:**
```bash
# Check DNS resolution
nslookup api.ads.instacart.com
dig api.ads.instacart.com
```

3. **Firewall/proxy settings:**
```bash
# If behind corporate firewall, configure proxy
export https_proxy=http://proxy.company.com:8080
export http_proxy=http://proxy.company.com:8080
```

4. **Check Instacart API status:**
   - Visit Instacart developer status page
   - Check social media for outage announcements
   - Try requests from different network

### Issue: "Request timeout"

**Error Message:**
```
requests.exceptions.ReadTimeout: HTTPSConnectionPool(host='api.ads.instacart.com', port=443): Read timed out.
```

**Causes:**
- Slow network connection
- Large response payload
- Server-side processing delays

**Solutions:**

1. **Increase timeout values:**
```python
# Modify timeout in the script
response = requests.post(url, timeout=60)  # Increase from 30 to 60 seconds
```

2. **Check network speed:**
```bash
# Test download speed
curl -o /dev/null -s -w "%{time_total}\n" https://api.ads.instacart.com/oauth/token
```

3. **Retry with delays:**
```python
# Add delays between retry attempts
for attempt in range(max_retries):
    try:
        response = requests.post(url, timeout=30)
        break
    except requests.Timeout:
        if attempt < max_retries - 1:
            time.sleep(2 ** attempt)  # Exponential backoff
```

---

## File System and Permissions

### Issue: "Permission denied" when saving files

**Error Message:**
```
PermissionError: [Errno 13] Permission denied: 'client1_refresh_token_20250123_1430.json'
```

**Causes:**
- Insufficient write permissions
- Directory doesn't exist
- File in use by another process

**Solutions:**

1. **Check directory permissions:**
```bash
# Check current directory permissions
ls -la .

# Make directory writable
chmod 755 .
```

2. **Create output directory:**
```bash
# Create directory if it doesn't exist
mkdir -p output
cd output
python ../instacart_refresh_token.py
```

3. **Run with elevated permissions (if needed):**
```bash
# Linux/macOS
sudo python instacart_refresh_token.py

# Windows (run as administrator)
# Right-click command prompt > "Run as administrator"
```

### Issue: "File already exists" conflicts

**Error Message:**
```
FileExistsError: [Errno 17] File exists: 'client1_refresh_token_20250123_1430.json'
```

**Causes:**
- Multiple script runs at same time
- Timestamp collision
- Previous run interrupted

**Solutions:**

1. **Check for running processes:**
```bash
# Linux/macOS
ps aux | grep instacart_refresh_token.py

# Windows
tasklist | findstr python
```

2. **Remove old files:**
```bash
# Remove files older than 7 days
find . -name "*_refresh_token_*.json" -mtime +7 -delete
find . -name "*_refresh_token_*.txt" -mtime +7 -delete
```

3. **Use unique timestamps:**
```python
# Modify script to include microseconds
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
```

---

## Python Environment Issues

### Issue: "ModuleNotFoundError: No module named 'requests'"

**Error Message:**
```
ModuleNotFoundError: No module named 'requests'
```

**Causes:**
- Missing dependencies
- Wrong Python environment
- Virtual environment not activated

**Solutions:**

1. **Install dependencies:**
```bash
pip install requests python-dotenv
```

2. **Use virtual environment:**
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Linux/macOS:
source venv/bin/activate
# Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

3. **Check Python version:**
```bash
# Ensure Python 3.7+
python --version
python3 --version
```

### Issue: "SyntaxError" or "Invalid syntax"

**Error Message:**
```
SyntaxError: invalid syntax
```

**Causes:**
- Using Python 2.x instead of Python 3.x
- Corrupted script file
- Encoding issues

**Solutions:**

1. **Use Python 3:**
```bash
# Explicitly use Python 3
python3 instacart_refresh_token.py

# Check which Python is default
which python
which python3
```

2. **Fix encoding issues:**
```bash
# Check file encoding
file instacart_refresh_token.py

# Convert to UTF-8 if needed
iconv -f ISO-8859-1 -t UTF-8 instacart_refresh_token.py > fixed_script.py
```

---

## ⚡ Rate Limiting and API Quotas

### Issue: "Error 429: Too Many Requests"

**Error Message:**
```
Error 429 from Instacart API:
{"error": "rate_limit_exceeded", "error_description": "API rate limit exceeded"}
```

**Causes:**
- Making requests too frequently
- Multiple scripts running simultaneously
- API quota exceeded

**Solutions:**

1. **Add delays between requests:**
```python
# Add delay between client processing
for client in clients:
    process_client(client)
    time.sleep(5)  # Wait 5 seconds between clients
```

2. **Implement exponential backoff:**
```python
def make_request_with_backoff(url, data, max_retries=5):
    for attempt in range(max_retries):
        response = requests.post(url, data=data)
        
        if response.status_code == 429:
            wait_time = (2 ** attempt) + random.uniform(0, 1)
            time.sleep(wait_time)
            continue
            
        return response
    
    raise Exception("Max retries exceeded")
```

3. **Check for concurrent processes:**
```bash
# Kill other running instances
pkill -f instacart_refresh_token.py
```

### Issue: API quota exceeded

**Error Message:**
```
Error 403: Quota exceeded for API requests
```

**Solutions:**

1. **Monitor API usage:**
   - Check Instacart developer dashboard for quota limits
   - Implement usage tracking in your scripts

2. **Optimize request frequency:**
   - Reduce token refresh frequency
   - Batch multiple operations
   - Cache tokens longer

3. **Contact Instacart support:**
   - Request quota increase if needed
   - Verify account status

---

## Debug Mode and Logging

### Enable Debug Logging

```python
import logging

# Add to beginning of script
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('debug.log'),
        logging.StreamHandler()
    ]
)

# Enable requests debugging
import http.client as http_client
http_client.HTTPConnection.debuglevel = 1
```

### Verbose Output Mode

```python
# Add verbose flag to script
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose output')
args = parser.parse_args()

if args.verbose:
    print(f"Processing client: {client_name}")
    print(f"Request payload: {json.dumps(data, indent=2)}")
    print(f"Response status: {response.status_code}")
    print(f"Response headers: {dict(response.headers)}")
```

### Common Debug Commands

```bash
# Run with maximum verbosity
python -v instacart_refresh_token.py

# Capture all output
python instacart_refresh_token.py > output.log 2>&1

# Monitor in real-time
python instacart_refresh_token.py | tee output.log

# Check system resources
top -p $(pgrep -f instacart_refresh_token.py)
```

---

## Platform-Specific Issues

### Windows Issues

**Issue: "UnicodeDecodeError"**
```python
# Solution: Specify encoding
with open(filename, 'w', encoding='utf-8') as f:
    f.write(content)
```

**Issue: Path separators**
```python
# Use os.path.join for cross-platform compatibility
import os
filename = os.path.join('output', f'{client}_token.txt')
```

**Issue: PowerShell execution policy**
```powershell
# Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### macOS Issues

**Issue: SSL certificate verification**
```bash
# Update certificates
/Applications/Python\ 3.x/Install\ Certificates.command

# Or install certificates manually
pip install --upgrade certifi
```

**Issue: Permission denied on M1 Macs**
```bash
# Use native Python
/usr/bin/python3 instacart_refresh_token.py

# Or install Python via Homebrew
brew install python
```

### Linux Issues

**Issue: "Command not found"**
```bash
# Add to PATH
export PATH=$PATH:/usr/local/bin

# Or use full path
/usr/bin/python3 instacart_refresh_token.py
```

**Issue: Missing SSL libraries**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install ca-certificates python3-pip

# CentOS/RHEL
sudo yum update ca-certificates python3-pip
```

---

## Advanced Troubleshooting

### Network Analysis

```bash
# Trace network requests
tcpdump -i any -n host api.ads.instacart.com

# Check DNS resolution time
dig +trace api.ads.instacart.com

# Test with curl
curl -v -X POST https://api.ads.instacart.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"client_id":"test","client_secret":"test","grant_type":"refresh_token","refresh_token":"test"}'
```

### Memory and Performance

```python
# Add memory monitoring
import psutil
import os

process = psutil.Process(os.getpid())
print(f"Memory usage: {process.memory_info().rss / 1024 / 1024:.2f} MB")

# Profile execution time
import time
start_time = time.time()
# Your code here
print(f"Execution time: {time.time() - start_time:.2f} seconds")
```

### JSON Response Analysis

```python
# Pretty print API responses
import json

response = requests.post(url, data=data)
print("Response Status:", response.status_code)
print("Response Headers:", dict(response.headers))

try:
    response_json = response.json()
    print("Response Body:")
    print(json.dumps(response_json, indent=2))
except json.JSONDecodeError:
    print("Response Text:", response.text)
```
---

## Additional Resources

### API Documentation
- [Instacart Ads API Documentation](https://docs.ads.instacart.com/)
- [OAuth 2.0 Specification](https://tools.ietf.org/html/rfc6749)

### Community Resources
- Stack Overflow tag: `instacart-api`
- Reddit: r/analytics, r/dataengineering
- LinkedIn: Instacart Developer Community

### Tools for Testing
- [Postman Collection for Instacart API](link-to-collection)
- [Online JWT Decoder](https://jwt.io/)
- [HTTP Status Code Reference](https://httpstatuses.com/)

---

*For additional support: paul@mazavaltd.com | #AnalyzeResponsibly*