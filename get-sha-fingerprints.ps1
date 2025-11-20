# PowerShell Script to Get SHA Fingerprints
# Run this script to get your SHA-1 and SHA-256 fingerprints

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Getting SHA Fingerprints for Firebase" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Java is installed
$javaPath = Get-Command java -ErrorAction SilentlyContinue

if (-not $javaPath) {
    Write-Host "❌ Java is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Java JDK or use one of these methods:" -ForegroundColor Yellow
    Write-Host "1. Install Java JDK from: https://adoptium.net/" -ForegroundColor Yellow
    Write-Host "2. Use Android Studio (recommended):" -ForegroundColor Yellow
    Write-Host "   - Open Android Studio" -ForegroundColor Yellow
    Write-Host "   - Open project: chamak/android" -ForegroundColor Yellow
    Write-Host "   - Gradle → app → Tasks → android → signingReport" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "3. Or use Flutter build command:" -ForegroundColor Yellow
    Write-Host "   flutter build apk --debug" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "✅ Java found!" -ForegroundColor Green
Write-Host ""

# Get debug keystore path
$keystorePath = "$env:USERPROFILE\.android\debug.keystore"

if (-not (Test-Path $keystorePath)) {
    Write-Host "❌ Debug keystore not found at: $keystorePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "The debug keystore will be created automatically when you:" -ForegroundColor Yellow
    Write-Host "1. Build your Flutter app for the first time, OR" -ForegroundColor Yellow
    Write-Host "2. Run: flutter build apk --debug" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "✅ Debug keystore found!" -ForegroundColor Green
Write-Host "Location: $keystorePath" -ForegroundColor Gray
Write-Host ""

# Get SHA fingerprints
Write-Host "Getting SHA fingerprints..." -ForegroundColor Cyan
Write-Host ""

try {
    $output = keytool -list -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android 2>&1
    
    # Extract SHA-1
    $sha1Match = $output | Select-String -Pattern "SHA1:\s+([A-F0-9:]+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    
    # Extract SHA-256
    $sha256Match = $output | Select-String -Pattern "SHA256:\s+([A-F0-9:]+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    
    if ($sha1Match -and $sha256Match) {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  ✅ SHA Fingerprints Found!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "SHA-1:" -ForegroundColor Yellow
        Write-Host $sha1Match -ForegroundColor White
        Write-Host ""
        Write-Host "SHA-256:" -ForegroundColor Yellow
        Write-Host $sha256Match -ForegroundColor White
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Next Steps:" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Copy both SHA fingerprints above" -ForegroundColor Yellow
        Write-Host "2. Go to Firebase Console:" -ForegroundColor Yellow
        Write-Host "   https://console.firebase.google.com/project/chamak-39472/settings/general" -ForegroundColor Cyan
        Write-Host "3. Scroll to 'Your apps' → Android app (com.chamak.app)" -ForegroundColor Yellow
        Write-Host "4. Click 'Add fingerprint' → Paste SHA-1 → Save" -ForegroundColor Yellow
        Write-Host "5. Click 'Add fingerprint' → Paste SHA-256 → Save" -ForegroundColor Yellow
        Write-Host "6. Download new google-services.json" -ForegroundColor Yellow
        Write-Host "7. Replace: android/app/google-services.json" -ForegroundColor Yellow
        Write-Host ""
        
        # Save to file
        $fingerprintsFile = "SHA_FINGERPRINTS.txt"
        @"
SHA Fingerprints for Firebase Console
Generated: $(Get-Date)

SHA-1:
$sha1Match

SHA-256:
$sha256Match

Next Steps:
1. Go to Firebase Console → Project Settings
2. Add both SHA fingerprints
3. Download new google-services.json
4. Replace android/app/google-services.json
"@ | Out-File -FilePath $fingerprintsFile -Encoding UTF8
        
        Write-Host "✅ Fingerprints saved to: $fingerprintsFile" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "❌ Could not extract SHA fingerprints from output" -ForegroundColor Red
        Write-Host ""
        Write-Host "Full output:" -ForegroundColor Yellow
        Write-Host $output -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Error getting SHA fingerprints: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try using Android Studio instead:" -ForegroundColor Yellow
    Write-Host "Gradle → app → Tasks → android → signingReport" -ForegroundColor Yellow
}


