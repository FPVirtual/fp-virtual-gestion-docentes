# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development (runs PHP server + queue + log watcher + Vite concurrently)
composer dev

# Frontend only
npm run dev        # dev server
npm run build      # production build

# Testing
php artisan test                            # all tests (Pest)
php artisan test --filter TestName          # single test
./vendor/bin/pest tests/Feature/SomeTest.php  # run specific file

# Database
php artisan migrate:fresh --seed           # reset and reseed DB
php artisan migrate                        # run pending migrations

# Code style
./vendor/bin/pint                          # fix code style (Laravel Pint)

# Docker
docker compose up -d    # start all services; app available at localhost:8082
```

## Architecture

**Stack:** Laravel 12 / PHP 8.2 · Blade templates · Tailwind CSS · Alpine.js · MySQL · Vite

**Two login entry points:**
- `/login` — regular users (coordinators, tutors)
- `/admin/login` — admin panel

**Authentication:** Session-based (stored in DB). The `web` guard uses the `Usuario` model with an `is_admin` boolean flag. A legacy `admin` guard uses a separate `Admin` model. The `EsAdmin` middleware checks `auth()->user()->is_admin` for all `/admin/*` routes.

**User-facing modules** (all require auth, defined in `routes/web.php`):
| Route | Purpose |
|---|---|
| `alta-docente` | Register a new teacher; auto-generates `@fpvirtualaragon.es` email |
| `docentes/baja` | Deactivate / reactivate a teacher |
| `establecer-coordinador` | Assign/remove coordinator role per center-cycle |
| `establecer-tutor` | Assign/remove tutor role |
| `establecer-docencia` | Assign teaching duties (cycle + module) |

**Admin panel** (`/admin/*` prefix): teacher and center listing with CSV export, bulk platform enrollment (`alta-plataforma`).

**Key service:** `app/Services/GeneradorEmailVirtualService.php` generates virtual email addresses from teacher names — applies transliteration (ñ→n, accented chars), builds `initials(nombres) + primer_apellido + inicial(segundo_apellido)`, and appends a numeric suffix on collision.

**Models** (`app/Models/`): `Usuario`, `Docente`, `Centro`, `Ciclo`, `Modulo`, `Tutor`, `Coordinador`, `Docencia`, `Imparte`, `CentroDocente`, `CentroCiclo`, `CicloModulo`, `DocenteCicloModulo`, `Admin`.

**Localization:** All user-facing strings are in Spanish; translation files are in `lang/es/`.
