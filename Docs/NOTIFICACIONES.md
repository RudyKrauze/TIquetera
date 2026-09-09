# Sistema de Notificaciones en Tiempo Real

## Descripción General

Sistema de notificaciones push en tiempo real implementado para las 5 áreas de la organización:

1. **Recursos Humanos** (`rrhh`)
2. **Sistemas ** (`support`)
3. **Mantenimiento** (`mantenimiento`)
4. **Compras e Insumos** (`compras`)
5. **Administrador** (`administrador`)

---

## Arquitectura

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Cliente Web   │────▶│   Socket.io      │────▶│   PostgreSQL    │
│   (Browser)     │◀────│   WebSocket      │◀────│   Database      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                        │
        │    HTTP REST API       │
        └────────────────────────┘
```

### Componentes

| Componente        | Archivo                        | Descripción                                         |
| ----------------- | ------------------------------ | --------------------------------------------------- |
| Backend WebSocket | `server.js`                    | Manejo de conexiones Socket.io y emisión de eventos |
| API REST          | `server.js`                    | Endpoints para CRUD de notificaciones               |
| Cliente JS        | `public/js/notifications.js`   | Clase NotificationSystem para el frontend           |
| Estilos           | `public/css/notifications.css` | Estilos del dropdown, toasts y página de historial  |
| Historial         | `public/notificaciones.html`   | Página de historial completo de notificaciones      |

---

## Base de Datos

### Tabla `notifications`

```sql
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    ticket_id INTEGER REFERENCES tickets(id) ON DELETE CASCADE,
    department VARCHAR(255) NOT NULL,
    title VARCHAR(500) NOT NULL,
    message TEXT NOT NULL,
    ticket_tracking_id VARCHAR(50),
    created_by_name VARCHAR(255),
    is_read BOOLEAN DEFAULT FALSE,
    read_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimización
CREATE INDEX idx_notifications_department ON notifications(department);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
```

---

## API REST

### Endpoints

| Método | Endpoint                      | Descripción                        | Autenticación |
| ------ | ----------------------------- | ---------------------------------- | ------------- |
| GET    | `/api/notifications/unread`   | Últimas 5 notificaciones no leídas | Requerida     |
| GET    | `/api/notifications/count`    | Conteo de notificaciones no leídas | Requerida     |
| GET    | `/api/notifications/history`  | Historial paginado                 | Requerida     |
| PUT    | `/api/notifications/:id/read` | Marcar como leída                  | Requerida     |
| PUT    | `/api/notifications/read-all` | Marcar todas como leídas           | Requerida     |

### Ejemplos de Respuesta

#### GET /api/notifications/unread

```json
[
  {
    "id": 1,
    "ticket_id": 42,
    "department": "Sistemas ",
    "title": "Nuevo ticket: Problema con impresora",
    "message": "Juan Pérez ha creado un nuevo ticket",
    "ticket_tracking_id": "TKT-ABC123",
    "created_by_name": "Juan Pérez",
    "is_read": false,
    "created_at": "2024-12-04T11:30:00.000Z"
  }
]
```

#### GET /api/notifications/history?page=1&limit=20

```json
{
  "notifications": [...],
  "total": 45,
  "page": 1,
  "totalPages": 3
}
```

---

## WebSocket Events

### Eventos del Cliente → Servidor

| Evento            | Payload             | Descripción                     |
| ----------------- | ------------------- | ------------------------------- |
| `join_department` | `{ token: string }` | Unirse al room del departamento |
| `request_count`   | -                   | Solicitar conteo actualizado    |

### Eventos del Servidor → Cliente

| Evento               | Payload                   | Descripción                       |
| -------------------- | ------------------------- | --------------------------------- |
| `joined`             | `{ department, message }` | Confirmación de unión al room     |
| `new_notification`   | Objeto notificación       | Nueva notificación en tiempo real |
| `notification_count` | `{ count: number }`       | Conteo actualizado                |
| `error`              | `{ message: string }`     | Error de conexión                 |

### Ejemplo de Conexión

```javascript
const socket = io("http://localhost:3005");

socket.on("connect", () => {
  socket.emit("join_department", { token: getCookie("token") });
});

socket.on("new_notification", (notification) => {
  console.log("Nueva notificación:", notification);
  // Actualizar UI, mostrar toast, reproducir sonido
});
```

---

## Flujo de Notificaciones

### Creación de Ticket

```
1. Usuario crea ticket (POST /api/tickets)
2. Servidor inserta ticket en BD
3. Servidor crea notificación para el departamento destino
4. Servidor emite evento WebSocket a room del departamento
5. Si el ticket no es para Administrador, también notifica a Administrador
6. Clientes conectados reciben notificación en tiempo real
7. Se muestra toast push y se actualiza badge
```

### Mapeo de Roles a Departamentos

```javascript
const ROLE_TO_NOTIFICATION_DEPARTMENT = {
  rrhh: "Recursos Humanos",
  support: "Sistemas ",
  mantenimiento: "Mantenimiento",
  compras: "Compras e Insumos",
  administrador: "Administrador",
};
```

---

## Frontend: Clase NotificationSystem

### Métodos Públicos

| Método                       | Descripción                       |
| ---------------------------- | --------------------------------- |
| `init()`                     | Inicializa el sistema completo    |
| `loadInitialNotifications()` | Carga notificaciones al iniciar   |
| `markAsRead(id)`             | Marca una notificación como leída |
| `markAllAsRead()`            | Marca todas como leídas           |
| `showToast(notification)`    | Muestra toast push                |
| `playNotificationSound()`    | Reproduce sonido de alerta        |
| `setSoundEnabled(boolean)`   | Habilita/deshabilita sonidos      |
| `disconnect()`               | Desconecta WebSocket              |

### Uso

```javascript
// El sistema se inicializa automáticamente al cargar la página
// si existe el elemento #notification-bell

// Acceso manual:
window.notificationSystem.setSoundEnabled(false);
window.notificationSystem.markAllAsRead();
```

---

## Interfaz de Usuario

### Campana de Notificaciones

- Ubicada en la barra de navegación superior
- Badge rojo con contador de no leídas
- Animación de pulso cuando hay notificaciones

### Dropdown

- Muestra últimas 5 notificaciones no leídas
- Botón "Marcar todas como leídas"
- Enlace "Ver más" a página de historial
- Se cierra al hacer clic fuera o presionar Escape

### Toast Push

- Aparece en esquina superior derecha
- Auto-cierre después de 5 segundos
- Click para ir al ticket
- Máximo 3 toasts simultáneos

### Página de Historial

- URL: `/notificaciones`
- Paginación de 20 notificaciones por página
- Filtro por estado (todas/leídas/no leídas)
- Estadísticas de total y no leídas

---

## Accesibilidad (WCAG)

- **Roles ARIA**: `role="alert"`, `role="menu"`, `role="listitem"`
- **Labels**: `aria-label`, `aria-expanded`, `aria-haspopup`
- **Navegación por teclado**: Tab, Enter, Escape
- **Focus visible**: Outline en elementos focusables
- **Reducción de movimiento**: Respeta `prefers-reduced-motion`
- **Alto contraste**: Estilos para `prefers-contrast: high`

---

## Rendimiento

### Optimizaciones Implementadas

1. **Índices de BD**: Para departamento, is_read y created_at
2. **Pool de conexiones**: Máximo 20 conexiones PostgreSQL
3. **Límite de notificaciones**: Máximo 5 en dropdown, 20 por página
4. **Debounce**: En actualizaciones de UI
5. **Lazy loading**: Socket.io se carga desde CDN solo cuando es necesario

### Métricas Objetivo

| Métrica             | Objetivo     | Implementación                               |
| ------------------- | ------------ | -------------------------------------------- |
| Tiempo de respuesta | < 2 segundos | WebSocket para push instantáneo              |
| Concurrencia        | Alta         | Rooms de Socket.io por departamento          |
| Memoria             | Optimizada   | Límite de toasts y notificaciones en memoria |

---

## Seguridad

1. **Autenticación JWT**: Requerida para todos los endpoints
2. **Validación de departamento**: Usuarios solo ven notificaciones de su área
3. **Sanitización**: Escape de HTML en títulos y mensajes
4. **CORS**: Configurado para orígenes permitidos
5. **Cookies HttpOnly**: Token no accesible desde JavaScript

---

## Instalación

### Dependencias

```bash
npm install socket.io
```

### Variables de Entorno

No se requieren variables adicionales. El sistema usa las existentes:

- `JWT_SECRET`
- `DB_*` (conexión a PostgreSQL)

### Inicialización

La tabla de notificaciones se crea automáticamente al iniciar el servidor si no existe.

---

## Archivos Modificados/Creados

### Nuevos

- `public/js/notifications.js` - Cliente de notificaciones
- `public/css/notifications.css` - Estilos
- `public/notificaciones.html` - Página de historial
- `public/mantenimiento.html` - Panel de mantenimiento
- `public/compras.html` - Panel de compras
- `NOTIFICACIONES.md` - Esta documentación

### Modificados

- `package.json` - Agregado socket.io
- `server.js` - WebSocket, tabla y endpoints de notificaciones
- `public/support.html` - Campana de notificaciones
- `public/rrhh.html` - Campana de notificaciones
- `public/administrador.html` - Campana de notificaciones

---

## Solución de Problemas

### Las notificaciones no llegan en tiempo real

1. Verificar que el servidor esté corriendo con WebSocket habilitado
2. Verificar conexión en consola del navegador
3. Revisar logs del servidor para errores de Socket.io

### El badge no se actualiza

1. Verificar que el usuario esté autenticado
2. Revisar que el rol del usuario esté mapeado correctamente
3. Verificar respuesta del endpoint `/api/notifications/count`

### Sonido no reproduce

1. El navegador puede bloquear audio sin interacción del usuario
2. Verificar que `soundEnabled` esté en `true`
3. Algunos navegadores requieren AudioContext después de un click

---

## Futuras Mejoras

- [ ] Notificaciones push del navegador (Web Push API)
- [ ] Configuración de preferencias de usuario
- [ ] Notificaciones por email
- [ ] Agrupación de notificaciones similares
- [ ] Historial de notificaciones eliminadas
- [ ] Métricas y analytics de notificaciones
