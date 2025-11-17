# Fix Agora CMakeLists.txt to use shared C++ library instead of static
# This fixes the C++ linking errors with NDK 27

Write-Host "🔧 Fixing Agora SDK CMakeLists.txt files..." -ForegroundColor Cyan

# Find Agora package directory
$agoraPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\agora_rtc_engine-6.2.4\android"
$irisPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\iris_method_channel-2.0.0-dev.3\android"

# Check if Agora directory exists
if (!(Test-Path $agoraPath)) {
    Write-Host "❌ Agora package not found! Run 'flutter pub get' first." -ForegroundColor Red
    exit 1
}

# Fix Agora CMakeLists.txt
$agoraCMake = "$agoraPath\CMakeLists.txt"
if (Test-Path $agoraCMake) {
    Write-Host "📝 Patching $agoraCMake" -ForegroundColor Yellow
    
    $content = Get-Content $agoraCMake -Raw
    $content = $content -replace '-static-libstdc\+\+', ''
    $content = $content -replace 'set\(CMAKE_CXX_FLAGS "\$\{CMAKE_CXX_FLAGS\} -static-libstdc\+\+"\)', 'set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")'
    
    # Add shared C++ library
    if ($content -notmatch 'ANDROID_STL') {
        $content = "set(ANDROID_STL c++_shared)`n" + $content
    }
    
    Set-Content $agoraCMake -Value $content
    Write-Host "✅ Fixed Agora CMakeLists.txt" -ForegroundColor Green
}

# Fix Iris CMakeLists.txt
$irisCMake = "$irisPath\CMakeLists.txt"
if (Test-Path $irisCMake) {
    Write-Host "📝 Patching $irisCMake" -ForegroundColor Yellow
    
    $content = Get-Content $irisCMake -Raw
    $content = $content -replace '-static-libstdc\+\+', ''
    $content = $content -replace 'set\(CMAKE_CXX_FLAGS "\$\{CMAKE_CXX_FLAGS\} -static-libstdc\+\+"\)', 'set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")'
    
    # Add shared C++ library
    if ($content -notmatch 'ANDROID_STL') {
        $content = "set(ANDROID_STL c++_shared)`n" + $content
    }
    
    Set-Content $irisCMake -Value $content
    Write-Host "✅ Fixed Iris CMakeLists.txt" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 All CMakeLists.txt files patched!" -ForegroundColor Green
Write-Host "📋 Now run: flutter run" -ForegroundColor Cyan












