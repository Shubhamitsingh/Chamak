# PowerShell script to set Agora secrets in Firebase Functions
# Run this script from the project root directory

Write-Host "Setting Agora secrets for Firebase Functions..." -ForegroundColor Green

# Set App ID
Write-Host "`nSetting AGORA_APP_ID..." -ForegroundColor Yellow
echo "43bb5e13c835444595c8cf087a0ccaa4" | firebase functions:secrets:set AGORA_APP_ID

# Set Primary Certificate
Write-Host "`nSetting AGORA_APP_CERTIFICATE..." -ForegroundColor Yellow
echo "e1c46db9ee1e4e049a1c36943d87fd09" | firebase functions:secrets:set AGORA_APP_CERTIFICATE

Write-Host "`n✅ Secrets set successfully!" -ForegroundColor Green
Write-Host "`nNext step: Deploy Firebase Functions" -ForegroundColor Cyan
Write-Host "Run: firebase deploy --only functions" -ForegroundColor Cyan
























