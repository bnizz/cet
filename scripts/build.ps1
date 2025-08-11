# Build script for CET DLL
# Builds the consolidated Chat Event Trigger DLL

param(
    [string]$Configuration = "Release",
    [string]$Platform = "Win32",
    [switch]$Clean = $false
)

# Set up paths
$scriptPath = $PSScriptRoot
$dllPath = Join-Path $scriptPath ".."
$buildPath = Join-Path $dllPath "build"

Write-Host "=== CET DLL Build Script ===" -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Platform: $Platform" -ForegroundColor Yellow
Write-Host "DLL Path: $dllPath" -ForegroundColor Yellow
Write-Host "Build Path: $buildPath" -ForegroundColor Yellow

# Navigate to DLL directory
Push-Location $dllPath

try {
    # Clean if requested
    if ($Clean -and (Test-Path $buildPath)) {
        Write-Host "Cleaning build directory..." -ForegroundColor Cyan
        Remove-Item -Recurse -Force $buildPath
    }

    # Create build directory
    if (-not (Test-Path $buildPath)) {
        Write-Host "Creating build directory..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $buildPath | Out-Null
    }

    # Navigate to build directory
    Set-Location $buildPath

    # Check for MinHook library
    $minhookPath = Join-Path $dllPath "third_party"
    if (Test-Path $minhookPath) {
        $minhookLib = if ($Platform -eq "x64") { 
            Join-Path $minhookPath "MinHook.x64.lib" 
        } else { 
            Join-Path $minhookPath "MinHook.x86.lib" 
        }
        
        if (Test-Path $minhookLib) {
            Write-Host "MinHook library found: $minhookLib" -ForegroundColor Green
        } else {
            Write-Warning "MinHook library not found: $minhookLib"
            Write-Host "Download from: https://github.com/TsudaKageyu/minhook/releases" -ForegroundColor Yellow
        }
    } else {
        Write-Warning "MinHook directory not found. Function hooking may not work."
    }

    # Configure with CMake
    Write-Host "Configuring with CMake..." -ForegroundColor Cyan
    $cmakeArgs = @(
        ".."
        "-G", "Visual Studio 16 2019"
        "-A", "Win32"  # Force 32-bit for WoW compatibility
    )
    
    $cmakeProcess = Start-Process -FilePath "cmake" -ArgumentList $cmakeArgs -Wait -NoNewWindow -PassThru
    
    if ($cmakeProcess.ExitCode -ne 0) {
        throw "CMake configuration failed with exit code $($cmakeProcess.ExitCode)"
    }

    # Build with CMake
    Write-Host "Building CET.dll..." -ForegroundColor Cyan
    $buildArgs = @(
        "--build", "."
        "--config", $Configuration
        "--verbose"
    )
    
    $buildProcess = Start-Process -FilePath "cmake" -ArgumentList $buildArgs -Wait -NoNewWindow -PassThru
    
    if ($buildProcess.ExitCode -ne 0) {
        throw "Build failed with exit code $($buildProcess.ExitCode)"
    }

    # Check if DLL was created
    $dllOutputPath = Join-Path $buildPath "bin\$Configuration\CET.dll"
    if (Test-Path $dllOutputPath) {
        Write-Host "Build successful!" -ForegroundColor Green
        Write-Host "CET.dll created at: $dllOutputPath" -ForegroundColor Green
        
        # Show file info
        $dllInfo = Get-Item $dllOutputPath
        Write-Host "File size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "Created: $($dllInfo.CreationTime)" -ForegroundColor Cyan
    } else {
        throw "Build completed but CET.dll not found at expected location: $dllOutputPath"
    }

} catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    exit 1
} finally {
    Pop-Location
}

Write-Host "=== Build Complete ===" -ForegroundColor Green
