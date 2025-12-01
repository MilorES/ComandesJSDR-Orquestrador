#!/bin/bash
# Ús: ./build-and-deploy.sh [--no-cache]
# Script per construir i desplegar ComandesJSDR

set -e

NO_CACHE=""

# Parse arguments
for arg in "$@"; do
    case $arg in
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

# Validar que VITE_API_URL estigui definit
if [ -z "$VITE_API_URL" ]; then
    echo "Error: VITE_API_URL no està definit al fitxer .env"
    exit 1
fi

echo ""

# Construir Backend des de GitHub
echo "Construint Backend API des de GitHub..."
docker buildx build $NO_CACHE \
    -t comandesjsdrapi:local \
    https://github.com/MilorES/ComandesJSDR-Back.git#main \
    -f ComandesAPI/Dockerfile

echo "Backend construït correctament"
echo ""

# Construir Frontend des de GitHub
echo "Construint Frontend des de GitHub..."

docker buildx build $NO_CACHE \
    -t comandesjsdrfront:local \
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
echo "   Frontend:  http://localhost:${FRONT_PORT:-5173}"
echo "   Backend:   $VITE_API_URL"
echo "   Health:    $VITE_API_URL/health"
echo ""
echo "Veure logs:"
echo "   docker compose logs -f"
echo ""
echo "Aturar serveis:"
echo "   docker compose down"
