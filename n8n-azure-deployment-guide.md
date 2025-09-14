# Complete Guide: Deploying n8n on Azure Free Tier with Custom Domain

This comprehensive guide walks you through deploying n8n (workflow automation tool) on Azure's always free services, connecting it to Supabase for persistent storage, and configuring a custom domain with SSL.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Azure Service Selection](#azure-service-selection)
- [Initial Setup](#initial-setup)
- [Deploying n8n](#deploying-n8n)
- [Database Integration](#database-integration)
- [Custom Domain Configuration](#custom-domain-configuration)
- [Webhook Configuration](#webhook-configuration)
- [Final Configuration Summary](#final-configuration-summary)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting, ensure you have:
- Azure account with active subscription
- Azure CLI installed and configured
- Supabase account with a database project
- Custom domain registered (e.g., `assistt.in`)
- Cloudflare account managing your domain's DNS
- Cloudflare API token with DNS edit permissions

## Azure Service Selection

### Why Azure Container Apps?

We chose **Azure Container Apps** over other options for these reasons:

| Service | Pros | Cons | Verdict |
|---------|------|------|---------|
| **Container Instances** | Simple, 20 free containers/month | No auto-scaling, manual management | ❌ Limited features |
| **App Service** | Full-featured, easy deployment | Free tier quota limitations | ❌ Quota issues |
| **Container Apps** | Auto-scaling, 2M requests free, scale-to-zero | Slightly more complex setup | ✅ **Best choice** |

**Container Apps Benefits:**
- **Always Free Tier:** 2 million requests and 400,000 GB-seconds per month
- **Scale-to-Zero:** No costs when inactive
- **Automatic SSL:** Managed certificates for custom domains
- **Auto-scaling:** Handles traffic spikes automatically
- **External Ingress:** Direct HTTPS access without port configuration

## Initial Setup

### Step 1: Verify Azure CLI Installation

```bash
# Check Azure CLI version
az --version

# Login to Azure account
az login

# Verify account details
az account show
```

Expected output should show your subscription details and confirm you're logged in.

### Step 2: Register Required Azure Providers

```bash
# Register Container Apps provider
az provider register --namespace Microsoft.App

# Register Log Analytics provider (required for Container Apps)
az provider register --namespace Microsoft.OperationalInsights

# Check registration status
az provider show -n Microsoft.App --query registrationState
az provider show -n Microsoft.OperationalInsights --query registrationState
```

Wait for both providers to show `"Registered"` status before proceeding.

### Step 3: Create Resource Group

```bash
# Create resource group in East US region
az group create --name n8n-free-rg --location eastus
```

## Deploying n8n

### Step 4: Create Container Apps Environment

```bash
# Create Container Apps environment
az containerapp env create --name n8n-env --resource-group n8n-free-rg --location eastus
```

**Note:** This command may take 2-3 minutes and will automatically create a Log Analytics workspace.

### Step 5: Deploy n8n Container

```bash
# Deploy n8n with basic authentication
az containerapp create \
  --name n8n-app \
  --resource-group n8n-free-rg \
  --environment n8n-env \
  --image n8nio/n8n:latest \
  --target-port 5678 \
  --ingress external \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 0 \
  --max-replicas 1 \
  --env-vars \
    N8N_HOST=0.0.0.0 \
    N8N_PORT=5678 \
    N8N_PROTOCOL=http \
    N8N_BASIC_AUTH_ACTIVE=true \
    N8N_BASIC_AUTH_USER=admin \
    N8N_BASIC_AUTH_PASSWORD=SecurePass123!
```

**Configuration Explanation:**
- `--min-replicas 0`: Enables scale-to-zero for cost savings
- `--max-replicas 1`: Limits to one instance (sufficient for personal use)
- `--cpu 0.5 --memory 1Gi`: Resource allocation within free tier limits
- Basic auth enabled for security

### Step 6: Verify Initial Deployment

```bash
# Check deployment status
az containerapp show --name n8n-app --resource-group n8n-free-rg \
  --query "properties.{Status:runningStatus,URL:configuration.ingress.fqdn}" \
  --output table
```

You should see status as "Running" and get the initial Azure URL (e.g., `n8n-app.nicewater-c2481a23.eastus.azurecontainerapps.io`).

## Database Integration

### Why Supabase for Persistence?

Without external storage, Container Apps lose all data when scaling to zero. Supabase provides:
- Free PostgreSQL database (500MB storage)
- Automatic backups
- Real-time features (if needed later)
- Easy integration with n8n

### Step 7: Prepare Supabase Database

```bash
# List your Supabase projects
supabase projects list

# Get your project details (replace with your project ref)
supabase projects api-keys --project-ref YOUR_PROJECT_REF
```

**Required Information:**
- Project Reference ID (e.g., `slicsqdcgwxgfvlmnrqz`)
- Database Password (from Supabase Dashboard > Settings > Database)

### Step 8: Update n8n with Database Configuration

**⚠️ IMPORTANT:** Use connection string format to avoid IPv6 connection issues with Azure Container Apps.

```bash
# Update container app with database connection string (RECOMMENDED)
az containerapp update \
  --name n8n-app \
  --resource-group n8n-free-rg \
  --replace-env-vars \
    DB_POSTGRESDB_CONNECTION_STRING="postgresql://postgres:YOUR_DATABASE_PASSWORD@aws-0-ap-south-1.pooler.supabase.com:5432/postgres?sslmode=require" \
    N8N_HOST=0.0.0.0 \
    N8N_PORT=5678 \
    N8N_PROTOCOL=http \
    N8N_BASIC_AUTH_ACTIVE=true \
    N8N_BASIC_AUTH_USER=admin \
    N8N_BASIC_AUTH_PASSWORD=SecurePass123! \
    N8N_USER_MANAGEMENT_DISABLED=true \
    N8N_ENCRYPTION_KEY=yourEncryptionKey123 \
    N8N_USER_FOLDER=/home/node/.n8n \
    WEBHOOK_URL=https://n8n.assistt.in/
```

**Critical Variables Explained:**
- `DB_POSTGRESDB_CONNECTION_STRING`: Uses pooler URL to force IPv4 connection
- `N8N_ENCRYPTION_KEY`: **Essential** for data persistence across restarts
- `N8N_USER_MANAGEMENT_DISABLED`: Simplifies authentication setup
- `N8N_HOST=0.0.0.0`: Allows container to bind to all interfaces
- `N8N_PORT=5678`: Internal port (Azure maps this to 443/HTTPS externally)

**Replace:**
- `YOUR_DATABASE_PASSWORD` with your actual Supabase database password
- `yourEncryptionKey123` with a strong, random encryption key

### Step 9: Test Database Connection

```bash
# Restart the container to apply new configuration
az containerapp revision restart \
  --name n8n-app \
  --resource-group n8n-free-rg \
  --revision $(az containerapp show --name n8n-app --resource-group n8n-free-rg --query "properties.latestRevisionName" -o tsv)

# Verify container is running
az containerapp show --name n8n-app --resource-group n8n-free-rg --query "properties.runningStatus"
```

## Custom Domain Configuration

### Step 10: Get Domain Verification Details

```bash
# Attempt to add custom domain (this will show required DNS records)
az containerapp hostname add --hostname n8n.assistt.in --name n8n-app --resource-group n8n-free-rg
```

This command will fail but provide the required TXT record for domain verification. Note the verification ID (e.g., `8FE59AB6950B100B757E4B7E7D69DD10AB7865FC841A31F9B407175073D08380`).

### Step 11: Configure DNS Records in Cloudflare

#### Method 1: Using Cloudflare API (Recommended)

```bash
# Set your Cloudflare API token
export CLOUDFLARE_API_TOKEN=your_cloudflare_api_token

# Get your zone ID
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=assistt.in" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" | \
  grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Add TXT record for domain verification
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type":"TXT",
    "name":"asuid.n8n.assistt.in",
    "content":"YOUR_VERIFICATION_ID",
    "ttl":300
  }'

# Add or update CNAME record for subdomain
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type":"CNAME",
    "name":"n8n.assistt.in",
    "content":"n8n-app.nicewater-c2481a23.eastus.azurecontainerapps.io",
    "ttl":300,
    "proxied":false
  }'
```

#### Method 2: Manual Configuration in Cloudflare Dashboard

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your domain (`assistt.in`)
3. Navigate to **DNS** → **Records**
4. Add these records:

**TXT Record for Verification:**
- **Type:** TXT
- **Name:** `asuid.n8n`
- **Content:** `YOUR_VERIFICATION_ID`
- **TTL:** Auto

**CNAME Record for Subdomain:**
- **Type:** CNAME
- **Name:** `n8n`
- **Content:** `n8n-app.nicewater-c2481a23.eastus.azurecontainerapps.io`
- **Proxy Status:** DNS Only (gray cloud icon)
- **TTL:** Auto

### Step 12: Add Custom Domain to Azure

```bash
# Wait 30 seconds for DNS propagation, then add domain
sleep 30
az containerapp hostname add --hostname n8n.assistt.in --name n8n-app --resource-group n8n-free-rg
```

### Step 13: Enable SSL Certificate

```bash
# Bind hostname with SSL certificate
az containerapp hostname bind \
  --hostname n8n.assistt.in \
  --name n8n-app \
  --resource-group n8n-free-rg \
  --environment n8n-env \
  --validation-method CNAME
```

**Note:** SSL certificate provisioning can take up to 20 minutes. The command may timeout, but the process continues in the background.

### Step 14: Verify Custom Domain Setup

```bash
# Check custom domain status
az containerapp show --name n8n-app --resource-group n8n-free-rg \
  --query "properties.configuration.ingress.customDomains" --output json

# Test HTTP connectivity
curl -I http://n8n.assistt.in

# Test HTTPS connectivity (may fail initially while certificate provisions)
curl -I https://n8n.assistt.in
```

## Webhook Configuration

### Step 15: Update n8n for Custom Domain Webhooks

The critical step that fixes webhook URLs showing `0.0.0.0:5678` instead of your custom domain:

```bash
# Update n8n with custom domain configuration
az containerapp update \
  --name n8n-app \
  --resource-group n8n-free-rg \
  --set-env-vars \
    WEBHOOK_URL=https://n8n.assistt.in/
```

**⚠️ IMPORTANT:** Keep `N8N_HOST=0.0.0.0` and `N8N_PORT=5678` for internal container configuration. Azure Container Apps handles the external HTTPS mapping automatically.

**Why This Configuration Works:**
- `N8N_HOST=0.0.0.0` - Allows n8n to bind to all container interfaces
- `N8N_PORT=5678` - Internal container port (non-privileged)
- `N8N_PROTOCOL=http` - Internal protocol (Azure handles HTTPS termination)
- `WEBHOOK_URL=https://n8n.assistt.in/` - External URL for webhooks (what users see)

**Common Mistake to Avoid:**
❌ Don't set `N8N_PORT=443` - this requires root privileges and will cause container startup failures

### Step 16: Verify Webhook Configuration

After the update, your webhook URLs should show as:
```
https://n8n.assistt.in/webhook-test/your-webhook-id
```

Instead of:
```
http://0.0.0.0:5678/webhook-test/your-webhook-id
```

## Final Configuration Summary

### Access Details
- **n8n URL:** https://n8n.assistt.in
- **Username:** admin
- **Password:** SecurePass123!

### Technical Configuration

**Azure Container Apps:**
- **Resource Group:** n8n-free-rg
- **Environment:** n8n-env
- **App Name:** n8n-app
- **Scaling:** 0-1 replicas (scale-to-zero enabled)
- **Resources:** 0.5 CPU, 1Gi memory

**Database (Supabase):**
- **Type:** PostgreSQL
- **Host:** db.YOUR_PROJECT_REF.supabase.co
- **Database:** postgres
- **Schema:** public

**DNS Configuration:**
- **Domain:** n8n.assistt.in
- **SSL:** Azure Managed Certificate
- **DNS Provider:** Cloudflare

**Key Environment Variables (CORRECTED):**
```bash
# Database Configuration (IPv4 Compatible)
DB_POSTGRESDB_CONNECTION_STRING=postgresql://postgres:PASSWORD@aws-0-ap-south-1.pooler.supabase.com:5432/postgres?sslmode=require

# n8n Server Configuration (Container Internal)
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http

# External Access Configuration
WEBHOOK_URL=https://n8n.assistt.in/

# Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=SecurePass123!

# Data Persistence (CRITICAL)
N8N_ENCRYPTION_KEY=your-unique-encryption-key-123
N8N_USER_MANAGEMENT_DISABLED=true
N8N_USER_FOLDER=/home/node/.n8n
```

**⚠️ CRITICAL NOTES:**
- Never use `N8N_PORT=443` - causes privilege errors
- Never change `N8N_ENCRYPTION_KEY` after initial setup
- Use connection string format to avoid IPv6 issues

## Troubleshooting

### Common Issues and Solutions

#### 1. Container Not Starting
**Symptom:** Container shows "Provisioning" or "Failed" status
**Solution:**
```bash
# Check container logs
az containerapp logs show --name n8n-app --resource-group n8n-free-rg --follow

# Restart the container
az containerapp revision restart --name n8n-app --resource-group n8n-free-rg --revision REVISION_NAME
```

#### 2. Database Connection Issues
**Symptoms:** n8n shows database connection errors, IPv6 connection failures
**Primary Cause:** Azure Container Apps doesn't support IPv6 outbound connections

**Solutions:**
1. **Use Connection String Format (RECOMMENDED):**
```bash
az containerapp update --name n8n-app --resource-group n8n-free-rg \
  --set-env-vars DB_POSTGRESDB_CONNECTION_STRING="postgresql://postgres:PASSWORD@aws-0-ap-south-1.pooler.supabase.com:5432/postgres?sslmode=require"
```

2. **Alternative: Use IPv4 DNS Resolution:**
```bash
az containerapp update --name n8n-app --resource-group n8n-free-rg \
  --set-env-vars NODE_OPTIONS="--dns-result-order=ipv4first"
```

**Error Indicators:**
- `connect ENETUNREACH 2406:da1a:...` (IPv6 address in error)
- Database timeout errors
- n8n stuck on "Initializing n8n process"

#### 3. SSL Certificate Not Working
**Symptoms:** HTTPS not accessible, SSL errors
**Solutions:**
- Wait up to 20 minutes for certificate provisioning
- Verify DNS records are correctly configured
- Ensure CNAME record is not proxied through Cloudflare

```bash
# Check certificate status
az containerapp env certificate list --resource-group n8n-free-rg --name n8n-env

# Verify DNS propagation
nslookup n8n.assistt.in
```

#### 4. Webhook URLs Still Showing 0.0.0.0
**Symptoms:** Webhooks show `http://0.0.0.0:5678/webhook...`
**Solution:** Ensure these environment variables are set correctly:
```bash
az containerapp update --name n8n-app --resource-group n8n-free-rg \
  --set-env-vars \
    N8N_HOST=n8n.assistt.in \
    N8N_PORT=443 \
    N8N_PROTOCOL=https \
    WEBHOOK_URL=https://n8n.assistt.in/
```

#### 5. Custom Domain Not Accessible
**Symptoms:** Domain doesn't resolve or shows errors
**Solutions:**
1. Check DNS records in Cloudflare
2. Verify domain verification TXT record exists
3. Ensure CNAME record points to correct Azure URL
4. Wait for DNS propagation (up to 24 hours, typically 5-10 minutes)

```bash
# Check DNS records
dig TXT asuid.n8n.assistt.in
dig CNAME n8n.assistt.in
```

#### 6. Data Persistence Issues (Complete Setup Required After Restart)
**Symptoms:** n8n requires complete setup after container restarts, losing all workflows and settings
**Primary Cause:** Missing encryption key causes n8n to be unable to decrypt stored data

**Solution:**
```bash
az containerapp update --name n8n-app --resource-group n8n-free-rg \
  --set-env-vars \
    N8N_ENCRYPTION_KEY=your-unique-encryption-key-123 \
    N8N_USER_MANAGEMENT_DISABLED=true \
    N8N_USER_FOLDER=/home/node/.n8n
```

**⚠️ CRITICAL:** Once you set an encryption key, **never change it**. Changing it will make all existing data unreadable.

**Generate a Secure Encryption Key:**
```bash
# Generate a random 32-character key
openssl rand -hex 16
```

#### 7. Container Scaling Issues
**Symptoms:** App takes long time to start or doesn't scale
**Solutions:**
- This is normal behavior for scale-to-zero containers
- First request after inactivity may take 10-30 seconds
- Consider setting `--min-replicas 1` if immediate response needed (uses more resources)

### Monitoring and Maintenance

#### Check Resource Usage
```bash
# View container metrics
az containerapp show --name n8n-app --resource-group n8n-free-rg \
  --query "properties.{Status:runningStatus,CPU:template.containers[0].resources.cpu,Memory:template.containers[0].resources.memory}"
```

#### Update n8n Version
```bash
# Update to latest n8n version
az containerapp update --name n8n-app --resource-group n8n-free-rg --image n8nio/n8n:latest
```

#### Backup Consideration
Your data is automatically backed up in Supabase, but consider:
- Exporting workflow configurations periodically
- Documenting custom environment variables
- Keeping DNS configuration documented

### Cost Optimization

**Always Free Tier Limits:**
- **Container Apps:** 2 million requests, 400,000 GB-seconds/month
- **Typical Usage:** Should stay within free limits for personal use
- **Scale-to-Zero:** Automatically reduces costs during inactivity

**Monitoring Costs:**
```bash
# Check current usage (requires Azure portal for detailed metrics)
az consumption usage list --top 5
```

## Security Considerations

### Production Recommendations

1. **Change Default Credentials:**
   ```bash
   az containerapp update --name n8n-app --resource-group n8n-free-rg \
     --set-env-vars N8N_BASIC_AUTH_PASSWORD=YOUR_STRONG_PASSWORD
   ```

2. **Use Azure Key Vault for Secrets:**
   - Store database passwords in Key Vault
   - Reference secrets in Container App configuration

3. **Enable Network Security:**
   - Consider Azure Private Endpoints for production
   - Configure IP restrictions if needed

4. **Regular Updates:**
   - Monitor n8n releases for security updates
   - Update container image regularly

### Backup Strategy

1. **Database Backups:** Handled automatically by Supabase
2. **Configuration Backup:** Export n8n workflows regularly
3. **Infrastructure as Code:** Consider using ARM templates or Terraform

## Keep-Alive Solution (Always-On within Free Tier)

### Resource Optimization for Always-On

To keep n8n active 24/7 while staying within Azure's free tier limits:

```bash
# Optimize container resources for always-on usage
az containerapp update \
  --name n8n-app \
  --resource-group n8n-free-rg \
  --cpu 0.25 \
  --memory 0.5Gi \
  --min-replicas 1 \
  --max-replicas 1
```

**Resource Calculations:**
- **Memory Usage:** 0.5GB × 24 hours × 30 days = 360,000 GB-seconds/month
- **Free Limit:** 400,000 GB-seconds/month
- **Usage:** 90% of free tier (safe margin)

### GitHub Actions Keep-Alive Workflow

Create `.github/workflows/n8n-keepalive.yml` in any GitHub repository:

```yaml
name: n8n Keep-Alive

on:
  schedule:
    # Working hours (IST 9:30-17:30 = UTC 4:00-12:00)
    - cron: '*/15 4-12 * * 1-5'  # Every 15min, Mon-Fri
    # Light pings off-hours
    - cron: '0 */2 * * *'        # Every 2 hours

jobs:
  keepalive:
    runs-on: ubuntu-latest
    steps:
      - name: Ping n8n Instance
        run: |
          current_hour=$(date -u +%H)
          current_day=$(date -u +%u)

          if [[ $current_hour -ge 4 && $current_hour -le 12 && $current_day -le 5 ]]; then
            echo "Working hours - detailed health check"
            curl -s https://n8n.assistt.in/ > /dev/null
          else
            echo "Off-hours - light ping"
            curl -s -I https://n8n.assistt.in/ > /dev/null
          fi
```

**Benefits:**
- ✅ **No Cold Starts:** Instant response during working hours
- ✅ **Cost-Effective:** Uses ~90% of free tier
- ✅ **Intelligent Pinging:** More frequent during work hours
- ✅ **Request Efficient:** ~1,200 requests/month (0.06% of 2M limit)

### Usage Monitoring

Run the included PowerShell script weekly:

```powershell
# Check your usage
.\monitor-usage.ps1

# Quick usage check
az containerapp show --name n8n-app --resource-group n8n-free-rg \
  --query "properties.template.containers[0].resources"
```

### Alternative: Scale-to-Zero with Smart Wake-up

If you prefer lower resource usage:

```bash
# Enable scale-to-zero
az containerapp update \
  --name n8n-app \
  --resource-group n8n-free-rg \
  --min-replicas 0
```

**Trade-offs:**
- ✅ **Lower Cost:** ~10% of free tier usage
- ❌ **Cold Starts:** 10-30 second delay after inactivity
- ✅ **Still Functional:** GitHub Actions keeps it warm during work hours

## Conclusion

This guide provided a complete walkthrough of deploying n8n on Azure's free tier with:
- ✅ Azure Container Apps for hosting
- ✅ Supabase for persistent data storage
- ✅ Custom domain with SSL certificate
- ✅ Proper webhook URL configuration
- ✅ Scale-to-zero cost optimization

Your n8n instance is now production-ready for personal or small business use, leveraging entirely free services with enterprise-grade features like automatic SSL, scaling, and managed database backups.

---

**Total Setup Time:** 30-45 minutes (including DNS propagation)
**Monthly Cost:** $0 (within free tier limits)
**Maintenance Required:** Minimal (automatic updates available)

For questions or issues, refer to:
- [n8n Documentation](https://docs.n8n.io/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Supabase Documentation](https://supabase.com/docs)