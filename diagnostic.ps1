# PowerShell Diagnostic Script for X-UI

Write-Host "Running X-UI Diagnostics" -ForegroundColor Green
Write-Host "============================="

# Check if x-ui is running
Write-Host "Checking if x-ui is running..." -ForegroundColor Yellow
$processes = Get-Process | Where-Object { $_.ProcessName -like "*x-ui*" }
if ($processes) {
    Write-Host "X-UI is running" -ForegroundColor Green
    foreach ($process in $processes) {
        Write-Host "Process ID: $($process.Id)"
    }
} else {
    Write-Host "X-UI is not running" -ForegroundColor Red
}

# Check database
Write-Host "Checking database..." -ForegroundColor Yellow
$defaultDbPath = "C:\etc\x-ui\x-ui.db"
if (Test-Path $defaultDbPath) {
    Write-Host "Database exists at $defaultDbPath" -ForegroundColor Green
    Get-Item $defaultDbPath | Format-List
} else {
    Write-Host "Database not found at default location" -ForegroundColor Red
    # Try to find it elsewhere
    Write-Host "Searching for database file (this may take a while)..." -ForegroundColor Yellow
    $dbPaths = Get-ChildItem -Path C:\ -Filter "x-ui.db" -Recurse -ErrorAction SilentlyContinue
    if ($dbPaths) {
        foreach ($path in $dbPaths) {
            Write-Host "Found database at alternative location: $($path.FullName)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Could not find database file" -ForegroundColor Red
    }
}

# Check ports
Write-Host "Checking web interface port..." -ForegroundColor Yellow
$netstatOutput = netstat -ano | Select-String -Pattern "(54321|443)"
if ($netstatOutput) {
    Write-Host $netstatOutput
} else {
    Write-Host "No processes found listening on ports 54321 or 443" -ForegroundColor Red
}

# Check CGO status
Write-Host "Checking CGO status..." -ForegroundColor Yellow
$goEnv = & go env | Select-String -Pattern "CGO_ENABLED"
if ($goEnv) {
    Write-Host $goEnv
    if ($goEnv -like "*CGO_ENABLED=`"0`"*") {
        Write-Host "Warning: CGO_ENABLED is set to 0, which will cause issues with SQLite" -ForegroundColor Red
        Write-Host "To fix this, you need to set CGO_ENABLED=1 before building the application" -ForegroundColor Yellow
    }
} else {
    Write-Host "Could not determine CGO_ENABLED status" -ForegroundColor Red
}

Write-Host "Diagnostic completed" -ForegroundColor Green
Write-Host "For more detailed logging, run x-ui with verbose logging enabled" 