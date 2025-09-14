# Reset n8n Database in Supabase
# This script will clear all n8n tables and restart the container

param(
    [string]$ResourceGroup = "n8n-free-rg",
    [string]$AppName = "n8n-app",
    [switch]$Confirm = $false
)

Write-Host "🚨 n8n Database Reset Script" -ForegroundColor Red
Write-Host "================================" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  This will PERMANENTLY DELETE all n8n data including:" -ForegroundColor Yellow
Write-Host "  - All workflows" -ForegroundColor Yellow
Write-Host "  - All executions history" -ForegroundColor Yellow
Write-Host "  - All credentials" -ForegroundColor Yellow
Write-Host "  - All users and settings" -ForegroundColor Yellow
Write-Host ""

if (-not $Confirm) {
    $response = Read-Host "Are you sure you want to continue? Type 'DELETE' to confirm"
    if ($response -ne "DELETE") {
        Write-Host "❌ Operation cancelled" -ForegroundColor Green
        exit
    }
}

Write-Host "🔄 Starting database reset process..." -ForegroundColor Cyan

# Step 1: Stop the n8n container to prevent new data writes
Write-Host "1️⃣ Scaling down n8n container..." -ForegroundColor Yellow
try {
    az containerapp update --name $AppName --resource-group $ResourceGroup --min-replicas 0 --max-replicas 0 | Out-Null
    Write-Host "✅ Container scaled down" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to scale down container: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Wait for container to stop
Write-Host "2️⃣ Waiting for container to stop..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 3: Manual SQL execution instructions
Write-Host "3️⃣ Database Clear Instructions:" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔗 Go to your Supabase Dashboard:" -ForegroundColor Cyan
Write-Host "   https://supabase.com/dashboard/project/slicsqdcgwxgfvlmnrqz" -ForegroundColor White
Write-Host ""
Write-Host "📝 Navigate to: SQL Editor > New Query" -ForegroundColor Cyan
Write-Host ""
Write-Host "🗂️  Copy and paste the contents of: clear-supabase-n8n.sql" -ForegroundColor Cyan
Write-Host "   (File is in the same directory as this script)" -ForegroundColor White
Write-Host ""
Write-Host "▶️  Click 'Run' to execute the SQL" -ForegroundColor Cyan
Write-Host ""

# Wait for user confirmation that they've executed the SQL
Read-Host "Press Enter after you've executed the SQL script in Supabase Dashboard"

# Step 4: Restart n8n container
Write-Host "4️⃣ Restarting n8n container..." -ForegroundColor Yellow
try {
    az containerapp update --name $AppName --resource-group $ResourceGroup --min-replicas 1 --max-replicas 1 | Out-Null
    Write-Host "✅ Container restarted" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to restart container: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Wait for startup
Write-Host "5️⃣ Waiting for n8n to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Step 6: Test accessibility
Write-Host "6️⃣ Testing n8n accessibility..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://n8n.assistt.in" -Method HEAD -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ n8n is accessible" -ForegroundColor Green
    } else {
        Write-Host "⚠️  n8n returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  n8n might still be starting up" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Database reset complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Go to: https://n8n.assistt.in" -ForegroundColor White
Write-Host "  2. Complete the fresh setup (this will be clean)" -ForegroundColor White
Write-Host "  3. Your data will now persist properly!" -ForegroundColor White
Write-Host ""
Write-Host "⚙️  Important: Your encryption key is preserved, so future data will persist correctly." -ForegroundColor Green