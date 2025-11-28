# ComandesJSDR - Orquestrador

## Descripció

ComandesJSDR és una plataforma que centralitza la gestió de comandes, automatitzant processos que normalment són manuals. Gràcies a XML-UBL, permet interoperabilitat amb altres sistemes i compliment normatiu sense complicacions.

Aquest repositori conté l'orquestrador que gestiona tots els serveis necessaris per executar l'aplicació completa ComandesJSDR (Frontend + Backend + Base de dades).

## Requisits Previs

- Docker Desktop instal·lat i en funcionament
- Docker Compose v3.8 o superior
- Git (per clonar repositoris)
- Accés als repositoris GitHub:
  - `ComandesJSDR-Front` (es construeix automàticament des de GitHub)
  - `ComandesJSDR-Back` (es construeix automàticament des de GitHub)

## Ús Ràpid

### Opció 1: Script Automatitzat (Recomanat)

**Windows (PowerShell):**
```powershell
.\build-and-deploy.ps1
```

**Linux/Mac (Bash):**
```bash
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

El script executarà automàticament:
- Creació de `.env` des de `.env.example` (si no existeix)
- Construcció del **Backend des de GitHub** (última versió de la branca main)
- Construcció del **Frontend des de GitHub** (última versió de la branca main)
- Inicialització de tots els serveis amb dependències i health checks

**Avantatges d'aquesta arquitectura:**
- Backend i Frontend sempre actualitzats des dels repositoris centrals
- No cal clonar repositoris localment
- Construccions consistents i reproducibles
- Ideal per a desplegaments i CI/CD

### Opció 2: Manual

### 1. Configuració Inicial

Copia el fitxer `.env.example` a `.env` i ajusta les variables si cal:

```powershell
Copy-Item .env.example .env
```

### 2. Construir Backend des de GitHub

```powershell
docker buildx build -t comandesapi:local https://github.com/MilorES/ComandesJSDR-Back.git#main -f ComandesAPI/Dockerfile
```

### 3. Construir Frontend des de GitHub

```powershell
docker buildx build -t comandesfront:local --build-arg VITE_API_URL=http://localhost:5000/api https://github.com/MilorES/ComandesJSDR-Front.git#main -f Dockerfile
```

### 4. Iniciar Tots els Serveis

```powershell
docker compose up -d
```

### 5. Aturar Tots els Serveis

```powershell
docker compose down
```

### 6. Aturar i Eliminar Volums (esborrar dades)

```powershell
docker compose down -v --remove-orphans
```

### 7. Reconstruir amb --no-cache

```powershell
.\build-and-deploy.ps1 -NoCache
```

## Arquitectura

L'orquestrador gestiona 3 serveis principals mitjançant Docker Compose:

1. **mariadb**: Base de dades MariaDB 10.6 amb persistència de dades
2. **comandesapi**: Backend API (.NET 9.0) - Es construeix des de https://github.com/MilorES/ComandesJSDR-Back
3. **comandesfront**: Frontend (React + Vite + Nginx) - Es construeix des de https://github.com/MilorES/ComandesJSDR-Front

### Característiques clau

- **Construcció automàtica des de GitHub**: Backend i Frontend es construeixen directament des dels repositoris (branca main)
- **No requereix codi local**: Només cal aquest orquestrador per desplegar tot el sistema
- **Sempre actualitzat**: Cada construcció obté l'última versió dels repositoris
- **Configuració centralitzada**: Variables d'entorn gestionades des d'un únic fitxer `.env`
- **Reproducible**: Construccions consistents en qualsevol màquina amb Docker

### Ordre d'Inici

Els serveis s'inicien en aquest ordre gràcies a les dependències i healthchecks:

```
mariadb (healthcheck) → comandesapi (healthcheck) → comandesfront
```

## Accés als Serveis

Després d'iniciar els serveis, podeu accedir a:

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:5000/api
- **Health Check**: http://localhost:5000/health
- **MariaDB**: localhost:3306 (accessible només des de la xarxa Docker interna)

## Variables d'Entorn

Totes les variables es configuren al fitxer `.env`:

| Variable | Descripció | Per Defecte |
|----------|------------|-------------|
| `API_PORT` | Port del backend | 5000 |
| `FRONT_PORT` | Port del frontend | 5173 |
| `MYSQL_ROOT_PASSWORD` | Contrasenya root MySQL | rootpassword |
| `MYSQL_DATABASE` | Nom de la base de dades | databaseapi |
| `MYSQL_USER` | Usuari MySQL | userapi |
| `MYSQL_PASSWORD` | Contrasenya MySQL | passwordapi |
| `MYSQL_PORT` | Port intern MySQL | 3306 |
| `JWT_SECRET_KEY` | Clau secreta JWT | [clau segura] |
| `JWT_ISSUER` | Emissor del token JWT | ComandesJSDR |
| `JWT_AUDIENCE` | Audiència del token JWT | ComandesJSDR-API |
| `CORS_ALLOWED_ORIGINS` | Orígens CORS permesos | http://localhost:3000,http://localhost:5173 |
| `VITE_API_URL` | URL de l'API pel frontend | http://localhost:5000/api |
| `ASPNETCORE_ENVIRONMENT` | Entorn d'execució .NET | Development |

## Comandaments Útils

### Veure logs de tots els serveis

```powershell
docker compose logs -f
```

### Veure logs d'un servei específic

```powershell
# Frontend
docker compose logs -f comandesfront

# Backend
docker compose logs -f comandesapi

# Base de dades
docker compose logs -f mariadb
```

### Reiniciar un servei

```powershell
docker compose restart comandesapi
```

### Reconstruir les imatges

```powershell
docker compose build
docker compose up -d
```

### Reconstruir sense caché

```powershell
docker compose build --no-cache
```

### Veure l'estat dels serveis

```powershell
docker compose ps
```

### Executar migracions manualment

```powershell
docker exec -it comandes_api dotnet ef database update
```

## Health Checks

Tots els serveis implementen health checks per garantir l'ordre correcte d'inicialització:

- **MariaDB**: Verificació de connectivitat mitjançant `mysqladmin ping`
- **Backend**: Verificació de disponibilitat de l'endpoint `/health`
- **Frontend**: Verificació de resposta del servidor Nginx

## Xarxa Docker

Tots els serveis es comuniquen a través de la xarxa personalitzada `comandes-network`:

```
comandesfront → comandesapi → mariadb
```

Això permet la resolució de noms per hostname i aïllament de la xarxa host.

## Consideracions de Seguretat

**IMPORTANT - Entorns de Producció:**

- Mai commitegis el fitxer `.env` al control de versions
- Genera contrasenyes i claus secretes aleatòries i segures
- La variable `JWT_SECRET_KEY` ha de contenir almenys 32 caràcters alfanumèrics
- Configura `ASPNETCORE_ENVIRONMENT=Production` i ajusta les variables corresponents
- Limita els orígens CORS a dominis específics de producció

## Resolució de Problemes

### El frontend no es connecta a l'API

Verifica que `VITE_API_URL` al `.env` coincideixi amb el port de l'API.

### Error de connexió a la base de dades

Comprova que el servei mariadb estigui healthy:

```powershell
docker compose ps
```

### Ports ja en ús

Canvia els ports al fitxer `.env`:

```env
API_PORT=5001
FRONT_PORT=5174
```

## Gestió de Volums

El volum `db_data` proporciona persistència per a les dades de MariaDB.

Per eliminar completament les dades (reinici complet):

```powershell
docker compose down -v --remove-orphans
```

L'opció `--remove-orphans` elimina contenidors orfes que puguin haver quedat d'execucions anteriors.

## Actualització de Serveis

Quan es fan canvis al codi font:

```powershell
# Reconstruir i reiniciar tots els serveis
docker compose up -d --build

# Reconstruir només un servei específic
docker compose up -d --build comandesapi
```

## Notes Importants

- Aquesta configuració està optimitzada per a entorns de **desenvolupament**
- Per a desplegament en producció, cal ajustar `ASPNETCORE_ENVIRONMENT=Production` i revisar totes les variables de seguretat
- Els health checks garanteixen la inicialització seqüencial i correcta dels serveis
- Tant el Frontend com el Backend es construeixen automàticament des de GitHub (branca main)
- Per desenvolupament local amb modificacions, clona els repositoris i ajusta els `build.context` al docker-compose.yml
