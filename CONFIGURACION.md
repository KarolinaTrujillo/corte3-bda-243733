# Configuración de Variables de Entorno

## Cambios Realizados para Eliminar Hardcodeo

Se han refactorizado todos los valores hardcodeados en el proyecto para usar variables de entorno. Esto permite que la aplicación sea flexible y se adapte a diferentes ambientes (desarrollo, producción, etc.).

### Archivos Modificados

#### 1. **api/db.js**
- ✅ Puerto de PostgreSQL ahora usa `process.env.DB_PORT` (default: 5432)

#### 2. **api/redis.js**
- ✅ Puerto de Redis ahora usa `process.env.REDIS_PORT` (default: 6379)

#### 3. **api/index.js**
- ✅ TTL de caché ahora usa `process.env.CACHE_TTL` (default: 300 segundos)
- ✅ Roles válidos ahora usan `process.env.VALID_ROLES` (default: rol_veterinario,rol_recepcion,rol_administrador)
- ✅ Rol por defecto ahora usa `process.env.DEFAULT_ROLE` (default: rol_recepcion)
- ✅ Host y puerto de la API ahora usan `process.env.HOST` y `process.env.PORT`

#### 4. **frontend/app.js**
- ✅ API_URL ahora se obtiene de `window.API_URL` o por defecto 'http://localhost:3000/api'

#### 5. **frontend/index.html**
- ✅ Script que configura `window.API_URL` para permitir inyección de variables

#### 6. **docker-compose.yml**
- ✅ Todos los valores usan sintaxis `${VARIABLE:-default}` para ser configurables
- ✅ Soporta .env file para cargar variables automáticamente

### Variables de Entorno Disponibles

| Variable | Descripción | Default | Ubicación |
|----------|-------------|---------|-----------|
| `DB_HOST` | Host de PostgreSQL | localhost | api, docker-compose |
| `DB_PORT` | Puerto de PostgreSQL | 5432 | api/db.js, docker-compose |
| `DB_USER` | Usuario de PostgreSQL | postgres | api, docker-compose |
| `DB_PASSWORD` | Contraseña de PostgreSQL | postgres | api, docker-compose |
| `DB_NAME` | Nombre de la base de datos | clinica_vet | api, docker-compose |
| `REDIS_HOST` | Host de Redis | localhost | api, docker-compose |
| `REDIS_PORT` | Puerto de Redis | 6379 | api/redis.js, docker-compose |
| `HOST` | Host del API | localhost | api/index.js, docker-compose |
| `PORT` | Puerto del API | 3000 | api/index.js, docker-compose |
| `FRONTEND_PORT` | Puerto del Frontend (Nginx) | 8080 | docker-compose |
| `API_URL` | URL de la API para el frontend | http://localhost:3000/api | frontend |
| `CACHE_TTL` | Tiempo de caché en segundos | 300 | api/index.js |
| `DEFAULT_ROLE` | Rol por defecto | rol_recepcion | api/index.js |
| `VALID_ROLES` | Roles válidos (separados por coma) | rol_veterinario,rol_recepcion,rol_administrador | api/index.js |

### Cómo Usar

#### Opción 1: Con Docker Compose (Recomendado)

1. Copia `.env.example` a `.env` si no existe:
```bash
cp .env.example .env
```

2. Modifica `.env` con tus valores:
```env
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=tu_contraseña_segura
DB_NAME=clinica_vet
REDIS_HOST=redis
REDIS_PORT=6379
PORT=3000
API_URL=http://localhost:3000/api
```

3. Inicia los servicios:
```bash
docker-compose up -d
```

#### Opción 2: Desarrollo Local

1. Configura las variables en tu terminal:

**Windows (PowerShell):**
```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:REDIS_HOST = "localhost"
$env:PORT = "3000"
```

**Linux/Mac (Bash):**
```bash
export DB_HOST=localhost
export DB_PORT=5432
export REDIS_HOST=localhost
export PORT=3000
```

2. O usa un archivo `.env.local` (git-ignorado) para desarrollo

### Seguridad

⚠️ **IMPORTANTE:**
- **NUNCA** comitas el archivo `.env` a Git
- Usa `.env.example` como plantilla
- Para producción, usa secretos manejados por tu plataforma (AWS Secrets Manager, Azure Key Vault, etc.)
- **CAMBIAR** la contraseña default de PostgreSQL (`postgres`)

### Verificación

Para verificar que las variables se están usando correctamente:

1. Backend está usando variables:
```bash
docker-compose logs api
# Deberías ver mensajes indicando los puertos configurados
```

2. Frontend accede a la API:
- Abre http://localhost:8080
- Verifica en la consola del navegador que `window.API_URL` está correctamente configurado
