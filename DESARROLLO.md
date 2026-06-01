# Guía de desarrollo

Cómo levantar el proyecto en local para desarrollo.

Hay dos caminos:

- **[Docker](#docker-recomendado)** — un solo requisito (Docker Desktop). Recomendado.
- **[Local con PHP en el host](#local-con-php-en-el-host)** — para quien ya tenga Laragon/XAMPP/MAMP con PHP 8.2+.

## Docker (recomendado)

### Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (incluye `docker compose`).
- Git.

No hace falta tener PHP, Composer ni Node instalados en el host. Todo corre dentro del contenedor.

### Pasos

```bash
# 1. Clonar
git clone <url-del-repo>
cd fp-virtual-gestion-docentes

# 2. Configurar variables de entorno
cp .env.example .env
# Edita .env: ver sección "Variables de entorno" más abajo.

# 3. Configurar el override de Docker (montaje de código en vivo)
cp docker-compose.override.yml.example docker-compose.override.yml

# 4. Construir y levantar los contenedores
docker compose up -d --build

# 5. Generar la APP_KEY y crear las tablas de BD
docker compose exec app-backend php artisan key:generate
docker compose exec app-backend php artisan migrate --seed
```

App disponible en **http://localhost:8082**.

### Qué hace cada paso

- `docker compose up -d --build` levanta dos contenedores:
  - **`app-backend`** — PHP 8.2 + Laravel sirviendo en `:8000` (mapeado al `:8082` del host).
  - **`mysql-db`** — MySQL 8 con la BD `gestor_profesores` (mapeada al `:3306` del host para que puedas conectar con DBeaver/TablePlus).
- El override monta tu carpeta local sobre `/var/www/html` del contenedor: editas un `.php` en tu editor, el cambio se ve al instante sin reconstruir.
- `vendor/`, `node_modules/` y `public/build/` están protegidos del montaje y se usan los que generó la imagen durante el build. Por eso no necesitas PHP/Node en el host.

### Comandos del día a día

```bash
# Levantar / parar
docker compose up -d
docker compose down

# Logs de Laravel en vivo
docker compose exec app-backend php artisan pail

# Shell dentro del contenedor
docker compose exec app-backend bash

# Tests
docker compose exec app-backend ./vendor/bin/pest
docker compose exec app-backend ./vendor/bin/pest --filter "nombre del test"

# Lint
docker compose exec app-backend ./vendor/bin/pint

# Reset de BD (¡borra todo!)
docker compose exec app-backend php artisan migrate:fresh --seed
```

### Cuándo reconstruir la imagen

Solo hace falta `docker compose up -d --build` cuando cambias:

- `Dockerfile`
- `composer.json` (al añadir/quitar paquetes PHP)
- `package.json` (al añadir/quitar paquetes Node)

Para cambios en `.php`, `.blade.php`, `.css`, etc. **no** hace falta rebuild — el montaje los expone al instante.

### Frontend (Vite) — solo si tocas CSS/JS

El `Dockerfile` hace `npm run build` durante el build, así que `public/build/` está listo de serie y la app funciona sin tocar nada.

Si vas a trabajar en CSS/JS y quieres hot-reload, instala Node en el host y arranca el dev server **en el host** (no dentro del contenedor):

```bash
npm install
npm run dev   # Vite escuchando en http://localhost:5173
```

Mientras `npm run dev` está corriendo, Vite crea un fichero `public/hot` en tu carpeta local. Laravel (dentro del contenedor) lo detecta automáticamente y, en vez de servir los assets ya compilados de `public/build/`, le dice al navegador que los pida directamente a `http://localhost:5173` — eso es lo que activa el HMR.

Cuando paras `npm run dev`, Vite borra `public/hot` y Laravel vuelve a usar los assets compilados. No hay que reconstruir la imagen ni tocar el override.

## Local con PHP en el host

Para quien ya tenga un entorno Laravel funcionando (Laragon, XAMPP, MAMP, Valet).

### Requisitos

- PHP 8.2+
- Composer 2.x
- Node.js 18+
- MySQL/MariaDB corriendo en local

### Pasos

```bash
git clone <url-del-repo>
cd fp-virtual-gestion-docentes

cp .env.example .env
# Edita .env apuntando a tu BD local (ver sección "Variables de entorno").

composer install
npm install
npm run build

php artisan key:generate
php artisan migrate --seed

# Levanta servidor + queue + log viewer + vite dev en paralelo
composer dev
```

App en **http://127.0.0.1:8000**.

`composer dev` arranca cuatro procesos en paralelo (`php artisan serve`, `queue:listen`, `pail`, `npm run dev`). Para arrancarlos por separado: `php artisan serve` + `npm run dev` en otra terminal.

## Variables de entorno

`.env.example` tiene defaults pensados para producción. Para desarrollo hay que ajustar:

### Conexión a BD

**Si usas Docker** (recomendado): los valores ya coinciden con `docker-compose.yml`.

```env
DB_CONNECTION=mariadb
DB_HOST=mysql-db
DB_PORT=3306
DB_DATABASE=gestor_profesores
DB_USERNAME=alumno
DB_PASSWORD=alumno
```

> `DB_HOST=mysql-db` es el nombre del servicio en la red interna de Docker. El override ya lo fuerza desde el `environment`, pero conviene tenerlo también en el `.env` por si arrancas comandos `artisan` desde el host.

**Si usas PHP en el host**: pon los datos de tu MySQL/MariaDB local (host normalmente `127.0.0.1`, usuario y contraseña los que tengas configurados).

### URL de la app

```env
APP_URL=http://localhost:8082   # Docker
# o
APP_URL=http://127.0.0.1:8000   # PHP en el host
```

### Moodle (integración API)

Para que funcione la creación de docentes desde `/admin/alta-plataforma`:

```env
MOODLE_URL=https://tu-moodle.example
MOODLE_TOKEN=<token-de-web-services>
MOODLE_USER_AUTH=oauth2
MOODLE_USER_LANG=es
MOODLE_TIMEOUT=15
```

El token se obtiene en el Moodle de destino (Administración del sitio → Servidor → Web Services → Tokens). Necesita permisos `moodle/user:create` y `moodle/user:viewdetails`, y las funciones `core_user_get_users_by_field` y `core_user_create_users` habilitadas en el servicio.

## Cómo se entra (login)

Hay dos guards distintos:

### `/admin/login` — área de administración

| Campo | Valor |
|---|---|
| Usuario | `Admin` |
| Contraseña | `12345678` |

Procede del `AdminSeeder`. Da acceso a `/admin/docentes`, `/admin/centros`, `/admin/alta-plataforma`.

### `/login` — usuarios de centro

El campo "usuario" es el **código del centro** (8 dígitos), no un email. Por defecto la contraseña es igual al usuario.

Ejemplos del `UsuarioSeeder`:

| Centro | Usuario | Contraseña |
|---|---|---|
| CPIFP Montearagón | `22002491` | `22002491` |
| IES Luis Buñuel | `50008460` | `50008460` |
| Campus Digital | `50020125` | `50020125` |

Lista completa en `database/seeders/UsuarioSeeder.php`.

## Datos de prueba

`migrate --seed` solo carga tres seeders básicos (`CentrosCiclosModulosSeeder`, `UsuarioSeeder`, `AdminSeeder`). Los docentes no se siembran por defecto. Para generar docentes de prueba:

```bash
docker compose exec app-backend php artisan db:seed --class=DocenteSeeder
```

(o el seeder que corresponda — revisa `database/seeders/`).

## Tests

```bash
# Todos
docker compose exec app-backend ./vendor/bin/pest

# Un fichero
docker compose exec app-backend ./vendor/bin/pest tests/Feature/GeneradorEmailVirtualTest.php --no-coverage

# Un test concreto
docker compose exec app-backend ./vendor/bin/pest --filter "genera el email correcto"
```

Los tests usan `RefreshDatabase`, así que crean y destruyen las tablas en la propia BD (`gestor_profesores`). No afectan a datos manuales que tengas si los re-siembras después.

## Acceder a la BD desde el host

El puerto `3306` está expuesto. Configura DBeaver/TablePlus:

| Campo | Valor |
|---|---|
| Host | `127.0.0.1` |
| Port | `3306` |
| Database | `gestor_profesores` |
| User | `alumno` o `root` |
| Password | `alumno` o `root12345` |

## Problemas frecuentes

**"Vite manifest not found"**  
La imagen ya trae el build hecho. Si te aparece, es porque tu override está pisando `public/build/`. Asegúrate de tener la línea `- /var/www/html/public/build` en `docker-compose.override.yml`, o ejecuta `docker compose exec app-backend npm run build`.

**"Access denied for user"**  
El `.env` y `docker-compose.yml` no concuerdan. Verifica que `DB_USERNAME`/`DB_PASSWORD` del `.env` coinciden con `MYSQL_USER`/`MYSQL_PASSWORD` del `docker-compose.yml` (o usa `root`/`root12345` si quieres conectar como root).

**Cambios en `.php` que no se reflejan**  
No tienes el override copiado. Verifica que `docker-compose.override.yml` existe en la raíz del proyecto.

**Logs de Moodle vacíos**  
Las llamadas a la API de Moodle se loguean en `storage/logs/moodle_api.log` (canal `moodle_api`), separado de `laravel.log`. Si no aparece nada, comprueba que `MOODLE_URL` y `MOODLE_TOKEN` están rellenos.

## Despliegue en producción

Producción vive en `/var/moodle-docker-deploy/gestionprof.fpvirtualaragon.es`. Para aplicar migraciones tras un deploy:

```bash
cd /var/moodle-docker-deploy/gestionprof.fpvirtualaragon.es
docker compose pull
docker compose up -d
docker compose exec fp-app php artisan migrate --force
```

El nombre del servicio en producción es `fp-app` (no `app-backend` como en el override de dev).
