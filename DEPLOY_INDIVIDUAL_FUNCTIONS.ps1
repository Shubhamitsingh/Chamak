# Individual Function Deployment Commands
# Run these commands one at a time in PowerShell
# 
# VERIFIED: All function names are correct:
# - reconcilePayments (line 1299 in functions/index.js)
# - sendChatNotification (line 323 in functions/index.js)
# - sendLiveStreamNotification (line 1911 in functions/index.js)

# Navigate to project directory first
cd "C:\Users\Shubham Singh\Desktop\chamak"

# Function 1: reconcilePayments
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deploying reconcilePayments..." -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan
firebase deploy --only functions:reconcilePayments

# Function 2: sendChatNotification
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deploying sendChatNotification..." -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan
firebase deploy --only functions:sendChatNotification

# Function 3: sendLiveStreamNotification
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deploying sendLiveStreamNotification..." -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan
firebase deploy --only functions:sendLiveStreamNotification

# After all deployments, verify
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Checking deployed functions..." -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
firebase functions:list
