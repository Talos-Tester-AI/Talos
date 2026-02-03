# Talos Install & Run Script
# Works on Windows (PowerShell)

Write-Host "Talos Install & Run Script (Windows)" -ForegroundColor Cyan

# 1. Prerequisite Checks
Write-Host "Checking prerequisites..." -ForegroundColor Blue

if (!(Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Node.js is not installed. Please install Node.js (v18+ recommended)." -ForegroundColor Red
    exit 1
}

if (!(Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Python is not installed. Please install Python 3.9+." -ForegroundColor Red
    exit 1
}

if (!(Get-Command "adb" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] ADB (Android Debug Bridge) is not installed. Please install Android Platform Tools." -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Prerequisites met." -ForegroundColor Green

# 2. Setup and Clone Repositories
$defaultInstallDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$installDir = Read-Host -Prompt "[?] Where should other components be installed? (Default: $defaultInstallDir)"

if ([string]::IsNullOrWhiteSpace($installDir)) {
    $installDir = $defaultInstallDir
}

# Resolve absolute path
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}
$installDirAbs = Resolve-Path $installDir
Write-Host "Using installation directory: $installDirAbs" -ForegroundColor Blue

function Ensure-Repo {
    param (
        [string]$Name,
        [string]$Url
    )
    $targetPath = Join-Path $installDirAbs $Name
    if (!(Test-Path $targetPath)) {
        Write-Host "Cloning $Name..." -ForegroundColor Blue
        git clone $Url $targetPath
    } else {
        Write-Host "$Name already exists." -ForegroundColor Blue
    }
}

Ensure-Repo -Name "talos-agent" -Url "https://github.com/Talos-Tester-AI/talos-agent.git"
Ensure-Repo -Name "talos-cli" -Url "https://github.com/Talos-Tester-AI/talos-ai.git"

# 3. Setup and Run Talos Agent
$agentDir = Join-Path $installDirAbs "talos-agent"
if (!(Test-Path $agentDir)) {
    Write-Host "[ERROR] Directory $agentDir not found even after clone attempt!" -ForegroundColor Red
    exit 1
}

Write-Host "Setting up Talos Agent..." -ForegroundColor Blue
Push-Location $agentDir

# Create venv if needed
if (!(Test-Path "venv")) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Blue
    python -m venv venv
} else {
    Write-Host "Using existing virtual environment." -ForegroundColor Blue
}

# Activate venv and install dependencies
# We can't easily "source" a script in PS and keep env vars for the current session in the same intuitive way as bash for subshells,
# but we can call the pip/python inside the scripts dir directly.
$venvPython = ".\venv\Scripts\python.exe"
$venvPip = ".\venv\Scripts\pip.exe"

if (!(Test-Path $venvPython)) {
     Write-Host "[ERROR] Virtual environment python not found at $venvPython" -ForegroundColor Red
     Pop-Location
     exit 1
}

Write-Host "Installing agent dependencies..." -ForegroundColor Blue
& $venvPip install -r requirements.txt | Out-Null

# Start Agent in background
Write-Host "Starting Talos Agent in background..." -ForegroundColor Blue
# Start-Process allows us to run it detached. We use -PassThru to get the object back.
# We redirect output to a log file.
$agentProcess = Start-Process -FilePath $venvPython -ArgumentList "main.py" -RedirectStandardOutput "agent.log" -RedirectStandardError "agent.log" -PassThru -WindowStyle Hidden

Write-Host "[SUCCESS] Talos Agent started (PID: $($agentProcess.Id)). Logs: $agentDir\agent.log" -ForegroundColor Green

Pop-Location

# 4. Setup and Run Talos CLI
$cliDir = Join-Path $installDirAbs "talos-cli"
if (!(Test-Path $cliDir)) {
    Write-Host "[ERROR] Directory $cliDir not found!" -ForegroundColor Red
    Stop-Process -Id $agentProcess.Id -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Setting up Talos CLI..." -ForegroundColor Blue
Push-Location $cliDir

try {
    if (!(Test-Path "node_modules")) {
        Write-Host "Installing CLI dependencies (this may take a while)..." -ForegroundColor Blue
        npm install
    } else {
         Write-Host "Checking CLI dependencies..." -ForegroundColor Blue
         npm install
    }

    Write-Host "Starting Talos CLI..." -ForegroundColor Blue
    Write-Host "Press Ctrl+C to stop both Agent and CLI." -ForegroundColor Yellow
    
    # Run npm run dev. This blocks until the user stops it.
    npm run dev
}
finally {
    # Cleanup
    Write-Host "Stopping Talos Agent (PID: $($agentProcess.Id))..." -ForegroundColor Blue
    Stop-Process -Id $agentProcess.Id -ErrorAction SilentlyContinue
    Write-Host "[SUCCESS] Talos Agent stopped." -ForegroundColor Green
    Pop-Location
}
