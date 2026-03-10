---

# Gestión de Personal Docente - FP Virtual

Sistema integral para la gestión de altas, bajas y asignación de docencia en centros educativos, optimizado para entornos de Formación Profesional.

## Configuración del Entorno de Pruebas

Para este proyecto se han modificado los ficheros de configuración base con el fin de adaptar el sistema a un entorno de pruebas controlado:

* **docker-compose.yml**: Personalización de los servicios de red y volúmenes para facilitar la persistencia de datos durante los tests.
* **.env**: Configuración de variables de entorno específicas para la conexión con el contenedor de base de datos MySQL en Docker.

---

## Infraestructura (Docker)

El proyecto está completamente contenerizado para asegurar un entorno de desarrollo idéntico al de producción.

* **PHP 8.4 + Nginx**: Servidor de aplicaciones optimizado.
* **MySQL 8.0**: Motor de base de datos relacional.
* **phpMyAdmin**: Gestión de base de datos integrada en el puerto 8080.

### Levantamiento del entorno

Para poner en marcha el proyecto y el servidor, ejecute los siguientes comandos en orden:

```bash
docker-compose up -d
php artisan migrate --seed
npm run build
npm run dev
```

---

## Retos Técnicos y Soluciones

A continuación se detallan los principales problemas encontrados durante el desarrollo y las soluciones técnicas implementadas:

| Problema | Causa Raíz | Solución Implementada |
| --- | --- | --- |
| **Error de Conexión DB** | El archivo `.env` apuntaba a `127.0.0.1` en lugar del nombre del servicio en Docker. | Se configuró `DB_HOST=db` para permitir la comunicación interna entre los contenedores de Docker. |
| **Violación de Integridad (1452)** | Intento de insertar asignaciones de módulos antes de que el docente existiera en la tabla principal. | Se reestructuró la lógica del controlador para asegurar la creación del registro "Padre" (Docente) antes que cualquier relación "Hijo". |
| **Campos Obligatorios (1364)** | La tabla relacional requería `id_centro` pero el formulario no lo enviaba explícitamente. | Se implementó la recuperación automática del `id_centro` mediante el objeto `Auth::user()` para garantizar la integridad de los datos. |
| **Datos Corruptos en Nombres** | Entrada de usuarios con caracteres especiales como `º` o `.` que ensuciaban los listados. | Creación de un método de sanitización en el controlador que limpia los strings y aplica formato `Title Case` automáticamente. |
| **Falsas Alarmas en Docencia** | El sistema contaba a docentes de baja como "activos", dando avisos erróneos de sobreasignación. | Se añadieron filtros `where('de_baja', false)` en las consultas de conteo y en los desplegables de selección. |

---

## Características Principales

### 1. Normalización y Sanitización de Datos

* **DNI**: Estandarización automática a mayúsculas para asegurar la integridad de las relaciones y evitar duplicados.
* **Nombres/Apellidos**: Limpieza de símbolos y formateo automático:

```php
private function normalizarNombreYApellido($string) {
    $limpio = str_replace(['º', '.'], '', $string);
    return mb_convert_case(mb_strtolower($limpio, 'UTF-8'), MB_CASE_TITLE, 'UTF-8');
}

```

### 2. Buscador en Tiempo Real (UX)

Uso de **Alpine.js** para el filtrado instantáneo de tablas. Permite localizar docentes por nombre o DNI sin realizar peticiones adicionales al servidor, optimizando el rendimiento.

### 3. Sistema de "Soft Delete" y Reactivación

Gestión de estados mediante el campo `de_baja` para mantener la integridad histórica:

* **Dar de baja**: Desactiva al docente mediante un modal de confirmación con Alpine.js.
* **Reactivar**: Botón dinámico que permite reincorporar al personal con un solo clic, reactivando su estado en la base de datos.

---

## Estado del Proyecto

* [x] **Tarea A, B, C**: Altas con validación de DNI/Email.
* [x] **Tarea D**: Sistema de Bajas y Reactivaciones.
* [x] **Tarea G**: Normalización de nombres mediante `str_replace`.

---
