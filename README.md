# ComandesJSDR - Orquestrador

## Descripció

ComandesJSDR és una plataforma que centralitza la gestió de comandes, automatitzant processos que normalment són manuals. Gràcies a XML-UBL, permet interoperabilitat amb altres sistemes i compliment normatiu sense complicacions.

Aquest repositori conté l'orquestrador que gestiona tots els serveis necessaris per executar l'aplicació completa ComandesJSDR (Frontend + Backend + Base de dades).

## Requisits Previs

- **Windows:** Docker Desktop instal·lat i en funcionament
- **Linux/Mac:** Docker i Docker Compose instal·lats
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

**Reconstruir sense caché:**
```powershell
.\build-and-deploy.ps1 -NoCache
```

**Linux/Mac (Bash):**
```bash
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

**Aturar tots els serveis:**
```powershell
docker compose down
```

**Aturar i eliminar volums (esborrar dades):**
```powershell
docker compose down -v --remove-orphans
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

### Opcions Addicionals

**Aturar tots els serveis:**
```powershell
docker compose down
```

**Aturar i eliminar volums (esborrar dades):**
```powershell
docker compose down -v --remove-orphans
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
| `ASPNETCORE_ENVIRONMENT` | Entorn d'execució .NET | Production |

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
- Limita els orígens CORS a dominis específics de producció (no utilitzis localhost)

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

## Notes Importants

- Aquesta configuració està pensada per a entorns de **producció** (construcció automàtica des de GitHub)
- Abans de desplegar en producció, revisa i personalitza el fitxer `.env`:
  - Canvia totes les contrasenyes i claus secretes (`JWT_SECRET_KEY`, `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`, etc.)
  - Ajusta `CORS_ALLOWED_ORIGINS` als dominis reals de producció
  - Verifica que `VITE_API_URL` apunti a la URL pública de la API
  - Ajusta els ports si cal (`API_PORT`, `FRONT_PORT`)
- Els health checks garanteixen la inicialització seqüencial i correcta dels serveis
- Per actualitzar a l'última versió, simplement executa novament `.\build-and-deploy.ps1`
- Per desenvolupament local, consulta la documentació específica de cada repositori (`ComandesJSDR-Front` i `ComandesJSDR-Back`)
