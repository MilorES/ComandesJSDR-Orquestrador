#!/bin/bash
# Script per construir i desplegar ComandesJSDR
# Usage: ./build-and-deploy.sh [--rebuild] [--no-cache]

set -e

REBUILD=false
NO_CACHE=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --rebuild)
            REBUILD=true
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
    esac
done

echo "ComandesJSDR - Script de Construcció i Desplegament"
echo "======================================================"
echo ""

# Verificar que existeix .env
if [ ! -f ".env" ]; then
    echo "Fitxer .env no trobat. Creant des de .env.example..."
    cp .env.example .env
    echo "Fitxer .env creat. Revisa la configuració abans de continuar."
    echo ""
fi

# Carregar variables d'entorn des del fitxer .env
export $(grep -v '^#' .env | xargs)

echo "Variables d'entorn carregades des de .env"
echo "VITE_API_URL = $VITE_API_URL"
echo ""

# Construir Backend des de GitHub
echo "Construint Backend API des de GitHub..."
docker buildx build $NO_CACHE \
    -t comandesapi:local \
    https://github.com/MilorES/ComandesJSDR-Back.git#main \
    -f ComandesAPI/Dockerfile

echo "Backend construït correctament"
echo ""

# Construir Frontend des de GitHub
echo "Construint Frontend des de GitHub..."

docker buildx build $NO_CACHE \
    -t comandesfront:local \
    --build-arg VITE_API_URL=$VITE_API_URL \
    https://github.com/MilorES/ComandesJSDR-Front.git#main \
    -f Dockerfile

echo "Frontend construït correctament"
echo ""

# Iniciar tots els serveis
echo "Iniciant tots els serveis..."
docker compose up -d

echo ""
echo "Tots els serveis iniciats correctament!"
echo ""
echo "Accés als serveis:"
echo "   Frontend:  http://localhost:5173"
echo "   Backend:   http://localhost:5000/api"
echo "   Health:    http://localhost:5000/health"
echo ""
echo "Veure logs:"
echo "   docker compose logs -f"
echo ""
echo "Aturar serveis:"
echo "   docker compose down"
echo ""
