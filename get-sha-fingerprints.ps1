# Get SHA Fingerprints for Firebase
# This script will help you get SHA-1 and SHA-256 fingerprints

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Getting SHA Fingerprints for Firebase" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Method 1: Try to find Java and use keytool
$javaPaths = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "C:\Program Files\Java\*\bin\keytool.exe",
    "C:\Program Files (x86)\Java\*\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\Sdk\jbr\bin\keytool.exe"
)

$keytoolPath = $null
foreach ($path in $javaPaths) {
    $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $keytoolPath = $found.FullName
        break
    }
}

if ($keytoolPath) {
    Write-Host "✅ Found keytool at: $keytoolPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Getting Debug Keystore SHA Fingerprints..." -ForegroundColor Yellow
    Write-Host ""
    
    $debugKeystore = "$env:USERPROFILE\.android\debug.keystore"
    
    if (Test-Path $debugKeystore) {
        Write-Host "Debug Keystore Location: $debugKeystore" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "SHA Fingerprints:" -ForegroundColor Yellow
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        & $keytoolPath -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android 2>&1 | Select-String -Pattern "SHA1:|SHA256:" | ForEach-Object {
            $line = $_.Line.Trim()
            Write-Host $line -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "Full Certificate Info:" -ForegroundColor Yellow
        & $keytoolPath -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android
    } else {
        Write-Host "❌ Debug keystore not found at: $debugKeystore" -ForegroundColor Red
        Write-Host "Creating debug keystore..." -ForegroundColor Yellow
        
        # Create debug keystore directory if it doesn't exist
        $androidDir = "$env:USERPROFILE\.android"
        if (-not (Test-Path $androidDir)) {
            New-Item -ItemType Directory -Path $androidDir -Force | Out-Null
        }
        
        Write-Host "Please run Flutter build first to create debug keystore:" -ForegroundColor Yellow
        Write-Host "  flutter build apk --debug" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ keytool not found in common locations" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative Methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Method 1: Use Flutter to get SHA" -ForegroundColor Cyan
    Write-Host "  flutter build apk --debug" -ForegroundColor White
    Write-Host "  (Check build output for SHA fingerprints)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Method 2: Find Java installation" -ForegroundColor Cyan
    Write-Host "  Java is usually at:" -ForegroundColor White
    Write-Host "    C:\Program Files\Java\jdk-*\bin\keytool.exe" -ForegroundColor Gray
    Write-Host "    or" -ForegroundColor Gray
    Write-Host "    C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Method 3: Use Android Studio" -ForegroundColor Cyan
    Write-Host "  1. Open Android Studio" -ForegroundColor White
    Write-Host "  2. Open your project" -ForegroundColor White
    Write-Host "  3. Gradle → Tasks → android → signingReport" -ForegroundColor White
    Write-Host "  4. Run signingReport" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Copy SHA-1 and SHA-256 from above" -ForegroundColor White
Write-Host "2. Go to Firebase Console" -ForegroundColor White
Write-Host "3. Project Settings → Your apps → com.chamakz.app" -ForegroundColor White
Write-Host "4. Add fingerprint → Paste SHA-1" -ForegroundColor White
Write-Host "5. Add fingerprint → Paste SHA-256" -ForegroundColor White
Write-Host "6. Download updated google-services.json" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
