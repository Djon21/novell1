param(
    [string]$BobVersion = "1.11.0",
    [switch]$NoDownload
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BobJar = Join-Path $ProjectRoot "scripts\bob.jar"
$BuildDir = Join-Path $ProjectRoot "build\bob"

# Java check
cmd /c "java -version >nul 2>nul"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Java not found. Install Java 17+ from https://adoptium.net" -ForegroundColor Red
    exit 1
}

# Download bob.jar
if (-not (Test-Path -LiteralPath $BobJar) -and -not $NoDownload) {
    $url = "https://github.com/defold/defold/releases/download/v$BobVersion/bob.jar"
    Write-Host "Downloading bob.jar v$BobVersion ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $BobJar -UseBasicParsing
        Write-Host "  -> $BobJar" -ForegroundColor Green
    } catch {
        Write-Host "Failed: $url" -ForegroundColor Red
        Write-Host "Download manually:" -ForegroundColor Yellow
        Write-Host "  https://github.com/defold/defold/releases/tag/v$BobVersion" -ForegroundColor Yellow
        exit 1
    }
} elseif (-not (Test-Path -LiteralPath $BobJar)) {
    Write-Host "bob.jar not found at $BobJar" -ForegroundColor Red
    exit 1
}

# Build
Write-Host "=== bob resolve + build ===" -ForegroundColor Cyan
& java -jar $BobJar --root $ProjectRoot --output $BuildDir resolve build

if ($LASTEXITCODE -eq 0) {
    Write-Host "BUILD OK" -ForegroundColor Green
} else {
    Write-Host "BUILD FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}
