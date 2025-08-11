# CET (Chat Event Trigger) Setup Script
# Automates the complete setup of the Chat Event Trigger solution

param(
    [string]$WoWPath = "",
    [string]$Configuration = "Release",
    [switch]$SkipBuild = $false,
    [switch]$SkipDeploy = $false,
    [switch]$Clean = $false
)

Write-Host @"
=======================================================
    Chat Event Trigger (CET) - Setup Script
=======================================================
"@ -ForegroundColor Green

# Get WoW path if not provided
if ([string]::IsNullOrEmpty($WoWPath) -and -not $SkipDeploy) {
    Write-Host "Please provide the path to your World of Warcraft installation:" -ForegroundColor Yellow
    $WoWPath = Read-Host "WoW Path"
    
    if ([string]::IsNullOrEmpty($WoWPath)) {
        Write-Warning "No WoW path provided. Deployment will be skipped."
        $SkipDeploy = $true
    }
}

# Set up paths
$scriptPath = $PSScriptRoot
$buildScriptPath = Join-Path $scriptPath "build.ps1"
$deployScriptPath = Join-Path $scriptPath "deploy.ps1"

Write-Host "Configuration: $Configuration" -ForegroundColor Cyan
Write-Host "WoW Path: $WoWPath" -ForegroundColor Cyan
Write-Host "Skip Build: $SkipBuild" -ForegroundColor Cyan
Write-Host "Skip Deploy: $SkipDeploy" -ForegroundColor Cyan

try {
    # Step 1: Build the DLL
    if (-not $SkipBuild) {
        Write-Host "`n=== Step 1: Building CET DLL ===" -ForegroundColor Yellow
        
        $buildArgs = @(
            "-Configuration", $Configuration
            "-Platform", "Win32"
        )
        
        if ($Clean) {
            $buildArgs += "-Clean"
        }
        
        & $buildScriptPath @buildArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed with exit code $LASTEXITCODE"
        }
        
        Write-Host "DLL build completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n=== Step 1: Skipping DLL Build ===" -ForegroundColor Yellow
    }
    
    # Step 2: Deploy to WoW
    if (-not $SkipDeploy) {
        Write-Host "`n=== Step 2: Deploying to WoW ===" -ForegroundColor Yellow
        
        $deployArgs = @{
            WoWPath = $WoWPath
            Configuration = $Configuration
        }
        
        if ($SkipBuild) {
            $deployArgs.SkipDLL = $true
        }
        
        & $deployScriptPath @deployArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Deployment failed with exit code $LASTEXITCODE"
        }
        
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n=== Step 2: Skipping Deployment ===" -ForegroundColor Yellow
    }
    
    # Step 3: Display final instructions
    Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
    
    if (-not $SkipDeploy) {
        Write-Host @"

🎉 CET has been successfully installed to your WoW directory!

📋 Quick Start Guide:
1. Launch World of Warcraft
2. Load any character
3. Set your Google Translate API key:
   /cet apikey YOUR_API_KEY_HERE
   
4. Configure translation (example Chinese to English):
   /cet direction zh en
   
5. Enable chat channels you want to translate:
   /cet toggle say
   /cet toggle guild
   /cet toggle whisper
   
6. Test the connection:
   /cet test
   
7. Open the configuration UI:
   /cetui

📖 For detailed documentation, see README.md

🔧 Available Commands:
   /cet status     - Show current settings
   /cet help       - Show all commands
   /cetui          - Open configuration window

"@ -ForegroundColor White
    } else {
        Write-Host @"

⚠️  Build completed but not deployed.

To deploy manually:
1. Copy the built CET.dll to your WoW directory
2. Copy the addon folder to Interface/AddOns/CET/
3. Follow the quick start guide above

"@ -ForegroundColor Yellow
    }
    
    Write-Host "Need help? Check the README.md for detailed instructions and troubleshooting." -ForegroundColor Cyan

} catch {
    Write-Host "`n❌ Setup failed!" -ForegroundColor Red
    Write-Error $_.Exception.Message
    exit 1
}

Write-Host "`n✅ CET setup completed successfully!" -ForegroundColor Green
