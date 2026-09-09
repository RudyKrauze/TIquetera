# Sistema de Notificaciones Push

## Descripción General

Este sistema implementa notificaciones push nativas del navegador usando la Web Push API, permitiendo alertas incluso cuando el usuario no está activamente en el sitio web.

## Arquitectura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Service Worker │ ◄── │   Backend API   │ ◄── │  Base de Datos  │
│     (sw.js)     │     │  (web-push)     │     │  (PostgreSQL)   │
└────────┬────────┘     └────────┬────────┘     └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│   Navegador     │     │  Push Service   │
│   (Chrome/FF)   │     │  (FCM/Mozilla)  │
└─────────────────┘     └─────────────────┘
```

## Componentes

### Frontend

| Archivo                             | Descripción                                                 |
| ----------------------------------- | ----------------------------------------------------------- |
| `public/sw.js`                      | Service Worker que recibe y muestra las notificaciones push |
| `public/js/push-notifications.js`   | Clase `PushNotificationSystem` para gestionar suscripciones |
| `public/css/push-notifications.css` | Estilos del modal de preferencias                           |
| `public/img/logo-icon.svg`          | Icono de la notificación                                    |
| `public/img/badge-icon.svg`         | Badge de la notificación                                    |

### Backend

| Endpoint                | Método   | Descripción                            |
| ----------------------- | -------- | -------------------------------------- |
| `/api/push/vapid-key`   | GET      | Obtiene la clave pública VAPID         |
| `/api/push/subscribe`   | POST     | Registra una suscripción push          |
| `/api/push/unsubscribe` | POST     | Elimina una suscripción                |
| `/api/push/preferences` | PUT      | Actualiza preferencias de notificación |
| `/api/push/test`        | POST     | Envía una notificación de prueba       |
| `/api/push/metrics`     | GET/POST | Métricas de entrega y engagement       |

### Base de Datos

```sql
-- Tabla de suscripciones
push_subscriptions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  endpoint TEXT UNIQUE,
  keys_p256dh TEXT,
  keys_auth TEXT,
  department VARCHAR(255),
  preferences JSONB,
  created_at TIMESTAMP,
  last_used TIMESTAMP
)

-- Tabla de métricas
push_metrics (
  id SERIAL PRIMARY KEY,
  notification_id INTEGER,
  subscription_id INTEGER,
  action VARCHAR(50),
  delivered BOOLEAN,
  clicked BOOLEAN,
  closed BOOLEAN,
  error TEXT,
  created_at TIMESTAMP
)
```

## Configuración

### Variables de Entorno (.env)

```env
# Claves VAPID generadas con: npx web-push generate-vapid-keys
VAPID_PUBLIC_KEY=tu_clave_publica
VAPID_PRIVATE_KEY=tu_clave_privada
VAPID_SUBJECT=mailto:admin@tudominio.com
```

### Generar Nuevas Claves VAPID

```bash
npx web-push generate-vapid-keys --json
```

## Flujo de Suscripción

1. **Usuario hace clic en "Activar notificaciones"**
2. **Navegador solicita permiso** → Usuario acepta/rechaza
3. **Si acepta:**
   - Service Worker se registra
   - PushManager crea suscripción con clave VAPID
   - Suscripción se envía al servidor
   - Servidor guarda en `push_subscriptions`
4. **Usuario recibe notificaciones push**

## Flujo de Envío

1. **Se crea un ticket**
2. **Backend ejecuta `sendPushToDepartment()`**
3. **Para cada suscripción del departamento:**
   - Verifica preferencias del usuario
   - Construye payload con título, mensaje, icono
   - Envía vía `webpush.sendNotification()`
   - Registra métrica de entrega
4. **Service Worker recibe el push**
5. **Muestra notificación nativa del sistema**

## Preferencias de Usuario

Los usuarios pueden configurar:

| Preferencia     | Descripción                                  |
| --------------- | -------------------------------------------- |
| `newTickets`    | Recibir alertas de nuevos tickets            |
| `ticketUpdates` | Recibir actualizaciones de tickets asignados |
| `urgentOnly`    | Solo notificaciones de prioridad alta        |
| `sound`         | Reproducir sonido con la notificación        |

## Compatibilidad

| Navegador  | Soporte | Notas                   |
| ---------- | ------- | ----------------------- |
| Chrome     | ✅      | Completo                |
| Firefox    | ✅      | Completo                |
| Edge       | ✅      | Completo                |
| Safari     | ⚠️      | Requiere macOS Ventura+ |
| iOS Safari | ❌      | No soportado            |

## Manejo de Errores

### Suscripción Expirada (410)

```javascript
if (error.statusCode === 410) {
  // Eliminar suscripción de la BD
  await pool.query("DELETE FROM push_subscriptions WHERE id = $1", [sub.id]);
}
```

### Permiso Denegado

- Se muestra mensaje informando al usuario
- Se sugiere activar en configuración del navegador

### Sin Conexión

- Las notificaciones se encolan en el Push Service
- Se entregan cuando el dispositivo vuelve a estar online

## Métricas Disponibles

| Métrica     | Descripción                             |
| ----------- | --------------------------------------- |
| `delivered` | Notificaciones entregadas exitosamente  |
| `clicked`   | Notificaciones en las que se hizo clic  |
| `closed`    | Notificaciones cerradas sin interacción |
| `error`     | Errores de entrega                      |

## Troubleshooting

### Las notificaciones no llegan

1. Verificar que el Service Worker esté registrado
2. Comprobar permisos en el navegador
3. Verificar claves VAPID en `.env`
4. Revisar logs del servidor

### Error "Push service error"

- Regenerar claves VAPID
- Verificar VAPID_SUBJECT sea un email válido

### La suscripción falla

- Verificar que el sitio use HTTPS (o localhost)
- Comprobar que el Service Worker esté en la raíz

## Seguridad

- Las claves VAPID **nunca** deben exponerse al cliente
- Solo se comparte la clave pública
- Las suscripciones están asociadas a usuarios autenticados
- Los endpoints push son validados antes de enviar

---

## API Reference

### PushNotificationSystem (Frontend)

```javascript
// Inicializar
await window.pushSystem.init();

// Suscribir
const result = await window.pushSystem.subscribe();

// Desuscribir
await window.pushSystem.unsubscribe();

// Actualizar preferencias
await window.pushSystem.updatePreferences({
  urgentOnly: true,
  sound: false,
});

// Enviar prueba
await window.pushSystem.sendTestNotification();

// Mostrar modal de preferencias
window.pushSystem.showPreferencesModal();
```

### sendPushToDepartment (Backend)

```javascript
await sendPushToDepartment(
  "Sistemas ", // department
  {
    id: 123,
    ticketId: 456,
    trackingId: "TKT-ABC123",
    title: "Nuevo ticket",
    message: "Juan creó un ticket",
  },
  "high" // priority: 'low', 'medium', 'high'
);
```
