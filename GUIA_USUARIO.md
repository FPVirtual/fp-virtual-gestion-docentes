# Guía de Usuario — Gestión del Profesorado de FP Virtual en Aragón

Guía completa de uso de la aplicación web `gestionprof.fpvirtualaragon.es`, destinada a la gestión del profesorado de los centros de FP Virtual en Aragón: altas de docentes, generación automática de correos `@fpvirtualaragon.es`, asignación de roles (coordinador, tutor) y docencias, y exportación de altas masivas para Google Workspace y Moodle.

---

## 1. Introducción

### 1.1 ¿Qué permite hacer la aplicación?

- **Dar de alta docentes** en el sistema, con generación automática de un correo institucional `@fpvirtualaragon.es`.
- **Dar de baja y reactivar** docentes de tu centro.
- **Asignar roles**: coordinador y tutor por centro-ciclo.
- **Asignar docencias**: qué módulo de qué ciclo imparte cada docente.
- **Panel de administración**: consultar el listado completo de docentes y centros/ciclos, ver su información detallada y **exportar CSV** para altas masivas en **Google Workspace** y **Moodle**.
- **Informe semanal de bajas**: los administradores reciben por correo un resumen de las bajas y reactivaciones registradas en la semana.

### 1.2 Tipos de usuarios

| Tipo | Cómo se identifica | Qué puede hacer |
|---|---|---|
| **Usuario de centro** | Su código de centro de 8 dígitos | Gestionar los docentes de su centro: altas, bajas, reactivaciones, coordinadores, tutores y docencias. |
| **Administrador** | Usuario `is_admin = true` (p. ej. `Admin`) | Todo lo anterior (aunque su panel es el de administración) más: listados globales de docentes y centros, información detallada y exportación de CSV de altas masivas. |

> Las credenciales de desarrollo se documentan en `DESARROLLO.md`. La contraseña inicial de un usuario de centro coincide con su código de centro y debe cambiarse desde el perfil.

---

## 2. Acceso al sistema

### 2.1 Login de usuario de centro (`/login`)

1. Abre la aplicación; serás redirigido a la pantalla **"Acceso al Sistema"**.
2. Introduce:
   - **Nombre de usuario**: tu **código de centro de 8 dígitos** (p. ej. `22002491`).
   - **Contraseña**: inicialmente, el propio código de centro.
   - Marca **Recordar sesión** si quieres mantener la sesión abierta.
3. Pulsa **Acceder**. Accederás siempre al **Panel de Gestión Docente**.

**¿Olvidaste tu contraseña?** El enlace **"¿Olvidaste tu contraseña?"** abre el flujo de restablecimiento: introduce el **correo electrónico** asociado a la cuenta (no el código de centro) y recibirás un enlace para crear una nueva contraseña. (Nota: algunos textos de esta pantalla aparecen en inglés.)

### 2.2 Login de administración (`/admin/login`)

Pantalla independiente **"Acceso Administrador"**:

1. Introduce **Usuario** y **Contraseña** (en desarrollo: `Admin` / `12345678`).
2. Pulsa **Acceder**.

El sistema exige que la cuenta tenga el flag de administrador; si las credenciales son válidas pero la cuenta no es administradora, el acceso se rechaza. Desde el panel de administración se cierra sesión con **Cerrar sesión** del menú de usuario.

---

## 3. Navegación

### 3.1 Menú de usuario de centro

La barra superior muestra el logo de FP Virtual y los siguientes enlaces:

- **Panel Usuario** — vuelve al panel principal.
- **Alta Docente** — alta de un docente.
- **Establecer docencia** — asignar docencia.
- **Baja Docente** — bajas y reactivaciones.
- **Alta Plataforma** — visible solo si tu cuenta es administradora; enlaza con la exportación masiva.
- Menú desplegable con tu nombre: **Perfil** (datos de la cuenta y cambio de email/contraseña) y **Cerrar sesión**.
- En el menú de móvil (hamburguesa) existe además el grupo **"Establecer"** con **Coordinador/es**, **Tutor/es** y **Docencia**. En pantallas de escritorio, las pantallas de coordinador y tutor no aparecen enlazadas en el menú, pero son funcionales si se accede directamente a `/establecer-coordinador` y `/establecer-tutor`.

### 3.2 Menú de administración

- **Panel Administración** — panel principal.
- **Ver Docentes** — listado global de docentes.
- **Ver Centros** — listado global de centros y ciclos.
- **Alta Plataforma** — generación de CSV de altas masivas.
- Menú de usuario con **Cerrar sesión**.

---

## 4. Panel de Gestión Docente (`/dashboard`)

Pantalla de bienvenida con el mensaje *"Bienvenido {nombre} aquí podrás gestionar tu actividad."* y tarjetas de acceso rápido:

- **Dar alta docente** → `/alta-docente`
- **Establecer docencia** → `/establecer-docencia`
- **Baja Docente** → `/docentes/baja`

---

## 5. Alta de docente (`/alta-docente`)

Pantalla **"Dar Alta Docente"**: *"Complete el siguiente formulario para dar de alta a un docente en el sistema."*

### 5.1 Campos del formulario

| Campo | Descripción |
|---|---|
| **DNI** | Documento de identidad. Formato `12345678A` o NIE `X1234567A` (máx. 10 caracteres). Al salir del campo, el sistema comprueba automáticamente si el docente ya existe (ver 5.2). |
| **Correo Electrónico (NO USAR el de @fpvirtualaragon.es)** | Correo personal del docente (p. ej. `docente@centro-educativo.com`). |
| **Nombre** | Nombre del docente. |
| **Apellidos** | Todos los apellidos del docente. |
| **Correo @fpvirtualaragon.es (generado automáticamente)** | Campo de **solo lectura**. Se previsualiza en vivo mientras escribes nombre y apellidos. No es editable: el correo se asigna automáticamente. |

El campo **centro** no aparece: se toma del usuario que está dando el alta.

### 5.2 Autocompletado por DNI (AJAX)

Al completar el campo **DNI** y salir de él:

- Si el docente **ya existe** en el sistema:
  - Se **autocompletan y bloquean** Nombre, Apellidos y Correo Electrónico.
  - Aparece un icono de **candado** sobre los campos bloqueados; pulsarlo permite **desbloquearlos y corregirlos**.
  - Se muestra un aviso: *"Docente encontrado. Revisa y corrige el email si es necesario."*
- Si **no existe**, los campos quedan libres para rellenarlos.

### 5.3 Generación del correo virtual

Mientras escribes el nombre y los apellidos, se muestra en tiempo real el correo `@fpvirtualaragon.es` que se asignará. El algoritmo (`GeneradorEmailVirtualService`) construye:

**iniciales del nombre + primer apellido + inicial del segundo apellido**, transliterado a ASCII (sin acentos ni ñ) y con un sufijo numérico en caso de colisión.

Ejemplo: `Dario Axel Ureña Garcia` → `daurenag@fpvirtualaragon.es`.

El nombre y los apellidos se normalizan automáticamente al guardar (se eliminan caracteres como `º` y `.`, y se ajustan las mayúsculas).

### 5.4 Guardar

- Pulsa **Guardar docente**.
- Si el docente ya estaba asignado a tu centro, verás el error *"Este docente ya está asignado a este centro."*
- Si el docente existía pero estaba de baja, el alta lo **reactiva** automáticamente.
- Al finalizar, se redirige a **Establecer docencia** con el docente ya preseleccionado y el mensaje *"Docente asignado correctamente."*, para que puedas asignarle su docencia de inmediato.
- **Volver al panel** regresa al dashboard sin guardar.

---

## 6. Baja y reactivación de docentes (`/docentes/baja`)

Pantalla **"Dar de baja a docentes"**: *"Busca un docente y confirma su baja del centro."*

1. Usa el buscador **"Buscar docentes..."** para filtrar en vivo por nombre, apellido o DNI (con contador *"Mostrando X de Y docentes"*; la tecla `Escape` o la × limpian la búsqueda).
2. La tabla muestra **Nombre | Apellido | DNI | Acción** con los docentes de tu centro:
   - **Docente activo** → botón rojo con papelera (**Dar de baja**). Abre el modal **"Confirmar baja"**: *"El docente {nombre} dejará de estar activo en el centro. ¿Estás seguro?"*. Confirma con **Sí, dar de baja** o cancela.
   - **Docente de baja** → botón verde **Reactivar** (**Volver a dar de alta**), que reactiva directamente sin modal.

Mensajes de resultado: *"Docente dado de baja correctamente."* o *"El docente {nombre} ha sido reactivado y ya puede acceder al sistema."*

Las bajas y reactivaciones quedan registradas en el log de auditoría y se incluyen en el **informe semanal de bajas** que reciben los administradores por correo.

---

## 7. Establecer coordinador (`/establecer-coordinador`)

Pantalla **"Establecer Coordinador/es"**: *"Complete el siguiente formulario para establecer o borrar un coordinador."*

### 7.1 Asignar un coordinador

1. **Seleccionar Coordinador**: docentes de tu centro (formato "Nombre Apellidos - DNI").
2. **Seleccionar Ciclo**: ciclos de tu centro.
3. Marca **También es tutor** si el coordinador ejerce además de tutor de ese ciclo.
4. Pulsa **Establecer**.

Reglas y mensajes:

- Solo puede haber **un coordinador por centro-ciclo**. Si el ciclo ya tiene coordinador: *"Ya existe un coordinador asignado a este ciclo."*
- Si marcaste *También es tutor*, se crea también la tutoría si no existía.
- Éxito: *"Coordinador añadido correctamente."*

### 7.2 Listado y borrado

La tabla **"Listado de Coordinadores Actuales"** incluye buscador y columnas ordenables (**Nombre, Apellidos, Ciclo, DNI**; pulsa el encabezado para ordenar).

- Pulsa **Borrar** → modal **"Confirmar eliminación"**: *"¿Estás seguro de que quieres borrar a {nombre} del ciclo {ciclo}?"*
- Si el coordinador también es tutor del ciclo, se advierte *"Este coordinador también es tutor de este ciclo."* y ofrece dos opciones:
  - **Sí, borrar solo como coordinador**
  - **Sí, borrar como coordinador y tutor**
- Mensajes: *"Coordinador eliminado correctamente"* (+ *" y también se ha eliminado como tutor"*).

---

## 8. Establecer tutor (`/establecer-tutor`)

Pantalla **"Establecer Tutor/es"**, idéntica en funcionamiento a la de coordinador:

1. **Seleccionar Ciclo**.
2. **Seleccionar tutor**.
3. Pulsa **Establecer**.

Reglas: un tutor por centro-ciclo. La tabla **"Listado de Tutores Actuales"** tiene buscador y columnas ordenables. Al borrar, si el tutor también es coordinador del ciclo, el modal ofrece borrar **solo como tutor** o **como tutor y coordinador**.

---

## 9. Establecer docencia (`/establecer-docencia`)

Pantalla **"Establecer Docencia"**: *"Complete el siguiente formulario para asignar docencia a un profesor."*

### 9.1 Asignar una docencia

1. **Seleccionar Docente**: docentes **activos** de tu centro (tras un alta, el docente queda preseleccionado).
2. **Seleccionar Ciclo**.
3. **Seleccionar Módulo**: la lista de módulos se ajusta según el ciclo elegido.
4. Pulsa **Establecer**.

Mensajes:

- *"Docencia asignada correctamente."*
- Si el módulo ya tenía docente: *"Docencia asignada correctamente. ¡¡¡ATENCIÓN!!! Este módulo ya tenía un docente asignado por lo que ahora este módulo tiene DOS O MÁS docentes asignados."* (un módulo puede tener varios docentes).

### 9.2 Listado y borrado

La tabla **"Listado de Docencias Actuales"** tiene buscador y columnas ordenables (**Nombre, Apellidos, Ciclo, Módulo, DNI**). Pulsa **Borrar** → modal con el detalle de módulo y ciclo → **Sí, borrar**. Mensaje: *"Docencia eliminada correctamente."*

---

## 10. Perfil de usuario (`/profile`)

Pantalla **"Perfil de Usuario"** con dos secciones:

### 10.1 Información personal

- **ID Centro** y **Nombre**: campos de **solo lectura** (identifican tu cuenta).

### 10.2 Actualizar credenciales

- **Cambiar Correo Electrónico**: escribe el **Nuevo Correo Electrónico** y pulsa **Actualizar Email**. El correo debe ser único en el sistema. Aviso: *"Correo electrónico actualizado correctamente."*
- **Cambiar Contraseña**:
  - **Contraseña Actual**
  - **Nueva Contraseña**
  - **Confirmar Contraseña**
  - Pulsa **Actualizar Contraseña**. Avisos: *"Contraseña actualizada correctamente."* o *"La contraseña actual no es válida."*

---

## 11. Panel de administración

### 11.1 Panel principal (`/admin/dashboard`)

Pantalla **"Panel de Administración"** con accesos directos a **Ver docentes** y **Ver centros**. **Alta Plataforma** se accede desde la barra de navegación.

### 11.2 Gestión de Docentes (`/admin/docentes`)

Pantalla **"Gestión de Docentes"**: *"Listado completo de docentes registrados en el sistema."*

- **Exportar docentes a CSV** (botón verde): descarga `docentes_AAAA-MM-DD.csv` con columnas **Nombre, Apellido, DNI, Emails, Es Tutor, Es Coordinador** (separador `;`, con BOM para abrir correctamente en Excel).
- **Buscador** "Buscar docentes..." con filtrado en vivo.
- Tabla **Nombre | Apellido | DNI | Es Tutor | Es Coordinador | Más Info**, con ✔/✗ en verde/rojo para tutor/coordinador y columnas ordenables por Nombre/Apellido/DNI.
- **Más Info** (🔍) abre el modal **"Información del docente"** con:
  - Datos personales: nombre, correo(s) (enlace mailto; el centro al pasar el ratón), DNI.
  - **Módulos que imparte**, agrupados por centro (tabla Ciclo/Módulo).
  - **Tutor en:** centro y ciclo.
  - **Coordinador en:** centro y ciclo.

### 11.3 Gestión de Centros (`/admin/centros`)

Pantalla **"Gestión de Centros"**: *"Listado completo de centros y ciclos registrados en el sistema."* (una fila por centro-ciclo).

- **Exportar centros a CSV**: descarga `centros_modulos_docentes_AAAA-MM-DD.csv` con columnas **Código Centro, Código Ciclo, Código Módulo, DNI Docente, Nombre Docente, Apellido Docente** — una fila por módulo, con *"SIN DOCENTE"* cuando el módulo no tiene asignación.
- **Buscador** "Buscar centros o ciclos..." y columnas ordenables (código/nombre de centro/ciclo).
- **Más Info** (🔍) abre el modal **"Información del Centro/Ciclo"**:
  - Tarjetas **Centro Educativo** (código y nombre) y **Ciclo Formativo** (código y nombre).
  - **Tutor del Ciclo** y **Coordinador del Ciclo**: nombre, DNI y correo, o *"No hay tutor/coordinador asignado a este ciclo"*.
  - Tabla **Módulos del Ciclo**: código, nombre, docente y su correo (*"Sin asignar"* si no hay docente).

### 11.4 Alta en Plataforma (`/admin/alta-plataforma`)

Pantalla **"Alta en Plataforma"**: *"Selecciona los docentes para generar los CSV de Google Workspace y Moodle."*

Muestra los docentes **activos** que ya tienen correo virtual generado. Los que ya fueron procesados aparecen como **Exportado** (verde) con su fecha; el resto, **Pendiente** (rojo).

**Filtros**: buscar por nombre, apellido o DNI; filtrar por **estado** (Todos / Pendiente de alta / Procesado). Botones **Filtrar** y **Limpiar**.

**Tabla**: checkbox por docente y un checkbox principal para seleccionar todos (paginación de 20 en adelante).

**Ver CSV** (por fila) abre el modal **"Previsualización CSV"** con las dos líneas que se generarían (Google Workspace y Moodle).

**Generar CSVs** (deshabilitado si no hay selección; el pie indica *"N docente(s) seleccionado(s)"*) abre el modal **"Exportar CSVs"**:

- **Descargar CSV Google Workspace** → `alta_google_workspace.csv`
- **Descargar CSV Moodle** → `alta_moodle.csv`

Ambos ficheros usan la cabecera oficial de **29 columnas** de Google Workspace e incluyen: contraseña inicial `Cambiam3!_` (con **cambio obligatorio en el primer inicio de sesión**), unidad organizativa `/Profesorado`, correo personal como *Recovery Email*, DNI como *Employee ID* y estado `Active` (solo en Google).

Después de descargar, elige:

- **Cerrar sin actualizar estado**: solo cierra el modal.
- **Cerrar y actualizar estado**: marca los docentes como procesados (`Exportado` con fecha), para que no vuelvan a aparecer como pendientes. Si falla: *"Error al actualizar el estado. Inténtalo de nuevo."*

> Flujo recomendado: selecciona docentes → **Generar CSVs** → descarga ambos CSV → sube cada CSV a su plataforma (Google Workspace / Moodle) → **Cerrar y actualizar estado** una vez confirmado que las altas han funcionado.

---

## 12. Informe semanal de bajas

Cada baja o reactivación realizada desde la pantalla **Baja Docente** queda registrada en el log de auditoría. El comando de consola `docentes:enviar-resumen-bajas` (programable con un planificador) envía por correo el **"Informe Semanal de Bajas de Docentes"** a la dirección configurada (`LOG_ALERT_TO`), con los eventos de los últimos 7 días (fecha/hora, nivel, mensaje y contexto), y rota el log tras el envío. Con la opción `--dry-run` el comando muestra el resumen por consola sin enviar ni rotar el log.

---

## 13. Resumen rápido de tareas habituales

| Tarea | Dónde |
|---|---|
| Alta de un docente | `Alta Docente` → DNI (autocompletado) → email personal → nombre/apellidos → revisar correo virtual → Guardar → asignar docencia |
| Baja de un docente | `Baja Docente` → buscar → papelera → confirmar |
| Reactivar un docente | `Baja Docente` → buscar → **Reactivar** (también ocurre automáticamente al dar de alta de nuevo al docente) |
| Nombrar coordinador | `/establecer-coordinador` → docente + ciclo (+ "También es tutor") |
| Nombrar tutor | `/establecer-tutor` → ciclo + docente |
| Asignar/quitar docencia | `Establecer docencia` → docente + ciclo + módulo |
| Cambiar mi contraseña o email | Menú de usuario → `Perfil` |
| Exportar altas masivas (Google/Moodle) | Admin → `Alta Plataforma` → seleccionar → Generar CSVs → descargar → actualizar estado |
| Consultar listado global | Admin → `Ver Docentes` / `Ver Centros` (con exportación CSV y detalle en *Más Info*) |

---

*Documentación generada a partir del código del proyecto (Laravel 12 + Blade). Para la puesta en marcha del entorno y credenciales de desarrollo, consulta `DESARROLLO.md`.*
