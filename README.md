# fp-virtual-gestion-docentes

Aplicación web para la **gestión del profesorado de FP Virtual en Aragón** (`gestionprof.fpvirtualaragon.es`): altas y bajas de docentes, generación automática de correos `@fpvirtualaragon.es`, asignación de roles (coordinador, tutor) y docencias (ciclo + módulo), y exportación de altas masivas para Google Workspace y Moodle.

## Stack tecnológico

- **Backend:** Laravel 12 / PHP 8.2 (sesiones en base de datos, colas en `database`).
- **Frontend:** Blade + Tailwind CSS 3 + Alpine.js; assets compilados con Vite 6.
- **Base de datos:** MariaDB 10.11 (en local se levanta con Docker).
- **Autenticación:** Laravel Breeze (Blade), basada en sesiones.
- **Testing:** Pest 3 (sobre PHPUnit). Estilo de código: Laravel Pint.

## Acceso

Hay dos pantallas de acceso:

- `/login` — usuarios de centro. El "usuario" es el **código de centro de 8 dígitos** y la contraseña inicial coincide con él (ver `database/seeders/UsuarioSeeder.php`).
- `/admin/login` — administración (en desarrollo: `Admin` / `12345678`).

Para la puesta en marcha completa del entorno (local y servidor LAN), credenciales de prueba y acceso a la BD con DBeaver, ver **[DESARROLLO.md](./DESARROLLO.md)**. Para el uso de la aplicación, ver **[GUIA_USUARIO.md](./GUIA_USUARIO.md)**.

## Arquitectura de la aplicación

### Autenticación

Un único guard `web` sobre el modelo `App\Models\Usuario` (tabla `usuario`). El acceso al panel de administración se controla con el flag booleano `is_admin` y el middleware `App\Http\Middleware\EsAdmin`, que protege todas las rutas `/admin/*` (un usuario autenticado no-admin recibe un `403`).

- `is_admin` está fuera de `$fillable` a propósito, para evitar su asignación masiva desde formularios.
- El login admin (`Admin/Auth/LoginController`) autentica por `nombre` (con fallback por `email`) y exige `is_admin`.
- El usuario de centro se identifica por su código de centro; el alta de docentes siempre se hace en el contexto de ese centro.

### Módulos funcionales (`routes/web.php`)

**Zona de usuario autenticado** (`auth`):

| Ruta | Controlador | Función |
|---|---|---|
| `alta-docente` | `AltaDocenteController` | Alta de docente; genera el email virtual. AJAX: `comprobar-docente/{dni}` (autocompletado) y `alta-docente/preview-email` (previsualización en vivo) |
| `docentes/baja`, `docentes/reactivar/{dni}` | `BajaDocenteController` | Baja y reactivación de docentes del centro |
| `establecer-coordinador` | `EstablecerCoordinadorController` | Asignar/quitar rol de coordinador por centro-ciclo |
| `establecer-tutor` | `EstablecerTutorController` | Asignar/quitar rol de tutor por centro-ciclo |
| `establecer-docencia` | `EstablecerDocenciaController` | Asignar docencia (ciclo + módulo). AJAX: `modulos-por-ciclo/{id}` |
| `profile`, `dashboard` | scaffold Breeze | Perfil de usuario (email, contraseña) y panel principal |

**Panel de administración** (`/admin/*`, prefijo `admin.`, middleware `auth` + `es_admin`):

| Ruta | Controlador | Función |
|---|---|---|
| `docentes`, `docentes/exportar-csv` | `Admin\DocenteController` | Listado global de docentes (buscador, ordenación, ficha en modal) + exportación CSV |
| `centros`, `centros/exportar-csv` | `Admin\CentroController` | Listado de centros-ciclos + ficha con tutor, coordinador y módulos + exportación CSV |
| `alta-plataforma` | `Admin\AltaPlataformaController` | Alta masiva: genera CSV de 29 columnas para Google Workspace y Moodle, contraseña inicial `Cambiam3!_` (cambio obligatorio), unidad organizativa `/Profesorado`; marca docentes como `is_procesado` |

### Organización del código

- `app/Http/Controllers/` — controladores de usuario (raíz), `Auth/` (scaffold Breeze), `Admin/` (panel) y `Admin/Auth/LoginController.php` (login admin).
- `app/Models/` — `Usuario`, `Docente`, `Centro`, `Ciclo`, `Modulo`, `Tutor`, `Coordinador`, `Docencia`, `Imparte`, `CentroDocente`, `CentroCiclo`, `CicloModulo`, `DocenteCicloModulo`. Muchas relaciones pivot usan el **DNI como clave** en lugar del id.
- `app/Services/GeneradorEmailVirtualService.php` — servicio clave: genera el correo `@fpvirtualaragon.es` con el algoritmo `iniciales(nombre) + primer_apellido + inicial(segundo_apellido)`, transliterado a ASCII (sin acentos ni ñ) y con sufijo numérico en caso de colisión. Ej.: `Dario Axel Ureña Garcia` → `daurenag@fpvirtualaragon.es`.
- `app/Console/Commands/EnviarResumenBajas.php` — comando `docentes:enviar-resumen-bajas` (con `--dry-run`) que envía por email el resumen semanal de bajas registradas en `storage/logs/docentes_baja.log`.
- `resources/views/` — vistas Blade: raíz, `admin/`, `auth/`, `components/` (Breeze), `layouts/`, `profile/`, `emails/`.
- `lang/es/` — toda la interfaz está en español; Laravel Lang (`laravel-lang/*`) aporta traducciones de validación.

### Base de datos y seeders

- Migraciones en `database/migrations/`. Datos maestros de centros/ciclos/módulos en `CentrosCiclosModulosSeeder` (lee `database/seeders/zz_infoCentros.csv`).
- `DatabaseSeeder` solo llama a `CentrosCiclosModulosSeeder` y `UsuarioSeeder`; los docentes **no** se siembran por defecto.
- Credenciales de la BD en desarrollo: base `gestor_profesores`, usuario `gestor` / `gestor` (root: `root12345`).

## Casos de uso y funcionalidad

### Usuario de centro

| Caso de uso | Descripción |
|---|---|
| **Alta de docente** | Formulario con DNI, email personal, nombre y apellidos. Al teclear el DNI se autocompleta si el docente ya existe (campos bloqueados, desbloqueables con el candado). El correo `@fpvirtualaragon.es` se genera y previsualiza en vivo. Si el docente estaba de baja, el alta lo reactiva. Tras guardar, redirige a asignar docencia con el docente preseleccionado. |
| **Baja de docente** | Listado con buscador en vivo; confirmación en modal. La baja queda auditada en `storage/logs/docentes_baja.log`. |
| **Reactivación de docente** | Botón directo sobre los docentes dados de baja. |
| **Establecer coordinador** | Un coordinador por centro-ciclo; opción "También es tutor" que crea la tutoría. Listado ordenable con borrado (solo coordinador o coordinador + tutor). |
| **Establecer tutor** | Un tutor por centro-ciclo; simétrico al coordinador. |
| **Establecer docencia** | Asigna docente + ciclo + módulo (los módulos se filtran por ciclo). Un módulo puede tener varios docentes (se advierte al duplicar). |
| **Perfil** | Consulta de ID de centro y cambio de email/contraseña. |

### Administrador

| Caso de uso | Descripción |
|---|---|
| **Gestión de Docentes** | Listado global con buscador, ordenación y ficha en modal (datos, módulos que imparte, tutorías, coordinaciones). Exportación CSV. |
| **Gestión de Centros** | Listado centro-ciclo con ficha en modal (tutor, coordinador, módulos y docentes). Exportación CSV. |
| **Alta en Plataforma** | Selección de docentes activos con correo virtual (filtros por texto y estado pendiente/procesado), previsualización CSV, descarga de `alta_google_workspace.csv` y `alta_moodle.csv` (cabecera oficial de 29 columnas), y marcado de docentes como procesados. |
| **Informe semanal de bajas** | Comando `docentes:enviar-resumen-bajas` (programable) que envía por email los eventos de baja/reactivación de la semana y rota el log. |

## Comandos principales

```bash
composer dev                        # desarrollo: serve + queue:listen + pail + vite
npm run dev / npm run build         # Vite
php artisan test                    # suite de tests (Pest)
./vendor/bin/pint                   # formateo (Laravel Pint)
php artisan migrate:fresh --seed    # recrear tablas y datos básicos
docker compose up -d                # MariaDB de desarrollo en 127.0.0.1:3306
```

## Testing

Suite en Pest 3 con `RefreshDatabase`; `phpunit.xml` fuerza SQLite en memoria, así que los tests no tocan la BD de desarrollo. Estado verificado (2026-09-07): **81 pasan, 26 fallan**; los fallos son tests scaffold de Breeze que referencian una clase `User` inexistente (la app usa `Usuario`) — fallo conocido y ajeno a la lógica de negocio. Los tests de dominio (`GeneradorEmailVirtualTest`, `AltaPlataformaTest`, `GestionDocentesTest`, `BajasDocentesLogTest`, etc.) están verdes.

## Despliegue

- `Dockerfile`: PHP 8.2-FPM + Composer + Node 18, assets compilados con Vite, arranque vía `start.sh` → `supervisord.conf`.
- `docker-compose.yml`: solo MariaDB (desarrollo).
- `docker-compose.server.yml`: servidor de pruebas en LAN (app en `http://IP:8082`); requiere reconstruir la imagen para aplicar cambios de código.
- Producción: desplegado vía Docker Compose en `gestionprof.fpvirtualaragon.es`.

## Documentación de referencia

- **[GUIA_USUARIO.md](./GUIA_USUARIO.md)** — guía completa de uso, pantalla a pantalla.
- **[DESARROLLO.md](./DESARROLLO.md)** — puesta en marcha (local y servidor LAN), credenciales de prueba, DBeaver, solución de problemas.
- **[AGENTS.md](./AGENTS.md)** — guía para agentes de IA que trabajen en el repositorio.
- `CLAUDE.md` — resumen rápido (parcialmente desactualizado).
- `PULL_REQUEST.md` — diagnóstico del PR #73 de unificación de autenticación.
