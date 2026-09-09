# Auditoría de Código - TicketHTML

## 1. Resumen Ejecutivo

El proyecto es un sistema de tickets basado en Node.js (Express) y PostgreSQL con un frontend servido estáticamente. La arquitectura es monolítica.
Se han encontrado buenas prácticas de seguridad en el backend, pero existen inconsistencias graves en la estructura de archivos del frontend (duplicación masiva) y un problema de configuración en la inicialización de la base de datos.

## 2. Análisis del Backend (`server.js` y relacionados)

### Aspectos Positivos

- **Seguridad**: Se implementan correctamente headers de seguridad (`helmet`), limitación de tasas (`express-rate-limit`), limpieza de XSS (`xss-clean`) y CORS.
- **Base de Datos**: Uso de sentencias preparadas (parameterized queries) con `pg` para evitar inyección SQL.
- **Configuración**: Uso correcto de variables de entorno (`dotenv`).

### Hallazgos / Problemas

- **Archivo faltante en ruta esperada**: El archivo `db_init.js` busca cargar la estructura de la base de datos desde `db_schema.sql` en la raíz del proyecto (`__dirname`), pero el archivo real se encuentra en la carpeta `Docs/`.
  - **Impacto**: `Starting server...` mostrará una advertencia y no creará las tablas en una instalación nueva.
- **Lógica de Migración Confusa**: `db_init.js` contiene lógica para desactivar roles ('gerencia', 'facturacion', 'contact'), pero los archivos de estas vistas siguen activos en `public/`.

## 3. Análisis del Frontend (`public/`)

### Estructura y Duplicación

- **CRÍTICO**: Existe una duplicación de código masiva. Los archivos JS de los paneles (`gerencia.js`, `compras.js`, `mantenimiento.js`, etc.) comparten más del **90% de su lógica**.
  - Funciones idénticas: `verifyAuth`, `loadTickets`, `renderTickets`, `handleKanbanDragStart` (y toda la lógica Kanban), `showTicketDetails`.
  - **Impacto**: Mantener esto es insostenible. Cualquier cambio en la lógica del Kanban o de los tickets debe replicarse manualmente en 5+ archivos.

### Seguridad Frontend

- La autenticación se maneja vía JWT y se verifica al cargar la página (`verifyAuth`), lo cual es correcto.
- Se utilizan funciones de escape (`escapeHtml`) para prevenir XSS al renderizar contenido dinámico.

## 4. Recomendaciones Prioritarias

### Inmediatas (Easy Wins)

1.  **Corregir ruta de Schema**: Modificar `db_init.js` para buscar el esquema en `path.join(__dirname, 'Docs', 'db_schema.sql')` o mover el archivo a la raíz.
2.  **Limpieza**: Si los roles 'gerencia', 'facturacion' y 'contact' están realmente deprecados, eliminar sus archivos `.html` y `.js` de `public/` para evitar confusión.

### Estructurales (Refactorización)

3.  **Modularización del Frontend**:
    - Crear un archivo `public/js/app-core.js` (o similar) que contenga la lógica compartida: autenticación, renderizado de tickets, Kanban y manejo de modales.
    - Los archivos específicos (`compras.js`, `support.js`) solo deberían contener la configuración específica (ej. nombre del departamento, columnas permitidas) e importar/llamar a las funciones del núcleo.

## 5. Conclusión

El backend es sólido en seguridad y estructura básica. El frontend es funcional pero frágil debido a la duplicación de código. Se recomienda priorizar la refactorización del frontend antes de añadir nuevas funcionalidades complejas.
