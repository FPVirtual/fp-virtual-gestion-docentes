# Arquitectura de la aplicación

Este documento describe la arquitectura general, las capas de la aplicación y los flujos principales del proyecto **fp-virtual-gestion-docentes**, una aplicación Laravel para la gestión del profesorado de FP Virtual en Aragón.

---

## 1. Visión general

La aplicación sigue una arquitectura **monolítica en capas**, típica de Laravel, separando claramente:

- **Presentación**: vistas Blade, componentes, assets con Vite y Tailwind CSS.
- **Aplicación / HTTP**: controladores, form requests, middleware y rutas.
- **Dominio**: modelos Eloquent, servicios y lógica de negocio.
- **Datos**: base de datos relacional (MariaDB/MySQL en producción, SQLite en tests) gestionada mediante migraciones y seeders.

El patrón de diseño subyacente es **MVC (Modelo-Vista-Controlador)** con algunos elementos de **Domain-Driven Design** ligero, como la extracción de lógica de negocio a servicios (`GeneradorEmailVirtualService`) y el uso de modelos ricos con relaciones explícitas.

```mermaid
flowchart TB
    subgraph CLIENTE["Cliente (navegador)"]
        A[HTML / Blade + Alpine.js]
    end

    subgraph PRESENTACION["Capa de presentación"]
        B[Vistas Blade]
        C[Componentes Blade]
        D[Vite + Tailwind CSS + Alpine.js]
    end

    subgraph APLICACION["Capa de aplicación"]
        E[Rutas web.php / auth.php]
        F[Middleware auth / es_admin]
        G[Form Requests]
        H[Controladores]
    end

    subgraph DOMINIO["Capa de dominio"]
        I[Modelos Eloquent]
        J[Servicios]
        K[Comandos Artisan]
        L[Mailables]
    end

    subgraph DATOS["Capa de datos"]
        M[Migraciones]
        N[Seeders / Factories]
        O[(MariaDB / MySQL / SQLite)]
    end

    A --> B
    B --> E
    E --> F
    F --> G
    G --> H
    H --> I
    H --> J
    H --> K
    H --> L
    I --> O
    J --> I
    M --> O
    N --> O
```

---

## 2. Stack tecnológico

| Capa | Tecnología | Versión / Detalle |
|------|------------|-------------------|
| Backend | PHP | `^8.2` |
| Framework | Laravel | `^12.0` |
| Base de datos | MariaDB | `10.11` (también compatible MySQL) |
| Auth | Laravel Breeze | scaffolding con Blade |
| Frontend | Blade + Tailwind CSS + Alpine.js | Vite compila assets |
| Bundler | Vite | `^6.3.2` |
| CSS | Tailwind CSS | `3.4.17` |
| Tests | Pest | `^3.8` con plugin Laravel |
| Formateo | Laravel Pint | `^1.21` |
| Contenedores | Docker + Docker Compose | perfiles local y servidor |

---

## 3. Estructura de directorios

```text
app/
├── Console/Commands/           # Comandos Artisan propios
├── Http/
│   ├── Controllers/            # Controladores web
│   │   ├── Admin/              # Panel de administración
│   │   └── Auth/               # Autenticación de Breeze
│   ├── Middleware/             # Middleware (EsAdmin, …)
│   ├── Requests/               # Form requests
├── Mail/                       # Mailables
├── Models/                     # Modelos Eloquent
├── Services/                   # Lógica de negocio reutilizable
└── View/Components/            # Componentes Blade

bootstrap/                      # Inicio de la aplicación
config/                         # Configuración de Laravel
database/
├── factories/                  # Factories para tests
├── migrations/                 # Migraciones
└── seeders/                    # Seeders

lang/es/                        # Traducciones en español
public/                         # Punto de entrada web
resources/
├── css/app.css                 # Directivas Tailwind
├── js/app.js                   # Alpine.js
└── views/                      # Vistas Blade

routes/
├── web.php                     # Rutas principales
├── auth.php                    # Rutas de autenticación Breeze
└── console.php                 # Tareas programadas

tests/                          # Tests con Pest
```

---

## 4. Capa de presentación

La capa de presentación está construida con **Blade**, **Tailwind CSS** y **Alpine.js**. Vite se encarga de compilar los assets.

### Layouts principales

| Layout | Uso |
|--------|-----|
| `layouts/app.blade.php` | Panel de centro |
| `layouts/guest.blade.php` | Login/registro invitado |
| `layouts/app-admin.blade.php` | Panel de administración |
| `layouts/admin.blade.php` | Navegación del panel admin |
| `layouts/navigation.blade.php` | Menú del panel de centro |

### Vistas principales

- **Centro**: `alta_docente`, `baja_docente`, `establecer_docencia`, `establecer_tutor`, `establecer_coordinador`, `dashboard`.
- **Admin**: `admin/login`, `admin/dashboard`, `admin/ver_docentes`, `admin/ver_centros`, `admin/alta_plataforma`.
- **Auth Breeze**: `auth/login`, `auth/register`, `auth/forgot-password`, etc.

```mermaid
flowchart LR
    subgraph VISTAS["Vistas Blade"]
        V1[Panel de centro]
        V2[Gestión docente]
        V3[Panel admin]
        V4[Auth Breeze]
    end

    subgraph COMPONENTES["Componentes / Layouts"]
        C1[layouts/app]
        C2[layouts/app-admin]
        C3[components/*]
    end

    subgraph ASSETS["Assets"]
        A1[Vite]
        A2[Tailwind CSS]
        A3[Alpine.js]
    end

    VISTAS --> COMPONENTES
    COMPONENTES --> ASSETS
```

---

## 5. Capa de aplicación

### 5.1. Rutas

Las rutas se definen en tres archivos:

- `routes/web.php`: rutas principales de la aplicación (centro y admin).
- `routes/auth.php`: rutas de autenticación de Laravel Breeze.
- `routes/console.php`: tareas programadas.

```mermaid
flowchart TB
    subgraph RUTAS["Rutas"]
        W[web.php]
        A[auth.php]
        C[console.php]
    end

    subgraph GRUPOS["Grupos de rutas"]
        G1[/ Públicas /]
        G2[/ auth /]
        G3[/ auth + es_admin /]
    end

    W --> G1
    W --> G2
    W --> G3
    A --> G2
    C --> |Scheduler| G4[Comandos Artisan]
```

### 5.2. Middleware

| Middleware | Función |
|------------|---------|
| `auth` | Protege rutas para usuarios autenticados. |
| `es_admin` | Aborta con 403 si el usuario no tiene `is_admin = true`. |
| `verified` | Requiere email verificado (Breeze). |

### 5.3. Controladores

```mermaid
flowchart TB
    subgraph CONTROLLERS["Controladores"]
        subgraph AUTH["Auth"]
            AC1[AuthenticatedSessionController]
            AC2[RegisteredUserController]
            AC3[NewPasswordController]
            AC4[PasswordResetLinkController]
            AC5[ProfileController]
        end

        subgraph ADMIN["Admin"]
            AD1[LoginController]
            AD2[CentroController]
            AD3[DocenteController]
            AD4[AltaPlataformaController]
        end

        subgraph CENTRO["Centro"]
            CE1[AltaDocenteController]
            CE2[BajaDocenteController]
            CE3[EstablecerDocenciaController]
            CE4[EstablecerTutorController]
            CE5[EstablecerCoordinadorController]
        end
    end
```

---

## 6. Capa de dominio

### 6.1. Modelos Eloquent

La aplicación utiliza modelos con claves primarias explícitas cuando no son autoincrementales enteras.

```mermaid
erDiagram
    CENTRO ||--o{ USUARIO : "tiene"
    CENTRO ||--o{ CENTRO_CICLO : "imparte"
    CICLO ||--o{ CENTRO_CICLO : ""
    CICLO ||--o{ CICLO_MODULO : "contiene"
    MODULO ||--o{ CICLO_MODULO : ""
    DOCENTE ||--o{ CENTRO_DOCENTE : "pertenece"
    CENTRO ||--o{ CENTRO_DOCENTE : ""
    DOCENTE ||--o{ DOCENTE_MODULO_CICLO : "imparte"
    CICLO ||--o{ DOCENTE_MODULO_CICLO : ""
    MODULO ||--o{ DOCENTE_MODULO_CICLO : ""
    DOCENTE ||--o{ TUTOR : "es"
    DOCENTE ||--o{ COORDINADOR : "es"
    CENTRO ||--o{ TUTOR : ""
    CICLO ||--o{ TUTOR : ""
    CENTRO ||--o{ COORDINADOR : ""
    CICLO ||--o{ COORDINADOR : ""

    CENTRO {
        string id_centro PK
        string nombre
    }

    CICLO {
        string id_ciclo PK
        string nombre
    }

    MODULO {
        string id_modulo PK
        string nombre
        int horas
    }

    DOCENTE {
        int id PK
        string dni UK
        string nombre
        string apellido
        string email_virtual UK
        boolean de_baja
        boolean formacion
        boolean is_procesado
        timestamp fecha_procesado
    }

    USUARIO {
        int id PK
        string nombre
        string email UK
        string password
        boolean is_admin
        string id_centro FK
    }

    CENTRO_DOCENTE {
        string id_centro PK,FK
        string dni PK,FK
        string email
    }

    DOCENTE_MODULO_CICLO {
        int id PK
        string id_centro FK
        string id_ciclo FK
        string id_modulo FK
        string dni FK
    }

    TUTOR {
        int id PK
        string id_centro FK
        string id_ciclo FK
        string dni FK
    }

    COORDINADOR {
        int id PK
        string id_centro FK
        string id_ciclo FK
        string dni FK
    }
```

### 6.2. Servicios

| Servicio | Responsabilidad |
|----------|-----------------|
| `GeneradorEmailVirtualService` | Genera emails `@fpvirtualaragon.es` a partir de nombre y apellidos, normalizando caracteres y resolviendo colisiones. |

### 6.3. Comandos y tareas programadas

- `docentes:enviar-resumen-bajas`: lee el log de bajas y envía un resumen semanal por email. Programado los lunes a las 08:00 h (Europe/Madrid).

---

## 7. Flujo de autenticación

La aplicación tiene dos puntos de entrada sobre el mismo guard `web`:

1. **Login de centro** (`/login`): el campo de usuario es el **código del centro** (8 dígitos).
2. **Login de admin** (`/admin/login`): el usuario es `Admin` y debe tener `is_admin = true`.

```mermaid
sequenceDiagram
    actor U as Usuario
    participant N as Navegador
    participant R as Rutas
    participant C as Controlador
    participant M as Middleware
    participant DB as Base de datos

    U->>N: Accede a /login o /admin/login
    N->>R: GET /login
    R->>C: AuthenticatedSessionController / LoginController
    C-->>N: Muestra formulario

    U->>N: Envía credenciales
    N->>R: POST /login o /admin/login
    R->>C: Auth::attempt(nombre/password)
    C->>DB: Verifica usuario
    DB-->>C: Usuario encontrado

    alt Login de admin
        C->>M: EsAdmin
        M->>C: is_admin === true
        C-->>N: Redirige a /admin/dashboard
    else Login de centro
        C-->>N: Redirige a /dashboard
    end
```

---

## 8. Flujo de alta de docente

```mermaid
sequenceDiagram
    actor U as Usuario de centro
    participant V as Vista alta_docente
    participant C as AltaDocenteController
    participant S as GeneradorEmailVirtualService
    participant D as Modelo Docente
    participant CD as Modelo CentroDocente
    participant DB as Base de datos

    U->>V: Accede a /alta-docente
    V->>C: GET /alta-docente
    C-->>V: Renderiza formulario

    U->>V: Introduce DNI
    V->>C: GET /comprobar-docente/{dni}
    C->>D: Busca por DNI
    D->>DB: SELECT
    DB-->>D: Resultado
    D-->>C: Datos del docente (si existe)
    C-->>V: JSON con existe/nombre/apellido/email

    U->>V: Escribe nombre/apellido
    V->>C: GET /alta-docente/preview-email
    C->>S: previsualizarEmail(nombre, apellido)
    S-->>C: Email propuesto
    C-->>V: JSON con email preview

    U->>V: Envía formulario
    V->>C: POST /alta-docente
    C->>C: Valida DNI español
    C->>D: Busca por DNI
    alt Docente existe
        C->>D: Actualiza nombre/apellido si cambian
        C->>S: generarOObtenerExistente
        S-->>C: Email virtual
        C->>D: Reactiva si estaba de baja
    else Docente nuevo
        C->>S: generarOObtenerExistente
        S-->>C: Email virtual
        C->>D: Crea nuevo docente
    end
    C->>CD: Crea/actualiza relación centro-docente con email personal
    CD->>DB: INSERT/UPDATE
    C-->>V: Redirige a establecer-docencia
```

---

## 9. Flujo de baja de docente

```mermaid
sequenceDiagram
    actor U as Usuario de centro
    participant V as Vista baja_docente
    participant C as BajaDocenteController
    participant D as Modelo Docente
    participant L as Canal bajas_docentes
    participant DB as Base de datos

    U->>V: Accede a /docentes/baja
    V->>C: GET /docentes/baja
    C->>DB: Lista docentes del centro
    C-->>V: Renderiza tabla con indicadores

    U->>V: Pulsa "Dar de baja"
    V->>C: POST /docentes/baja/{dni}
    C->>D: Busca docente
    C->>D: Marca de_baja = true
    D->>DB: UPDATE
    C->>L: Escribe entrada de auditoría
    C-->>V: Redirige con mensaje de éxito

    U->>V: Pulsa "Reactivar"
    V->>C: POST /docentes/reactivar/{dni}
    C->>D: Marca de_baja = false
    D->>DB: UPDATE
    C->>L: Escribe entrada de reactivación
    C-->>V: Redirige con mensaje
```

---

## 10. Flujo de alta en plataformas (Google Workspace / Moodle)

```mermaid
sequenceDiagram
    actor A as Administrador
    participant V as Vista alta_plataforma
    participant C as AltaPlataformaController
    participant D as Modelo Docente
    participant CD as CentroDocente
    participant JS as Alpine.js (frontend)

    A->>V: Accede a /admin/alta-plataforma
    V->>C: GET /admin/alta-plataforma
    C->>D: Filtra docentes activos con email_virtual
    D-->>C: Colección paginada
    C-->>V: Renderiza tabla + docentesJson

    A->>V: Pulsa "Preview CSV"
    V->>C: GET /admin/alta-plataforma/{id}/preview
    C->>D: Datos del docente
    C->>CD: Email personal del centro
    C-->>V: JSON con google_csv y moodle_csv (29 columnas)

    A->>V: Descarga CSV
    V->>JS: Genera blob y descarga archivo

    A->>V: Marcar como procesados
    V->>C: POST /admin/alta-plataforma/procesar
    C->>D: Actualiza is_procesado = true
    D->>DB: UPDATE
    C-->>V: JSON { ok: true, procesados: N }
```

---

## 11. Flujo de asignación de docencia, tutoría y coordinación

```mermaid
flowchart LR
    U[Usuario de centro] --> E1[/alta-docente/]
    E1 --> E2[/establecer-docencia/]
    E2 --> E3[Asignar módulos-ciclo]
    U --> T[/establecer-tutor/]
    T --> T1[Asignar tutor por ciclo]
    U --> C[/establecer-coordinador/]
    C --> C1[Asignar coordinador por ciclo]
    C1 -->|También es tutor| T1
```

---

## 12. Comunicación entre capas

```mermaid
flowchart TB
    subgraph FRONT["Frontend"]
        F1[Blade + Alpine.js]
        F2[Vite / Tailwind]
    end

    subgraph HTTP["HTTP / Aplicación"]
        H1[Rutas]
        H2[Middleware]
        H3[Requests]
        H4[Controladores]
    end

    subgraph DOM["Dominio"]
        D1[Modelos Eloquent]
        D2[Servicios]
        D3[Comandos]
        D4[Mail]
    end

    subgraph DATA["Datos"]
        DB[(Base de datos)]
        LOG[Logs / Archivos]
    end

    F1 --> H1
    H1 --> H2 --> H3 --> H4
    H4 --> D1
    H4 --> D2
    H4 --> D3
    H4 --> D4
    D1 --> DB
    D3 --> LOG
    D4 --> LOG
    D2 --> D1
```

---

## 13. Despliegue y contenedores

La aplicación puede ejecutarse de dos formas principales:

1. **Desarrollo local**: `composer dev` levanta servidor Laravel, Vite, worker de colas y logs en vivo.
2. **Servidor/Docker**: `docker-compose.server.yml` construye la imagen y despliega app + base de datos.

```mermaid
flowchart TB
    subgraph DESARROLLO["Desarrollo local"]
        D1[php artisan serve]
        D2[npm run dev]
        D3[php artisan queue:listen]
        D4[php artisan pail]
    end

    subgraph DOCKER["Docker servidor"]
        I1[Imagen php:8.2-fpm]
        I2[Nginx / PHP-FPM]
        I3[MariaDB]
        I4[Supervisor]
    end

    subgraph PROD["Producción"]
        P1[APP_ENV=production]
        P2[Config/Route/View cache]
        P3[HTTPS forzado]
    end

    DESARROLLO --> DOCKER --> PROD
```

---

## 14. Resumen de capas

| Capa | Componentes principales | Responsabilidad |
|------|-------------------------|-----------------|
| Presentación | Blade, Tailwind, Alpine.js, Vite | Renderizar la interfaz de usuario y gestionar interacciones ligeras. |
| Aplicación | Rutas, middleware, requests, controladores | Recibir peticiones HTTP, validar entrada, orquestar respuestas. |
| Dominio | Modelos Eloquent, servicios, comandos, mailables | Encapsular la lógica de negocio y las reglas del dominio. |
| Datos | Migraciones, seeders, factories, base de datos | Persistir y recuperar información de forma estructurada. |

Esta arquitectura permite mantener una separación clara de responsabilidades, facilitando el mantenimiento, la extensión futura y la cobertura de tests del proyecto.
