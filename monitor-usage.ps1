# Azure Container Apps Usage Monitor
# Run this script weekly to check your free tier usage

param(
    [string]$ResourceGroup = "n8n-free-rg",
    [string]$AppName = "n8n-app"
)

Write-Host "🔍 Checking Azure Container Apps usage..." -ForegroundColor Cyan

# Check current container status
Write-Host "`n📊 Container Status:" -ForegroundColor Yellow
$containerStatus = az containerapp show --name $AppName --resource-group $ResourceGroup --query "properties.{Status:runningStatus,CPU:template.containers[0].resources.cpu,Memory:template.containers[0].resources.memory,MinReplicas:template.scale.minReplicas,MaxReplicas:template.scale.maxReplicas}" --output json | ConvertFrom-Json

Write-Host "Status: $($containerStatus.Status)" -ForegroundColor Green
Write-Host "CPU: $($containerStatus.CPU) cores"
Write-Host "Memory: $($containerStatus.Memory)"
Write-Host "Min Replicas: $($containerStatus.MinReplicas)"
Write-Host "Max Replicas: $($containerStatus.MaxReplicas)"

# Calculate monthly usage estimates
Write-Host "`n📈 Estimated Monthly Usage:" -ForegroundColor Yellow
$cpuCores = [decimal]$containerStatus.CPU
$memoryGB = [decimal]($containerStatus.Memory -replace 'Gi','')

# Always-on calculation (min-replicas = 1)
$hoursPerMonth = 24 * 30  # 720 hours
$gbSecondsPerMonth = $hoursPerMonth * 3600 * $memoryGB

Write-Host "Container Runtime: Always-on ($hoursPerMonth hours/month)" -ForegroundColor Green
Write-Host "GB-seconds/month: $gbSecondsPerMonth" -ForegroundColor $(if($gbSecondsPerMonth -lt 400000) {"Green"} else {"Red"})
Write-Host "Free limit: 400,000 GB-seconds/month"

# Calculate percentage of free tier used
$usagePercentage = [math]::Round(($gbSecondsPerMonth / 400000) * 100, 2)
Write-Host "Usage: $usagePercentage% of free tier" -ForegroundColor $(if($usagePercentage -lt 80) {"Green"} elseif($usagePercentage -lt 100) {"Yellow"} else {"Red"})

# Request estimation (from keep-alive workflow)
Write-Host "`n🌐 Estimated Request Usage:" -ForegroundColor Yellow
$requestsPerMonth = 1200  # From GitHub Actions workflow
$requestPercentage = [math]::Round(($requestsPerMonth / 2000000) * 100, 4)
Write-Host "Requests/month: ~$requestsPerMonth" -ForegroundColor Green
Write-Host "Usage: $requestPercentage% of free tier (2M requests/month)"

Write-Host "`n💡 Optimization Recommendations:" -ForegroundColor Cyan
if ($usagePercentage -gt 100) {
    Write-Host "⚠️  OVER LIMIT: Reduce memory to 0.25Gi or enable scale-to-zero" -ForegroundColor Red
} elseif ($usagePercentage -gt 80) {
    Write-Host "⚠️  High usage: Consider reducing resources if performance allows" -ForegroundColor Yellow
} else {
    Write-Host "✅ Usage is within safe limits" -ForegroundColor Green
}

Write-Host "`n🔧 Quick Commands:" -ForegroundColor Cyan
Write-Host "Reduce memory: az containerapp update --name $AppName --resource-group $ResourceGroup --memory 0.25Gi"
Write-Host "Enable scale-to-zero: az containerapp update --name $AppName --resource-group $ResourceGroup --min-replicas 0"
Write-Host "Check real usage: az monitor metrics list --resource /subscriptions/.../n8n-app --metric requests"