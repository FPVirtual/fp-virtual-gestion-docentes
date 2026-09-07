# Fix: unificación de autenticación admin y limpieza del guard legacy

## Resumen

Se corrigen **dos bugs críticos de autenticación** reportados en el panel de administración y se resuelven **tres problemas adicionales** detectados durante el diagnóstico. La causa raíz común era una **migración a medias entre dos guards de autenticación** (`admin` legacy vs `web`+`is_admin`). Este PR completa esa migración, unifica todo en el guard `web` y elimina el código muerto resultante.

**Impacto en tests:** la suite pasa de **49 fallos / 58 pasan** a **26 fallos / 81 pasan** (+23 tests arreglados, 0 regresiones). Los 26 fallos restantes son scaffold de Breeze pre-existente, ajenos a este PR.

## Bugs corregidos (reportados)

### Bug 1 — Bucle de redirección en `/admin/login` ("too many redirects")

Con una cookie *remember* residual del guard `admin`, `showLoginForm` redirigía a `/admin/dashboard`; ese dashboard exige el guard `web` (`['auth','es_admin']`), fallaba, y el manejador de excepciones de `bootstrap/app.php` devolvía a `/admin/login`, generando un bucle infinito.

### Bug 2 — `/login` con credenciales de admin redirigía a `/admin/dashboard`

El fallo anterior dejaba `/admin/dashboard` guardado como URL *"intended"*. Luego `AuthenticatedSessionController::store` hacía `redirect()->intended(...)` y aterrizaba ahí en lugar de en `/dashboard`.

## Causa raíz

La autenticación estaba dividida entre dos sistemas:

- **Guard `web`** -> tabla `usuario` (`Usuario`) + flag `is_admin` (sistema nuevo).
- **Guard `admin`** -> tabla `admins` (`Admin`), separada (sistema legacy).

El **login** del admin usaba el guard `admin`, pero las **páginas protegidas** usaban el guard `web`. Esa incoherencia provocaba ambos bugs. **Solución:** unificar todo en el guard `web`+`is_admin` y eliminar el guard legacy.

## Problemas adicionales resueltos

| # | Problema | Solución |
|---|---|---|
| 2 | El mutator `nombre()` de `Usuario` **nunca se aplicaba** (silencioso): usaba `Attribute`/`Str` sin importarlos, por lo que Eloquent no lo reconocía y la normalización de nombres no ocurría. | Añadidos los imports correctos. |
| 4 | **Código muerto** del guard `admin` legacy tras la unificación (modelo, guard, provider, seeder, migración, referencias en vistas). | Eliminado por completo. |
| 5 | `is_admin` estaba en `$fillable` -> riesgo de **asignación masiva** (un usuario podría auto-asignarse admin si algún código usara `fill($request->all())`). | Sacado de `$fillable`; se asigna solo de forma explícita. |

## Cambios por fichero

**Bugs 1 y 2 — unificación de login en guard `web`:**

- `app/Http/Controllers/Admin/Auth/LoginController.php` — `showLoginForm`, `login` y `logout` migrados del guard `admin` al `web`; `login` autentica `Usuario` por `nombre` (fallback a email) y exige `is_admin`; rechaza a no-admins. Redirección directa a `admin.dashboard` (sin `intended()`).
- `app/Http/Controllers/Auth/AuthenticatedSessionController.php` — `store()` ahora redirige **siempre** a `route('dashboard')`.
- `routes/web.php` — ruta `/admin/` simplificada a `is_admin` (sin consultar la tabla legacy).

**Problemas 2 y 5 — modelo `Usuario`:**

- `app/Models/Usuario.php` — imports de `Attribute` y `Str`; `is_admin` fuera de `$fillable`.

**Problema 4 — eliminación del guard legacy:**

- Eliminados: `app/Models/Admin.php`, `database/seeders/AdminSeeder.php`, `database/migrations/..._create_admins_table.php`.
- `config/auth.php` — eliminados guard `admin` y provider `admins`.
- `database/seeders/DatabaseSeeder.php` — quitado `AdminSeeder`.
- `resources/views/layouts/admin.blade.php` y `resources/views/admin/dashboard.blade.php` — eliminadas referencias a `Auth::guard('admin')`.

**Tests:**

- `tests/Feature/AltaPlataformaTest.php` — migrado al guard `web`+`is_admin` (helper `adminUser()` crea un `Usuario` admin; `actingAs($admin)`; el caso de no-admin ahora espera `403`, que es lo que devuelve el middleware `EsAdmin`).

## Verificación

- **Tests:** `php artisan test` -> 23 tests arreglados, 0 regresiones (`AltaPlataformaTest`: 25 verdes).
- **Smoke test E2E** contra el servidor (`docker-compose.server.yml`):
  - `/admin/login` sin sesión -> **200** (sin bucle).
  - `/login` con admin (tras visitar `/admin/dashboard`) -> **`/dashboard`**.
  - Login admin por `/admin/login` -> `/admin/dashboard` -> **200**.
  - No-admin en `/admin/login` -> rechazado.
- Mutator: `"juan.gómez º"` -> `"Juangómez"`.
- Mass-assignment: `fill(['is_admin'=>true])` -> `null` (bloqueado).

**Credenciales** (ambas vías usan ya la tabla `usuario`): `/admin/login` y `/login` con **Admin / 12345678**.

## Notas para el revisor

- La tabla `admins` ya existente en BBDD queda **huérfana** (inofensiva). Eliminarla con `DROP TABLE admins;` o `migrate:fresh`.
- **Pendiente (fuera de alcance):** `/register` está roto (referencia a una clase `User` inexistente) y sigue público — recomendable eliminarlo o reescribirlo en un PR aparte. También quedan los tests scaffold de Breeze sin adaptar.
- `database/seeders/UsuarioSeeder.php` y `docker-compose.server.yml` aparecen modificados en el working tree pero **no forman parte de este trabajo** (cambios previos); revisar si deben entrar en este PR o no.
