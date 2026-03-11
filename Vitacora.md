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

- Conexión entre mi ordenador y la base de datos: Mi ordenador no podía "hablar" con la base de datos porque estaba dentro de Docker. Lo arreglé abriendo un túnel en el puerto 23306, así puedo gestionar los datos de la base de datos instituto (con usuario y contraseña alumno/alumno) directamente desde mi entorno local.

- Problemas para acceder al panel (Login): Al intentar entrar, el sistema rechazaba mis datos. Me di cuenta de que estaba intentando usar cuentas que no existían todavía. Lo solucioné revisando los seeders del proyecto y usando los correos y contraseñas oficiales que ya venían preparados en la base de datos para las pruebas.

- Error al asignar clases a los profesores: El sistema daba un error de "integridad" si intentaba ponerle módulos a un profesor antes de que estuviera registrado en la tabla principal. He reordenado el código para que primero se cree el profesor y, justo después, se le asigne toda su docencia de golpe.

- El programa no sabía en qué centro estaba: Antes, al dar de alta a un profesor, el sistema se perdía porque le faltaba el dato del centro. Ahora el programa es más automático: detecta qué usuario ha entrado y asigna al profesor directamente a su mismo centro educativo.

Limpieza de nombres y apellidos: Había nombres que aparecían con puntos o símbolos como "º" que ensuciaban la lista. He creado un filtro que limpia esos símbolos y pone siempre la primera letra en mayúscula para que todo el listado se vea uniforme.
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
Documentacion de lo que vamos haciendo:


