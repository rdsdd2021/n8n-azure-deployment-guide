# Reset n8n Database in Supabase
# This script will clear all n8n tables and restart the container

param(
    [string]$ResourceGroup = "n8n-free-rg",
    [string]$AppName = "n8n-app"
)

Write-Host "n8n Database Reset Script" -ForegroundColor Red
Write-Host "=========================" -ForegroundColor Red
Write-Host ""
Write-Host "WARNING: This will PERMANENTLY DELETE all n8n data!" -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Type 'DELETE' to confirm you want to clear all data"
if ($response -ne "DELETE") {
    Write-Host "Operation cancelled" -ForegroundColor Green
    exit
}

Write-Host "Starting database reset process..." -ForegroundColor Cyan

# Step 1: Stop the n8n container
Write-Host "1. Scaling down n8n container..." -ForegroundColor Yellow
az containerapp update --name $AppName --resource-group $ResourceGroup --min-replicas 0 --max-replicas 0

# Step 2: Wait for container to stop
Write-Host "2. Waiting for container to stop..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 3: Manual SQL execution instructions
Write-Host "3. Database Clear Instructions:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Go to your Supabase Dashboard:" -ForegroundColor Cyan
Write-Host "https://supabase.com/dashboard/project/slicsqdcgwxgfvlmnrqz"
Write-Host ""
Write-Host "Navigate to: SQL Editor > New Query" -ForegroundColor Cyan
Write-Host ""
Write-Host "Copy and paste the contents of: clear-supabase-n8n.sql" -ForegroundColor Cyan
Write-Host ""
Write-Host "Click 'Run' to execute the SQL" -ForegroundColor Cyan
Write-Host ""

# Wait for user confirmation
Read-Host "Press Enter after you have executed the SQL script in Supabase Dashboard"

# Step 4: Restart n8n container
Write-Host "4. Restarting n8n container..." -ForegroundColor Yellow
az containerapp update --name $AppName --resource-group $ResourceGroup --min-replicas 1 --max-replicas 1

# Step 5: Wait for startup
Write-Host "5. Waiting for n8n to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "Database reset complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Go to: https://n8n.assistt.in"
Write-Host "2. Complete the fresh setup"
Write-Host "3. Your data will now persist properly!"