# Plan de Tareas Atómicas — Ecosistema Global TicketHTML

> **Especificación Base:** [`specs/sistema-tickets-global/ux-spec.md`](file:///c:/Coding/TicketHTML/specs/sistema-tickets-global/ux-spec.md)  
> **Sistema de Diseño:** [`.stitch/DESIGN.md`](file:///c:/Coding/TicketHTML/.stitch/DESIGN.md)  
> **Estado:** ✅ Completado y Verificado (100%)

---

## Checklist Secuencial de Ejecución (Fase 3 & Fase 4)

- [x] **1. Actualizar Tokens Semánticos, Prioridad Urgente, Skip-Link, Skeletons y Reduced Motion en `public/css/design-system.css`**
  - Incorporados tokens semánticos (`--color-surface-elevated`, `--color-surface-interactive`, `--color-surface-input`, `--color-focus-ring`, `--color-high-*`) en `:root` y `html[data-theme="dark"]`.
  - Añadidos estilos para `.skip-link`, `:focus-visible`, `.skeleton-stat-card`, `.ticket-card-trigger`, `.priority-pill-urgent` vs `.priority-pill-high`, `.compact-counter.counter-warning/.counter-danger`, `.empty-state-cta` y `@media (prefers-reduced-motion: reduce)`.

- [x] **2. Refactorizar Primitivas Globales, Accesibilidad, Skeletons y Estados en `public/js/core-panel.js`**
  - Soportada explícitamente la prioridad `urgent` (`🔴 Urgente`) y `high` (`🟠 Alta`) mediante `window.formatPriorityLabel()` en `buildVerticalTicketCard`, `buildKanbanCard` y `buildGridTicketCard`.
  - Corregido el anidamiento interactivo en `buildGridTicketCard` (contenedor `<article>` con `.ticket-card-trigger[role="button"][tabindex="0"]` + soporte de teclado `Enter`/`Space` mediante `window.handleCardTriggerKeydown` y barra hermana `.ticket-quick-actions`).
  - Añadido `window.renderSkeletonStats(count = 4)` e inicialización automática de skeletons en `#statsGrid` y `#ticketsList` al cargar el DOM (cero CLS).
  - Añadidos `window.hasActiveTicketFilters()` y `window.resetAllTicketFilters()` con botón CTA `"🔄 Limpiar filtros activos"` en `.empty-state-box`.
  - Añadido anunciador `#a11yStatusAnnouncer` (`aria-live="polite"`), navegación por flechas (`ArrowLeft`/`ArrowRight`) para cualquier `[role="tablist"]` y helper `window.A11yFormValidator`.

- [x] **3. Alinear Portal Público y Seguimiento (`public/index.html`, `public/js/index.js`, `public/track.html`)**
  - En `public/index.html` y `public/js/index.js`: añadido `.skip-link`, `id="main-content"`, `aria-label` en `#trackingSearchInput`, asociación `aria-describedby` + `aria-invalid` + `role="alert"` en todos los campos y `.field-error`, `role="dialog" aria-modal="true"` en `#loginModal` y `#trackingModal`, importado `/js/core-panel.js?v=4.0` y reemplazados colores hexadecimales inline de contadores por clases CSS semánticas (`.counter-warning`, `.counter-danger`).
  - En `public/track.html`: añadido `.skip-link`, `<main id="main-content">`, `aria-label` en `#trackingInput`, soporte para prioridad `urgent` (`🔴 Urgente`) y `high` (`🟠 Alta`) e importado `/js/core-panel.js?v=4.0`.

- [x] **4. Alinear Paneles Operativos de Tickets (`support.html`, `gerencia.html`, `administrador.html`, `compras.html`, `rrhh.html`)**
  - Añadido `.skip-link` y `<div class="container" id="main-content" tabindex="-1">`.
  - Eliminado el bloqueo en blanco `<body style="visibility: hidden; opacity: 0;">` para permitir el renderizado inmediato del App Shell con Skeletons.
  - Estandarizada la opción `<option value="urgent">🔴 Urgente</option>` y `<option value="high">🟠 Alta</option>` en `#priorityFilter` de todos los paneles.
  - Añadidos `aria-label` en todos los selectores de filtro y buscadores, `role="tablist"` / `role="tab"` / `aria-selected` en `.maint-tabs-container`, y eliminados estilos inline en `gerencia.html` y `compras.html`.

- [x] **5. Alinear Mantenimiento Preventivo, Reportes y Notificaciones (`mantenimiento.html`, `tareas-publico.html`, `reportes.html`, `reporte-publico.html`, `notificaciones.html`)**
  - En `mantenimiento.html` y `tareas-publico.html`: añadido `.skip-link`, `id="main-content"`, `role="tablist"` en pestañas y selector de vista de calendario, `aria-label` en filtros de tareas e importado `/js/core-panel.js?v=4.0` en `tareas-publico.html`.
  - En `reportes.html` y `reporte-publico.html`: añadido `.skip-link`, `id="main-content"`, asociados `for="periodSelect"` y `for="departmentSelect"`, añadidos `role="img"` y `aria-label` en todos los `<canvas>` de Chart.js e importado `/js/core-panel.js?v=4.0` en `reporte-publico.html`.
  - En `notificaciones.html`: añadido `.skip-link`, `<header>` y `<main id="main-content">`, corregida la redirección del rol `gerencia` hacia `/gerencia` (en vez de `/admin`), añadido botón `"🔄 Reintentar"` en caso de fallo de red y habilitada navegación por teclado (`tabindex="0"`, `role="button"`, `Enter`/`Space`) en cada `.notification-item`.

- [x] **6. Verificación Integral de Sintaxis y Contrato de Accesibilidad / Estados**
  - Ejecutado `node --check` sobre la totalidad de scripts en `public/js/*.js` y `server.js` (0 errores).
  - Verificada la presencia de `.skip-link` y `core-panel.js` en las 12 vistas HTML del proyecto.
