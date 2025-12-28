# PowerShell script to get SHA-1 and SHA-256 fingerprints for local (debug) and release keystores

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "SHA Fingerprint Generator for Android Keystores" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Function to get fingerprints from a keystore
function Get-KeystoreFingerprints {
    param(
        [string]$KeystorePath,
        [string]$KeystorePassword,
        [string]$KeyAlias,
        [string]$KeystoreType = "jks"
    )
    
    if (-not (Test-Path $KeystorePath)) {
        Write-Host "❌ Keystore not found at: $KeystorePath" -ForegroundColor Red
        return $null
    }
    
    Write-Host "📦 Keystore: $KeystorePath" -ForegroundColor Yellow
    Write-Host "🔑 Key Alias: $KeyAlias" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        # Get SHA-1 fingerprint
        $sha1Output = & keytool -list -v -keystore $KeystorePath -alias $KeyAlias -storepass $KeystorePassword 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Error reading keystore. Please check the password and alias." -ForegroundColor Red
            return $null
        }
        
        # Extract SHA-1
        $sha1Match = $sha1Output | Select-String -Pattern "SHA1:\s*([A-F0-9:]+)"
        $sha1 = if ($sha1Match) { $sha1Match.Matches[0].Groups[1].Value } else { "Not found" }
        
        # Extract SHA-256
        $sha256Match = $sha1Output | Select-String -Pattern "SHA256:\s*([A-F0-9:]+)"
        $sha256 = if ($sha256Match) { $sha256Match.Matches[0].Groups[1].Value } else { "Not found" }
        
        return @{
            SHA1 = $sha1
            SHA256 = $sha256
        }
    }
    catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        return $null
    }
}

# Check if keytool is available
$keytoolCheck = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytoolCheck) {
    Write-Host "❌ keytool not found. Please ensure Java JDK is installed and added to PATH." -ForegroundColor Red
    Write-Host "   You can find keytool in: C:\Program Files\Java\jdk-*\bin\keytool.exe" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ keytool found" -ForegroundColor Green
Write-Host ""

# 1. Get Debug Keystore Fingerprints (for local development)
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "1. DEBUG KEYSTORE (Local Development)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$debugKeystorePath = "$env:USERPROFILE\.android\debug.keystore"
$debugPassword = "android"
$debugAlias = "androiddebugkey"

if (Test-Path $debugKeystorePath) {
    $debugFingerprints = Get-KeystoreFingerprints -KeystorePath $debugKeystorePath -KeystorePassword $debugPassword -KeyAlias $debugAlias
    
    if ($debugFingerprints) {
        Write-Host "✅ SHA-1 Fingerprint:" -ForegroundColor Green
        Write-Host "   $($debugFingerprints.SHA1)" -ForegroundColor White
        Write-Host ""
        Write-Host "✅ SHA-256 Fingerprint:" -ForegroundColor Green
        Write-Host "   $($debugFingerprints.SHA256)" -ForegroundColor White
        Write-Host ""
    }
} else {
    Write-Host "⚠️  Debug keystore not found at: $debugKeystorePath" -ForegroundColor Yellow
    Write-Host "   This is normal if you haven't built a debug APK yet." -ForegroundColor Yellow
    Write-Host "   Run: flutter build apk --debug (or just build the app once)" -ForegroundColor Yellow
    Write-Host ""
}

# 2. Get Release Keystore Fingerprints (if configured)
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "2. RELEASE KEYSTORE (Production)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$keyPropertiesPath = "android\key.properties"
if (Test-Path $keyPropertiesPath) {
    $keyProperties = @{}
    Get-Content $keyPropertiesPath | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $keyProperties[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    
    if ($keyProperties.ContainsKey('storeFile') -and $keyProperties.ContainsKey('keyAlias')) {
        $releaseKeystorePath = $keyProperties['storeFile']
        $releasePassword = $keyProperties['storePassword']
        $releaseAlias = $keyProperties['keyAlias']
        
        # Convert Windows path separators if needed
        $releaseKeystorePath = $releaseKeystorePath -replace '\\', '\'
        
        $releaseFingerprints = Get-KeystoreFingerprints -KeystorePath $releaseKeystorePath -KeystorePassword $releasePassword -KeyAlias $releaseAlias
        
        if ($releaseFingerprints) {
            Write-Host "✅ SHA-1 Fingerprint:" -ForegroundColor Green
            Write-Host "   $($releaseFingerprints.SHA1)" -ForegroundColor White
            Write-Host ""
            Write-Host "✅ SHA-256 Fingerprint:" -ForegroundColor Green
            Write-Host "   $($releaseFingerprints.SHA256)" -ForegroundColor White
            Write-Host ""
        }
    } else {
        Write-Host "⚠️  key.properties file found but missing required fields." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  key.properties file not found. Skipping release keystore." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📋 Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "For Firebase setup, use the DEBUG keystore fingerprints for development." -ForegroundColor White
Write-Host "Add these fingerprints to Firebase Console > Project Settings > Your Android App" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")







