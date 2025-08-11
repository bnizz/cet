# Deployment script for CET
# Deploys the CET addon and DLL to WoW directory

param(
    [string]$WoWPath = "C:\Users\user\AppData\Local\TurtleWoW",
    [string]$Configuration = "Release",
    [switch]$SkipDLL = $false
)

# Validate WoW path
if (-not (Test-Path $WoWPath)) {
    Write-Error "WoW directory not found: $WoWPath"
    exit 1
}

# Validate it's a WoW directory
$wowExe = Join-Path $WoWPath "WoW.exe"
if (-not (Test-Path $wowExe)) {
    Write-Error "WoW.exe not found in specified directory. Please provide the path to your WoW installation."
    exit 1
}

Write-Host "=== CET Deployment Script ===" -ForegroundColor Green
Write-Host "WoW Path: $WoWPath" -ForegroundColor Yellow
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow

# Set up paths
$scriptPath = $PSScriptRoot
$projectPath = Join-Path $scriptPath ".."
$addonSourcePath = Join-Path $projectPath "addon"
$dllSourcePath = Join-Path $projectPath "dll\build\bin\$Configuration\CET.dll"

$addonTargetPath = Join-Path $WoWPath "Interface\AddOns\CET"
$dllTargetPath = Join-Path $WoWPath "CET.dll"

try {
    # Deploy DLL
    if (-not $SkipDLL) {
        if (Test-Path $dllSourcePath) {
            Write-Host "Deploying CET.dll..." -ForegroundColor Cyan
            Copy-Item $dllSourcePath $dllTargetPath -Force
            
            $dllInfo = Get-Item $dllTargetPath
            Write-Host "CET.dll deployed successfully" -ForegroundColor Green
            Write-Host "File size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
        } else {
            Write-Warning "CET.dll not found at: $dllSourcePath"
            Write-Host "Run build script first or use -SkipDLL to deploy only addon files" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Skipping DLL deployment as requested" -ForegroundColor Yellow
    }

    # Create addon directory
    if (Test-Path $addonTargetPath) {
        Write-Host "Removing existing CET addon..." -ForegroundColor Cyan
        Remove-Item -Recurse -Force $addonTargetPath
    }

    Write-Host "Creating addon directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $addonTargetPath -Force | Out-Null

    # Deploy addon files
    Write-Host "Deploying addon files..." -ForegroundColor Cyan
    
    $addonFiles = @(
        "CET.toc",
        "CETDefaults.lua",
        "CETVars.lua", 
        "CET.lua",
        "CETUI.lua",
        "CETUI.xml"
    )

    foreach ($file in $addonFiles) {
        $sourcePath = Join-Path $addonSourcePath $file
        $targetPath = Join-Path $addonTargetPath $file
        
        if (Test-Path $sourcePath) {
            Copy-Item $sourcePath $targetPath -Force
            Write-Host "  Copied: $file" -ForegroundColor Green
        } else {
            Write-Warning "  Missing: $file"
        }
    }

    # Verify deployment
    Write-Host "`nVerifying deployment..." -ForegroundColor Cyan
    
    # Check addon files
    $missingFiles = @()
    foreach ($file in $addonFiles) {
        $targetPath = Join-Path $addonTargetPath $file
        if (-not (Test-Path $targetPath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-Host "All addon files deployed successfully!" -ForegroundColor Green
    } else {
        Write-Warning "Missing addon files: $($missingFiles -join ', ')"
    }
    
    # Check DLL
    if (-not $SkipDLL) {
        if (Test-Path $dllTargetPath) {
            Write-Host "CET.dll deployed successfully!" -ForegroundColor Green
        } else {
            Write-Warning "CET.dll deployment failed!"
        }
    }

    # Display final instructions
    Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Start World of Warcraft" -ForegroundColor White
    Write-Host "2. Load a character" -ForegroundColor White
    Write-Host "3. Set your API key: /cet apikey YOUR_API_KEY" -ForegroundColor White
    Write-Host "4. Configure translation: /cet direction zh en" -ForegroundColor White
    Write-Host "5. Enable channels: /cet toggle say" -ForegroundColor White
    Write-Host "6. Open UI: /cetui" -ForegroundColor White
    
    if ($SkipDLL) {
        Write-Host "`nNote: You skipped DLL deployment. Make sure CET.dll is available for the addon to work properly." -ForegroundColor Yellow
    }

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
