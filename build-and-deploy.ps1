#!/usr/bin/env pwsh
# Script per construir i desplegar ComandesJSDR
# Usage: .\build-and-deploy.ps1 [--rebuild]

param(
    [switch]$Rebuild = $false,
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
Write-Host ""

# Construir Backend des de GitHub
Write-Host "Construint Backend API des de GitHub..." -ForegroundColor Blue
$buildArgs = @(
    "buildx", "build",
    "-t", "comandesapi:local",
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
    "-t", "comandesfront:local",
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
    Write-Host "Accés als serveis:" -ForegroundColor Cyan
    Write-Host "   Frontend:  http://localhost:5173" -ForegroundColor White
    Write-Host "   Backend:   http://localhost:5000/api" -ForegroundColor White
    Write-Host "   Health:    http://localhost:5000/health" -ForegroundColor White
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
