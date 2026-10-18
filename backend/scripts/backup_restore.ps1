# ==============================================================================
# UniCheck - Database Backup and Restore Utility Script
# Target: PostgreSQL 15 / 18
# ==============================================================================

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("backup", "restore")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Database = "unicheck_clean_test",

    [Parameter(Mandatory = $false)]
    [string]$HostName = "localhost",

    [Parameter(Mandatory = $false)]
    [int]$Port = 5432,

    [Parameter(Mandatory = $false)]
    [string]$Username = "unicheck_user",

    [Parameter(Mandatory = $false)]
    [string]$Password = "unicheck_secret_password",

    [Parameter(Mandatory = $false)]
    [string]$FilePath = ""
)

$ErrorActionPreference = "Stop"

# 1. Resolve PostgreSQL binary directory
function Get-PgBinPath {
    param([string]$BinaryName)
    $cmd = Get-Command $BinaryName -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $commonPaths = @(
        "C:\Program Files\PostgreSQL\18\bin\$BinaryName.exe",
        "C:\Program Files\PostgreSQL\17\bin\$BinaryName.exe",
        "C:\Program Files\PostgreSQL\16\bin\$BinaryName.exe",
        "C:\Program Files\PostgreSQL\15\bin\$BinaryName.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    throw "PostgreSQL binary '$BinaryName' could not be found in PATH or standard installation directories."
}

$pgDumpPath = Get-PgBinPath "pg_dump"
$psqlPath = Get-PgBinPath "psql"

# Set credentials in environment for pg tools
$env:PGPASSWORD = $Password

# Default backup directory
$backupDir = Join-Path $PSScriptRoot "..\backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

if ($Action -eq "backup") {
    if (-not $FilePath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $FilePath = Join-Path $backupDir "unicheck_backup_${Database}_${timestamp}.sql"
    }

    Write-Host "[UniCheck Backup] Starting backup for database '$Database' at ${HostName}:${Port}..." -ForegroundColor Cyan
    Write-Host "[UniCheck Backup] Using pg_dump: $pgDumpPath" -ForegroundColor Gray
    Write-Host "[UniCheck Backup] Output file: $FilePath" -ForegroundColor Gray

    & $pgDumpPath -h $HostName -p $Port -U $Username -d $Database --clean --if-exists --no-owner --no-privileges --file=$FilePath
    
    if ($LASTEXITCODE -ne 0) {
        throw "pg_dump failed with exit code $LASTEXITCODE"
    }

    $fileItem = Get-Item $FilePath
    Write-Host "[UniCheck Backup] SUCCESS! Backup saved ($($fileItem.Length) bytes)." -ForegroundColor Green
    return $FilePath
}
elseif ($Action -eq "restore") {
    if (-not $FilePath) {
        # Find latest backup file in directory
        $latest = Get-ChildItem -Path $backupDir -Filter "*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $latest) {
            throw "No backup file specified and no backup file found in $backupDir"
        }
        $FilePath = $latest.FullName
    }

    if (-not (Test-Path $FilePath)) {
        throw "Backup file '$FilePath' does not exist."
    }

    Write-Host "[UniCheck Restore] Starting restore to database '$Database' from '$FilePath'..." -ForegroundColor Cyan
    Write-Host "[UniCheck Restore] Using psql: $psqlPath" -ForegroundColor Gray

    & $psqlPath -h $HostName -p $Port -U $Username -d $Database -q -f $FilePath
    
    if ($LASTEXITCODE -ne 0) {
        throw "psql restore failed with exit code $LASTEXITCODE"
    }

    Write-Host "[UniCheck Restore] SUCCESS! Database '$Database' restored successfully." -ForegroundColor Green
}
