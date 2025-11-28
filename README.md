# Orquestrador ComandesJSDR

## Descripció

Aquest repositori conté l'orquestrador que gestiona tots els serveis necessaris per executar l'aplicació completa ComandesJSDR (Frontend + Backend + Base de dades).

ComandesJSDR és una plataforma que centralitza la gestió de comandes, automatitzant processos que normalment són manuals. Gràcies a XML-UBL, permet interoperabilitat amb altres sistemes i compliment normatiu sense complicacions.



## Requisits Previs

- **Windows:** Docker Desktop instal·lat i en funcionament
- **Linux/Mac:** Docker i Docker Compose instal·lats
- Git (per clonar repositoris)
- Accés als repositoris GitHub:
  - `ComandesJSDR-Front` (es construeix automàticament des de GitHub)
  - `ComandesJSDR-Back` (es construeix automàticament des de GitHub)

## Instal·lació

Primer, clona aquest repositori d'orquestrador:

```shell
git clone https://github.com/MilorES/ComandesJSDR-Orquestrador.git
cd ComandesJSDR-Orquestrador
```

Després segueix les instruccions d'ús ràpid.

## Ús Ràpid

### Opció 1: Script Automatitzat (Recomanat)

**Windows (PowerShell):**
- Execució normal:
  ```powershell
  .\build-and-deploy.ps1
  ```
- Execució sense caché:
  ```powershell
  .\build-and-deploy.ps1 -NoCache
  ```

**Linux/Mac (Bash):**
- Execució normal:
  ```bash
  ./build-and-deploy.sh
  ```
- Execució sense caché:
  ```bash
  ./build-and-deploy.sh --no-cache
  ```
Atenció a l'script necesita permís d'execució
```bash
chmod +x build-and-deploy.sh
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

1. **comandesjsdr_mariadb**: Base de dades MariaDB 10.6 amb persistència de dades
2. **comandesjsdr_api**: Backend API (.NET 9.0) - Es construeix des de https://github.com/MilorES/ComandesJSDR-Back
3. **comandesjsdr_front**: Frontend (React + Vite + Nginx) - Es construeix des de https://github.com/MilorES/ComandesJSDR-Front

### Característiques clau

- **Construcció automàtica des de GitHub**: Backend i Frontend es construeixen directament des dels repositoris (branca main)
- **No requereix codi local**: Només cal aquest orquestrador per desplegar tot el sistema
- **Sempre actualitzat**: Cada construcció obté l'última versió dels repositoris
- **Configuració centralitzada**: Variables d'entorn gestionades des d'un únic fitxer `.env`
- **Reproducible**: Construccions consistents en qualsevol màquina amb Docker

### Ordre d'Inici

Els serveis s'inicien en aquest ordre gràcies a les dependències i healthchecks:

```
comandesjsdr_mariadb (healthcheck) → comandesjsdr_api (healthcheck) → comandesjsdr_front
```

## Accés als Serveis

Després d'iniciar els serveis, podeu accedir a:

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:5000/api
- **Health Check**: http://localhost:5000/health
- **MariaDB**: localhost:3306 (accessible només des de la xarxa Docker interna)

## Comandaments Útils

### Veure logs de tots els serveis

```powershell
docker compose logs -f
```

### Veure logs d'un servei específic

```powershell
# Frontend
docker compose logs -f comandesjsdr_front

# Backend
docker compose logs -f comandesjsdr_api

# Base de dades
docker compose logs -f comandesjsdr_mariadb
```

### Reiniciar un servei

```powershell
docker compose restart comandesjsdr_api
```



Després de reconstruir, pots iniciar els serveis amb:
```powershell
docker compose up -d
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

Tots els serveis es comuniquen a través de la xarxa personalitzada `comandesjsdr-network`:

```
comandesjsdr_front → comandesjsdr_api → comandesjsdr_mariadb
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
