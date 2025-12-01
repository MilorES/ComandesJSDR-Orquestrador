#!/usr/bin/env pwsh
# Ús: .\build-and-deploy.ps1 [-NoCache]
# Script per construir i desplegar ComandesJSDR

param(
    [switch]$NoCache = $false
)

Write-Host "ComandesJSDR - Script de Construcció i Desplegament" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que existeix .env
if (-not (Test-Path ".env")) {
    Write-Host "Fitxer .env no trobat. Creant des de .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "Fitxer .env creat. Revisa la configuració abans de continuar." -ForegroundColor Green
    Write-Host ""
}

# Carregar variables d'entorn des del fitxer .env
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::Process)
    }
}

Write-Host "Variables d'entorn carregades des de .env" -ForegroundColor Green
Write-Host "VITE_API_URL = $env:VITE_API_URL" -ForegroundColor Gray

# Validar que VITE_API_URL estigui definit
if ([string]::IsNullOrWhiteSpace($env:VITE_API_URL)) {
    Write-Host "Error: VITE_API_URL no està definit al fitxer .env" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Construir Backend des de GitHub
Write-Host "Construint Backend API des de GitHub..." -ForegroundColor Blue
$buildArgs = @(
    "buildx", "build",
    "-t", "comandesjsdrapi:local",
    "https://github.com/MilorES/ComandesJSDR-Back.git#main",
    "-f", "ComandesAPI/Dockerfile"
)

if ($NoCache) {
    $buildArgs += "--no-cache"
}

& docker $buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error construint el Backend" -ForegroundColor Red
    exit 1
}

Write-Host "Backend construït correctament" -ForegroundColor Green
Write-Host ""

# Construir Frontend des de GitHub
Write-Host "Construint Frontend des de GitHub..." -ForegroundColor Blue

$frontBuildArgs = @(
    "buildx", "build",
    "-t", "comandesjsdrfront:local",
    "--build-arg", "VITE_API_URL=$env:VITE_API_URL",
    "-f", "Dockerfile",
    "https://github.com/MilorES/ComandesJSDR-Front.git#main"
)

if ($NoCache) {
    $frontBuildArgs += "--no-cache"
}

& docker $frontBuildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error construint el Frontend" -ForegroundColor Red
    exit 1
}

Write-Host "Frontend construït correctament" -ForegroundColor Green
Write-Host ""

# Iniciar tots els serveis
Write-Host "Iniciant tots els serveis..." -ForegroundColor Blue
& docker compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Tots els serveis iniciats correctament!" -ForegroundColor Green
    Write-Host ""
    $frontPort = if ($env:FRONT_PORT) { $env:FRONT_PORT } else { "5173" }
    Write-Host "Accés als serveis:" -ForegroundColor Cyan
    Write-Host "   Frontend:  http://localhost:$frontPort" -ForegroundColor White
    Write-Host "   Backend:   $env:VITE_API_URL" -ForegroundColor White
    Write-Host "   Health:    $env:VITE_API_URL/health" -ForegroundColor White
    Write-Host ""
    Write-Host "Veure logs:" -ForegroundColor Cyan
    Write-Host "   docker compose logs -f" -ForegroundColor White
    Write-Host ""
    Write-Host "Aturar serveis:" -ForegroundColor Cyan
    Write-Host "   docker compose down" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Error iniciant els serveis" -ForegroundColor Red
    exit 1
}
