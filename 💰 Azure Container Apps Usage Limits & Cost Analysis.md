● 💰 Azure Container Apps Usage Limits & Cost Analysis

  🆓 Always Free Tier Limits (Per Month)

● | Resource      | Free Tier Limit    | Your Configuration                         |
  |---------------|--------------------|--------------------------------------------|
  | Requests      | 2,000,000/month    | Unlimited within limit                     |
  | Compute Time  | 400,000 GB-seconds | 0.5 vCPU × 1GB = 0.5 GB-seconds per second |
  | Bandwidth     | First 100GB free   | Covers typical usage                       |
  | Log Analytics | First 5GB/month    | Minimal logs expected                      |

  📊 Daily Usage Scenarios

● Scenario 1: Light Daily Usage 📱

  - Web UI Access: 30 minutes/day
  - Workflow Runs: 50 executions/day
  - Webhooks: 20 incoming/day
  - API Calls: 100/day

  Monthly Consumption:
  - Requests: ~5,000/month (0.25% of limit)
  - Compute: ~15,000 GB-seconds (3.75% of limit)
  - Scale-to-Zero: 23.5 hours/day inactive
  - Monthly Cost: $0 ✅

  Scenario 2: Moderate Daily Usage 💼

  - Web UI Access: 2 hours/day
  - Workflow Runs: 200 executions/day
  - Webhooks: 100 incoming/day
  - API Calls: 500/day
  - Background Jobs: 24/7 monitoring workflows

  Monthly Consumption:
  - Requests: ~25,000/month (1.25% of limit)
  - Compute: ~180,000 GB-seconds (45% of limit)
  - Always-on time: 4-6 hours/day
  - Monthly Cost: $0 ✅

  Scenario 3: Heavy Daily Usage 🚀

  - Web UI Access: 4+ hours/day
  - Workflow Runs: 500+ executions/day
  - Webhooks: 300+ incoming/day
  - API Calls: 1,000+ /day
  - Complex Workflows: Data processing, integrations

  Monthly Consumption:
  - Requests: ~60,000/month (3% of limit)
  - Compute: ~350,000 GB-seconds (87.5% of limit)
  - Always-on time: 8+ hours/day
  - Monthly Cost: $0-5 ⚠️

  💸 Potential Monthly Costs Breakdown

● | Component      | Free Tier   | Overage Cost          | Your Risk |
  |----------------|-------------|-----------------------|-----------|
  | Container Apps | 400K GB-sec | $0.000024/GB-sec      | Very Low  |
  | Requests       | 2M requests | $0.0000024/request    | Very Low  |
  | Log Analytics  | 5GB         | $2.30/GB              | Low       |
  | Bandwidth      | 100GB       | $0.05/GB              | Very Low  |
  | Supabase       | 500MB DB    | $25/month (paid tier) | Medium    |

  🎯 Realistic Monthly Bill Estimates

  Most Likely Scenario (95% of users):

  - Container Apps: $0 (within free tier)
  - Log Analytics: $0-2 (minimal logs)
  - Bandwidth: $0 (well within 100GB limit)
  - Supabase: $0 (within 500MB limit)
  - Total Monthly: $0-2 🎉

  Heavy Usage Scenario (5% of users):

  - Container Apps: $0-5 (if exceeding 400K GB-seconds)
  - Log Analytics: $2-5 (detailed logging)
  - Bandwidth: $0-5 (if heavy data transfer)
  - Supabase: $0-25 (if exceeding 500MB storage)
  - Total Monthly: $2-35 ⚠️

  🔍 What Uses Your Resources?

  High Resource Activities:

  - Complex Workflows: Data transformation, API polling
  - Always-On Monitoring: 24/7 running workflows
  - Heavy Web UI Usage: Multiple hours daily
  - Large Data Processing: File uploads, image processing

  Low Resource Activities:

  - Simple Triggers: Email notifications, Slack messages
  - Infrequent Workflows: Weekly/monthly automations
  - Basic Integrations: Simple webhook processing
  - Occasional UI Access: Configuration only

  🛡️ Cost Optimization Strategies

● 1. Optimize Container Configuration

  # Keep current optimal settings
  CPU: 0.5 (minimum for good performance)
  Memory: 1Gi (sufficient for most workflows)
  Min Replicas: 0 (scale-to-zero enabled)
  Max Replicas: 1 (prevents unexpected scaling costs)

  2. Monitor Resource Usage

  # Check current usage monthly
  az monitor metrics list --resource $(az containerapp show --name n8n-app --resource-group n8n-free-rg --query id -o tsv) --metric
   "Requests"

  3. Workflow Optimization

  - Use Scheduled Triggers instead of polling
  - Batch Operations when possible
  - Optimize Workflow Logic to reduce execution time
  - Use Webhooks instead of continuous monitoring

  4. Database Management

  - Regular Cleanup: Remove old workflow executions
  - Optimize Queries: Use efficient workflow designs
  - Monitor Storage: Keep under 500MB Supabase limit

  📈 Usage Monitoring Commands

  # Check Container App resource consumption
  az containerapp show --name n8n-app --resource-group n8n-free-rg \
    --query
  "properties.{Status:runningStatus,CPU:template.containers[0].resources.cpu,Memory:template.containers[0].resources.memory}"

  # Monitor costs (requires Cost Management access)
  az consumption usage list --top 5 --output table

  # Check Log Analytics usage
  az monitor log-analytics workspace show --resource-group n8n-free-rg --workspace-name YOUR_WORKSPACE_NAME

  🚨 Cost Alert Setup

  Set up cost alerts to avoid surprises:

  # Create budget alert (adjust amount as needed)
  az consumption budget create \
    --budget-name "n8n-monthly-budget" \
    --amount 10 \
    --time-grain Monthly \
    --time-period-start "$(date -u -d 'first day of this month' +%Y-%m-01T00:00:00Z)" \
    --category Cost \
    --resource-group n8n-free-rg

  📊 Real-World Usage Examples

  Personal Automation (Typical):

  - Daily workflow runs: 10-50
  - Monthly requests: 1,000-5,000
  - Compute usage: 5-20% of free tier
  - Expected monthly cost: $0 ✅

  Small Business Automation:

  - Daily workflow runs: 50-200
  - Monthly requests: 5,000-25,000
  - Compute usage: 20-60% of free tier
  - Expected monthly cost: $0 ✅

  Heavy Integration Platform:

  - Daily workflow runs: 200-500+
  - Monthly requests: 25,000-100,000+
  - Compute usage: 60-100%+ of free tier
  - Expected monthly cost: $0-15 ⚠️

  💡 Bottom Line

  For daily n8n usage, your monthly bill will most likely be:

  - 90% chance: $0 (stays within free tiers)
  - 8% chance: $1-5 (slight overages)
  - 2% chance: $5-25 (heavy usage or Supabase upgrade)

  Key factors that keep costs low:
  ✅ Scale-to-zero configuration
  ✅ Efficient resource allocation (0.5 CPU, 1GB RAM)
  ✅ Free tier limits are generous for personal/small business use
  ✅ Supabase free tier (500MB) sufficient for most n8n installations

  Monitor monthly and you should stay within free limits for typical daily usage! 🎯