# AGENTS.md

Guía para agentes de IA que trabajen en este repositorio. Todo el proyecto (código, comentarios, documentación e interfaz) está en **español**: escribe código y respuestas en español.

## Descripción del proyecto

Aplicación web para la **gestión del profesorado de FP Virtual en Aragón** (`gestionprof.fpvirtualaragon.es`). Permite dar de alta/baja docentes, generarles automáticamente un correo `@fpvirtualaragon.es`, asignar roles (coordinador, tutor) y docencias (ciclo + módulo), y exportar CSV de altas masivas para Google Workspace y Moodle desde un panel de administración.

## Stack tecnológico

- **Backend:** Laravel 12 / PHP 8.2 (sesiones en base de datos, colas en `database`).
- **Frontend:** Blade + Tailwind CSS 3 + Alpine.js; assets compilados con Vite 6. **No hay Vue** (el README lo menciona pero es incorrecto).
- **Base de datos:** MariaDB 10.11 (en local se levanta con Docker).
- **Autenticación:** Laravel Breeze (Blade), basada en sesiones.
- **Testing:** Pest 3 (sobre PHPUnit). Estilo de código: Laravel Pint.

## Comandos principales

```bash
# Desarrollo (arranca a la vez: php artisan serve + queue:listen + pail + vite)
composer dev

# Frontend por separado
npm run dev        # servidor de desarrollo Vite
npm run build      # build de producción

# Tests (Pest)
php artisan test                                   # toda la suite
./vendor/bin/pest tests/Feature/AlgunTest.php      # un fichero
./vendor/bin/pest --filter "texto del test"        # por nombre

# Base de datos
php artisan migrate:fresh --seed   # recrear tablas y sembrar datos básicos
php artisan db:seed --class=DocenteSeeder   # docentes de prueba (no se siembran por defecto)

# Estilo de código
./vendor/bin/pint   # formatea según Laravel Pint (ejecútalo antes de commitear)

# Docker (solo base de datos en desarrollo)
docker compose up -d               # MariaDB en 127.0.0.1:3306

# Docker (servidor completo de pruebas en LAN)
docker compose -f docker-compose.server.yml build
docker compose -f docker-compose.server.yml up -d   # app en http://IP:8082
```

Requisitos en local: PHP 8.2+, Composer, Node 18+, Docker (para la BD). Guía detallada paso a paso en `DESARROLLO.md`.

## Arquitectura

### Autenticación (importante: recién unificada)

Hay **un único guard `web`** sobre el modelo `App\Models\Usuario` (tabla `usuario`). El acceso al panel de administración se controla con el flag booleano `is_admin` y el middleware `App\Http\Middleware\EsAdmin`, que protege todas las rutas `/admin/*`.

- `/login` — usuarios de centro. El "usuario" es el **código de centro de 8 dígitos** y la contraseña inicial coincide con él (ver `database/seeders/UsuarioSeeder.php`).
- `/admin/login` — administración. Login: `Admin` / `12345678` (un `Usuario` con `is_admin = true`).

> **Ojo:** `CLAUDE.md` todavía describe un guard `admin` legacy con modelo `Admin`: **ya no existe**. Fue eliminado en el PR #73 (ver `PULL_REQUEST.md`). No reintroduzcas ese patrón. También: `is_admin` está fuera de `$fillable` en `Usuario` a propósito (evitar asignación masiva), y el mutator `nombre()` normaliza el nombre.

### Rutas y módulos funcionales (`routes/web.php`)

Todas requieren autenticación salvo el login:

| Ruta | Controlador | Propósito |
|---|---|---|
| `alta-docente` | `AltaDocenteController` | Alta de docente; genera el email virtual. Endpoints AJAX: `comprobar-docente/{dni}`, `alta-docente/preview-email` |
| `docentes/baja`, `docentes/reactivar/{dni}` | `BajaDocenteController` | Baja y reactivación de docentes |
| `establecer-coordinador` | `EstablecerCoordinadorController` | Asignar/quitar rol de coordinador por centro-ciclo |
| `establecer-tutor` | `EstablecerTutorController` | Asignar/quitar rol de tutor |
| `establecer-docencia` | `EstablecerDocenciaController` | Asignar docencia (ciclo + módulo). AJAX: `modulos-por-ciclo/{id}` |

Panel admin (`/admin/*`, prefijo `admin.`, middleware `auth` + `es_admin`):

| Ruta | Controlador | Propósito |
|---|---|---|
| `docentes`, `docentes/exportar-csv` | `Admin\DocenteController` | Listado de docentes + exportación CSV |
| `centros`, `centros/exportar-csv` | `Admin\CentroController` | Listado de centros + exportación CSV |
| `alta-plataforma` | `Admin\AltaPlataformaController` | Alta masiva en plataforma: genera filas CSV de 29 columnas (Google Workspace y Moodle), contraseña inicial `Cambiam3!_`, unidad organizativa `/Profesorado`; marca docentes como `is_procesado` |

### Organización del código

- `app/Http/Controllers/` — controladores de usuario (raíz), `Auth/` (scaffold Breeze), `Admin/` (panel) y `Admin/Auth/LoginController.php` (login admin).
- `app/Models/` — `Usuario`, `Docente`, `Centro`, `Ciclo`, `Modulo`, `Tutor`, `Coordinador`, `Docencia`, `Imparte`, `CentroDocente`, `CentroCiclo`, `CicloModulo`, `DocenteCicloModulo`. Muchas relaciones pivot usan el **DNI como clave** en lugar del id.
- `app/Services/GeneradorEmailVirtualService.php` — servicio clave: genera el correo `@fpvirtualaragon.es` con el algoritmo `iniciales(nombre) + primer_apellido + inicial(segundo_apellido)`, transliterado a ASCII (sin acentos ni ñ) y con sufijo numérico en caso de colisión. Ej.: `Dario Axel Ureña Garcia` → `daurenag@fpvirtualaragon.es`.
- `app/Console/Commands/EnviarResumenBajas.php` — comando `docentes:enviar-resumen-bajas` (con `--dry-run`) que envía por email el resumen semanal de bajas registradas en `storage/logs/docentes_baja.log`; usa `App\Mail\ResumenBajasDocentes`.
- `resources/views/` — vistas Blade: raíz (módulos de usuario), `admin/`, `auth/`, `components/` (blades anónimos estilo Breeze), `layouts/`, `profile/`, `emails/`.
- `lang/es/` — toda la interfaz está en español; Laravel Lang (`laravel-lang/*`) aporta traducciones de validación.

### Base de datos y seeders

- Migraciones en `database/migrations/`. Datos maestros de centros/ciclos/módulos vienen del seeder `CentrosCiclosModulosSeeder` (lee `database/seeders/zz_infoCentros.csv`).
- `DatabaseSeeder` solo llama a `CentrosCiclosModulosSeeder` y `UsuarioSeeder`. Los docentes **no** se siembran por defecto (`DocenteSeeder` está vacío).
- `BD-Gestor_Profesores.sql` en la raíz y `database/migrations/2025_09_09_fix.txt` son restos legados de SQL manual; las tablas las crean las migraciones.
- Credenciales de la BD en desarrollo: base `gestor_profesores`, usuario `gestor` / `gestor` (root: `root12345`).

## Convenciones de desarrollo

- **Idioma:** nombres de rutas, variables, métodos, comentarios y mensajes de usuario en español (p. ej. `establecer_docencia.index`, `EsAdmin`, "Acceso restringido a administradores.").
- **Estilo:** sigue Laravel Pint (`./vendor/bin/pint`); no añadas tu propio formato.
- **Vistas:** Blade con Tailwind; componentes reutilizables en `resources/views/components/`; layouts compartidos en `resources/views/layouts/`.
- **No crees un modelo `User` ni un guard `admin`:** la app usa `Usuario` y `web`+`is_admin`. Los tests scaffold de Breeze que referencian `User::factory()` están rotos por esto (ver "Testing").
- Al añadir campos al alta de docente, respeta el servicio `GeneradorEmailVirtualService` (su algoritmo tiene tests que no deben romperse).
- Variables de entorno de Moodle (`MOODLE_URL`, `MOODLE_TOKEN`, …): la integración actual genera **CSV**, no llama a la API web de Moodle. Las vars son legados del `.env.example`.

## Testing

- Suite en Pest 3 con `RefreshDatabase` (definido en `tests/Pest.php`). `phpunit.xml` fuerza SQLite en memoria para tests (`DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`), así que **no tocan la BD de desarrollo**.
- Estado actual de la suite (verificado 2026-09-07): **81 pasan, 26 fallan**. Los 26 fallos son tests scaffold de Breeze (`ProfileTest`, auth tests) que referencian una clase `User` inexistente — fallo conocido y preexistente, documentado en `PULL_REQUEST.md`. No está relacionado con la lógica de negocio; los tests de dominio (`GeneradorEmailVirtualTest`, `AltaPlataformaTest`, `GestionDocentesTest`, `BajasDocentesLogTest`, etc.) están verdes.
- `/register` está roto y público (referencia a la clase `User`); pendiente de eliminar o reescribir — no lo uses como base para nada.

## Despliegue y Docker

- `Dockerfile`: imagen PHP 8.2-FPM con Composer y Node 18; compila assets con Vite; arranque vía `start.sh` → `supervisord.conf` (php-fpm). Pensada para producción real.
- `docker-compose.yml` (desarrollo): solo MariaDB 10.11 con el puerto 3306 expuesto.
- `docker-compose.server.yml` (servidor de pruebas en LAN): construye la imagen completa pero sobrescribe el comando para servir con `php artisan serve` en el puerto 8082 y migra al arrancar. La BD **no** expone puertos. Para aplicar cambios de código hay que reconstruir la imagen.
- CI: el workflow `.github/workflows/docker-publish.yml` está desactivado (renombrado a `.desactivado`).
- Entorno de producción: desplegado vía Docker Compose en `gestionprof.fpvirtualaragon.es`.

## Seguridad

- Nunca subas secretos: `.env` está en `.gitignore`. Las credenciales por defecto (`Admin/12345678`, contraseñas = código de centro) son **datos de desarrollo** documentados en `DESARROLLO.md`, no credenciales reales.
- `is_admin` fuera de `$fillable`: no lo metas en formularios ni en `fill($request->all())`.
- El login admin exige `is_admin`; un usuario no-admin autenticado recibe `403` del middleware `EsAdmin`.
- Las contraseñas de seed se hashean con `Hash::make`. La contraseña inicial de altas masivas en plataforma (`Cambiam3!_`) es una constante en `AltaPlataformaController` con cambio obligatorio en el primer inicio de sesión (`Change Password at Next Sign-In = TRUE`).

## Documentación de referencia

- `DESARROLLO.md` — guía completa de puesta en marcha (local y servidor LAN), credenciales de prueba, acceso a la BD con DBeaver, solución de problemas frecuentes.
- `CLAUDE.md` — resumen rápido de comandos y arquitectura (parcialmente desactualizado: la parte del guard `admin` legacy ya no aplica).
- `PULL_REQUEST.md` — diagnóstico del PR #73 de unificación de autenticación.
- `README.md` — descripción general (contiene datos desactualizados: dice Laravel 10/Vue 3; el proyecto es Laravel 12 con Blade).
