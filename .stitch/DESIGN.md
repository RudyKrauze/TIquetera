# Design System Specification — TicketHTML (Imagen Diagnóstica)

> **Versión:** 2.0.0 (SDD Contract)  
> **Arquitectura CSS:** Vanilla CSS3 Custom Properties (`public/css/design-system.css`) + Theming Reactivo (`html[data-theme="light" | "dark"]`)  
> **Estándar de Accesibilidad:** WCAG 2.2 Nivel AA (Contraste mínimo 4.5:1 para texto normal, 3.0:1 para texto grande y bordes/controles interactivos)

---

## 1. Filosofía y Principios de Diseño

1. **Claridad Clínica y Operativa**: Como plataforma de soporte crítico para **Imagen Diagnóstica** (Sedes Ciudad, Maipú y San Martín), la interfaz prioriza el escaneo rápido de estados, prioridades y SLAs sin ruido visual.
2. **Cero Estilos Huérfanos (Single Source of Truth)**: Ninguna vista HTML (`public/*.html` o `private/*.html`) ni script JS debe inyectar colores hexadecimales hardcodeados. Todo color, radio, sombra o espaciado debe referenciar tokens semánticos de `design-system.css`.
3. **Paridad Total Light / Dark Mode**: Todo token semántico posee su contraparte calibrada en `html[data-theme="dark"]` para evitar deslumbramiento en salas de diagnóstico e informes médicos con baja iluminación ambiental.
4. **Accesibilidad Nativa First**: Foco visible de alto contraste (`:focus-visible`), objetivos táctiles mínimos de `44x44px` en móvil y semántica no dependiente únicamente del color (uso obligatorio de ícono + etiqueta textual en estados y prioridades).

---

## 2. Jerarquía de Tokens de Color

### 2.1. Capa 1: Tokens Primitivos (Paleta Base Institucional)

| Token Primitivo | Valor Hex | Uso Base |
| :--- | :--- | :--- |
| `--teal-50` | `#f0fdfa` | Tinte ultra suave de marca |
| `--teal-100` | `#ccfbf1` | Superficie suave de énfasis / hover ligero |
| `--teal-200` | `#99f6e4` | Bordes de acento suave |
| `--teal-400` | `#2dd4bf` | Acento primario en modo oscuro |
| `--teal-500` | `#14b8a6` | Acento interactivo brillante |
| `--teal-600` | `#008b8b` | **Color Institucional Primario (Imagen Diagnóstica)** |
| `--teal-700` | `#006b6b` | Primario hover / gradiente profundo |
| `--teal-800` | `#004c4c` | Primario active / cabeceras de alto contraste |
| `--slate-50` | `#f8fafc` | Superficie secundaria clara |
| `--slate-100` | `#f1f5f9` | Fondo de aplicación claro / inputs sutiles |
| `--slate-200` | `#e2e8f0` | Divisor y borde sutil claro |
| `--slate-300` | `#cbd5e1` | Borde fuerte de controles / inputs claro |
| `--slate-400` | `#94a3b8` | Texto secundario/muted en modo oscuro |
| `--slate-500` | `#64748b` | Placeholder calibrado |
| `--slate-600` | `#475569` | Texto secundario/muted en modo claro (Ratio 7.2:1 sobre blanco) |
| `--slate-700` | `#334155` | Bordes e inputs en modo oscuro |
| `--slate-800` | `#1e293b` | Superficie de tarjetas/modales en modo oscuro |
| `--slate-850` | `#162032` | Superficie elevada / cabeceras de tabla en modo oscuro |
| `--slate-900` | `#0f172a` | Fondo principal en modo oscuro / Texto principal en modo claro |

---

### 2.2. Capa 2: Tokens Semánticos (Superficie, Texto, Borde e Interacción)

| Token Semántico | Modo Claro (`:root`) | Modo Oscuro (`html[data-theme="dark"]`) | Ratio WCAG AA | Rol Arquitectónico |
| :--- | :--- | :--- | :--- | :--- |
| **Superficies** | | | | |
| `--color-bg` | `#f5f7fb` | `#0f172a` | N/A | Fondo base del `<body>` en paneles internos |
| `--color-bg-hero` | `linear-gradient(135deg, #008b8b 0%, #006b6b 100%)` | `linear-gradient(135deg, #0f172a 0%, #1e293b 100%)` | N/A | Fondo envolvente en portales públicos (`index.html`, `track.html`) |
| `--color-surface` | `#ffffff` | `#1e293b` | N/A | Tarjetas, contenedores principales, modales y tablas |
| `--color-surface-elevated` | `#f8fafc` | `#162032` | N/A | Cabeceras de sección, barras de filtros, fondos de timeline |
| `--color-surface-interactive` | `#f1f5f9` | `#273549` | N/A | Estado `:hover` de filas, tarjetas e ítems de notificación |
| `--color-surface-input` | `#ffffff` | `#0f172a` | N/A | Fondo de `<input>`, `<select>` y `<textarea>` |
| **Tipografía / Texto** | | | | |
| `--color-text-main` | `#0f172a` | `#f8fafc` | > 15:1 (AAA) | Títulos, cuerpo principal, valores de datos |
| `--color-text-muted` | `#475569` | `#94a3b8` | > 5.7:1 (AA) | Subtítulos, metadatos, etiquetas secundarias, fechas |
| `--color-text-placeholder` | `#64748b` | `#64748b` | > 4.5:1 (AA) | Placeholders de formularios y buscadores |
| `--color-text-inverse` | `#ffffff` | `#0f172a` | > 12:1 (AAA) | Texto sobre botones primarios o cabeceras sólidas |
| **Bordes y Divisores** | | | | |
| `--color-border-subtle` | `#e2e8f0` | `#334155` | N/A | Divisores internos de tarjetas, filas de tabla y listas |
| `--color-border-strong` | `#cbd5e1` | `#475569` | > 3.1:1 (AA) | Bordes de inputs, selects, botones outline y tarjetas activas |
| `--color-focus-ring` | `#008b8b` | `#2dd4bf` | > 4.5:1 (AA) | Anillo `:focus-visible` (`0 0 0 3px rgba(0, 139, 139, 0.35)`) |
| **Marca e Interacción** | | | | |
| `--color-primary` | `#008b8b` | `#14b8a6` | > 4.5:1 (AA) | Acción principal, enlaces activos, indicadores de progreso |
| `--color-primary-dark` | `#006b6b` | `#0d9488` | > 6.1:1 (AA) | Estado `:hover` / `:active` de acciones primarias |
| `--color-primary-soft` | `#e0f4f4` | `rgba(20, 184, 166, 0.16)` | N/A | Fondo de notificaciones no leídas, chips de tracking y selección |

---

### 2.3. Capa 3: Tokens de Estado y Prioridad (Semántica Operativa)

Todos los badges de estado y prioridad combinan **fondo suave + borde semántico + texto de alto contraste + ícono/indicador**:

| Categoría | Token Fondo (`-soft`) | Token Texto (`-text`) | Token Borde (`-border`) | Uso en el Sistema |
| :--- | :--- | :--- | :--- | :--- |
| **Success / Cerrado / Completado** | Claro: `#dcfce7`<br>Oscuro: `rgba(34, 197, 94, 0.16)` | Claro: `#14532d`<br>Oscuro: `#4ade80` | Claro: `#86efac`<br>Oscuro: `rgba(34, 197, 94, 0.4)` | Tickets `closed`, tareas `completed`, prioridad `low` (🟢 Baja), validaciones exitosas |
| **Info / En Progreso** | Claro: `#e0f2fe`<br>Oscuro: `rgba(56, 189, 248, 0.16)` | Claro: `#0c4a6e`<br>Oscuro: `#38bdf8` | Claro: `#7dd3fc`<br>Oscuro: `rgba(56, 189, 248, 0.4)` | Tickets `in-progress` (🔵 En Progreso), chips de técnicos asignados |
| **Warning / Pendiente / Media** | Claro: `#fef3c7`<br>Oscuro: `rgba(245, 158, 11, 0.16)` | Claro: `#78350f`<br>Oscuro: `#fbbf24` | Claro: `#fcd34d`<br>Oscuro: `rgba(245, 158, 11, 0.4)` | Tickets `open` (🟡 Pendiente), prioridad `medium` (🟡 Media), advertencias de límite (75%-90%) |
| **High / Prioridad Alta** | Claro: `#ffedd5`<br>Oscuro: `rgba(249, 115, 22, 0.16)` | Claro: `#9a3412`<br>Oscuro: `#fb923c` | Claro: `#fdba74`<br>Oscuro: `rgba(249, 115, 22, 0.4)` | Prioridad `high` (🟠 Alta) diferenciada cromáticamente de Urgente |
| **Danger / Urgente / Error** | Claro: `#fee2e2`<br>Oscuro: `rgba(239, 68, 68, 0.18)` | Claro: `#991b1b`<br>Oscuro: `#f87171` | Claro: `#fca5a5`<br>Oscuro: `rgba(239, 68, 68, 0.45)` | Prioridad `urgent` (🔴 Urgente), errores de formulario, acciones destructivas |
| **Purple / Rutinas Recurrentes** | Claro: `#f3e8ff`<br>Oscuro: `rgba(168, 85, 247, 0.16)` | Claro: `#581c87`<br>Oscuro: `#c084fc` | Claro: `#d8b4fe`<br>Oscuro: `rgba(168, 85, 247, 0.4)` | KPIs y badges de tareas preventivas recurrentes |

---

## 3. Escala Tipográfica

- **Familia Principal (`--font-sans`)**: `'Montserrat', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif`
- **Familia Monoespaciada (`--font-mono`)**: `'JetBrains Mono', 'Fira Code', 'Consolas', monospace` (exclusivo para `tracking_id` como `TKT-00124` y tokens de compartición).
- **Regla de Piso Tipográfico**: Queda prohibido cualquier tamaño menor a `0.75rem` (`12px`).

| Token Tipográfico | Tamaño (`rem` / `px`) | Peso (`font-weight`) | Altura de Línea (`line-height`) | Uso |
| :--- | :--- | :--- | :--- | :--- |
| `--text-xs` | `0.75rem` (`12px`) | `600` | `1.35` | Badges, píldoras de estado, contadores de caracteres, etiquetas de calendario |
| `--text-sm` | `0.875rem` (`14px`) | `400` / `500` / `600` | `1.45` | Metadatos de tarjetas, celdas de tablas secundarias, botones compactos, filtros |
| `--text-base` | `1rem` (`16px`) | `400` / `500` | `1.5` | Cuerpo de texto, inputs de formulario (previene auto-zoom en iOS Safari < 16px) |
| `--text-lg` | `1.125rem` (`18px`) | `600` / `700` | `1.35` | Títulos de tarjetas de ticket (`.ticket-title`), encabezados de modales |
| `--text-xl` | `1.25rem` (`20px`) | `700` | `1.3` | Títulos de sección (`.section-header h2`), títulos de barra de navegación |
| `--text-2xl` | `1.5rem` (`24px`) | `700` / `800` | `1.25` | Títulos principales de página y cabeceras ejecutivas |
| `--text-kpi` | `clamp(1.5rem, 2.2vw, 2rem)` | `800` | `1.1` | Números de tarjetas KPI (`.stat-number`) |

---

## 4. Sistema de Espaciado, Radios, Sombras y Layout

### 4.1. Escala Espacial (Base 4px)
- `--space-1`: `4px` (`0.25rem`) — Separación interna mínima entre ícono y texto en badges.
- `--space-2`: `8px` (`0.5rem`) — Gap entre píldoras de metadatos y botones de acción rápida.
- `--space-3`: `12px` (`0.75rem`) — Padding vertical de inputs, gap en grillas compactas.
- `--space-4`: `16px` (`1rem`) — Padding estándar de tarjetas, contenedores móviles y barras de herramientas.
- `--space-5`: `20px` (`1.25rem`) — Padding de contenedores desktop y separación entre bloques.
- `--space-6`: `24px` (`1.5rem`) — Padding interno de modales y cabeceras de sección.
- `--space-8`: `32px` (`2rem`) — Separación estructural entre macro-secciones.

### 4.2. Radios de Borde (`border-radius`)
- `--radius-xs`: `4px` — Barras de progreso de caracteres, checkboxes.
- `--radius-sm`: `6px` — Botones de acción rápida en tarjetas, chips de código.
- `--radius-md`: `8px` — Inputs, selects, botones estándar de formulario, toasts.
- `--radius-lg`: `12px` — Tarjetas de tickets (`.ticket-grid-card`), tarjetas KPI (`.stat-card`), tablas.
- `--radius-xl`: `16px` — Modales de diálogo (`.modal-content`, `.ticket-modal-content`), cabeceras flotantes.
- `--radius-pill`: `9999px` — Píldoras de estado/prioridad, botones de navegación de pestañas y conmutador de tema.

### 4.3. Elevación y Sombras
- `--shadow-sm`: `0 1px 3px rgba(15, 23, 42, 0.08), 0 1px 2px rgba(15, 23, 42, 0.04)` (Tarjetas en reposo).
- `--shadow-md`: `0 4px 12px rgba(15, 23, 42, 0.12)` (Tarjetas en `:hover`, barra de navegación, dropdowns).
- `--shadow-lg`: `0 20px 45px rgba(15, 23, 42, 0.22)` (Modales, diálogos de confirmación y notificaciones flotantes).
- `--shadow-focus`: `0 0 0 3px rgba(0, 139, 139, 0.35)` (Modo claro) / `0 0 0 3px rgba(45, 212, 191, 0.45)` (Modo oscuro).

### 4.4. Reglas de Breakpoints y Responsividad
- **Desktop Large (`> 1200px`)**: Contenedor máximo `1400px` en paneles operativos (grilla de tickets `3 columnas x 5 filas = 15 por página`), `1200px` en reportes.
- **Tablet / Laptop (`769px – 1024px`)**: Grilla de tickets de `2 columnas`, barra de filtros en `flex-wrap`.
- **Mobile (`<= 768px`)**:
  - Grilla de tickets y formularios colapsan a `1 columna`.
  - Tablas de datos (`.responsive-table`) se transforman automáticamente en tarjetas clave-valor mediante `td::before { content: attr(data-label); }`.
  - Altura mínima de controles táctiles (`button`, `select`, `input`, `.ticket-tab`): `44px`.

### 4.5. Movimiento y Reducción de Movimiento (WCAG 2.3.3)
- Transición estándar: `--transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1)` y `--transition-normal: 220ms cubic-bezier(0.16, 1, 0.3, 1)`.
- Soporte obligatorio en `design-system.css` para `@media (prefers-reduced-motion: reduce)`, desactivando animaciones de shimmer en skeletons, pulsos y desplazamientos `translateY`.
