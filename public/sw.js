/**
 * Service Worker para Notificaciones Push
 * ========================================
 * Maneja notificaciones push en segundo plano y offline
 */

const CACHE_NAME = 'tiquetera-v1';
const NOTIFICATION_ICON = '/img/logo-icon.svg';
const NOTIFICATION_BADGE = '/img/badge-icon.svg';

// Assets para precachear
const ASSETS_TO_CACHE = [
    '/',
    '/index.html',
    '/css/design-system.css',
    '/js/push-notifications.js',
    '/logo.png',
    '/js/pwa-install.js',
    '/manifest.json'
];

// Instalación del Service Worker
self.addEventListener('install', (event) => {

    
    // Precachear assets críticos
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {

                return cache.addAll(ASSETS_TO_CACHE);
            })
    );
    
    self.skipWaiting();
});

// Interceptación de peticiones (Cache y Offline)
self.addEventListener('fetch', (event) => {
    // Omitir peticiones que no sean GET (como POST a API)
    if (event.request.method !== 'GET') return;

    // Estrategia híbrida:
    // 1. Archivos estáticos (JS, CSS, Imágenes) -> Cache First
    // 2. Navegación y API -> Network First
    
    const url = new URL(event.request.url);
    const isStatic = url.pathname.match(/\.(js|css|png|jpg|svg|json|ico)$/);

    if (isStatic) {
        event.respondWith(
            caches.match(event.request).then((cachedResponse) => {
                if (cachedResponse) {
                    return cachedResponse;
                }
                return fetch(event.request).then((networkResponse) => {
                    // Validar respuesta válida
                    if(!networkResponse || networkResponse.status !== 200 || networkResponse.type !== 'basic') {
                        return networkResponse;
                    }

                    // Guardar en cache para la próxima
                    const responseToCache = networkResponse.clone();
                    caches.open(CACHE_NAME).then((cache) => {
                        cache.put(event.request, responseToCache);
                    });

                    return networkResponse;
                });
            })
        );
    } else {
        // Network First con fallback a cache (para modo offline)
        event.respondWith(
            fetch(event.request)
                .catch(() => {

                    return caches.match(event.request)
                        .then(response => {
                            // Si es una navegación HTML y no está en caché, podemos devolver una página offline genérica
                            // if (!response && event.request.mode === 'navigate') {
                            //     return caches.match('/offline.html'); 
                            // }
                            return response;
                        });
                })
        );
    }
});

// Activación del Service Worker
self.addEventListener('activate', (event) => {

    event.waitUntil(clients.claim());
});

// Recepción de notificaciones push
self.addEventListener('push', (event) => {


    let data = {
        title: 'Nueva notificación',
        body: 'Tienes una nueva notificación',
        icon: NOTIFICATION_ICON,
        badge: NOTIFICATION_BADGE,
        tag: 'default',
        data: {}
    };

    try {
        if (event.data) {
            const payload = event.data.json();
            data = {
                title: payload.title || data.title,
                body: payload.body || payload.message || data.body,
                icon: payload.icon || NOTIFICATION_ICON,
                badge: payload.badge || NOTIFICATION_BADGE,
                tag: payload.tag || `notification-${Date.now()}`,
                data: {
                    url: payload.url || '/',
                    ticketId: payload.ticketId,
                    trackingId: payload.trackingId,
                    department: payload.department,
                    notificationId: payload.notificationId,
                    timestamp: payload.timestamp || Date.now()
                },
                actions: payload.actions || [
                    { action: 'view', title: '📋 Ver ticket' },
                    { action: 'dismiss', title: '❌ Cerrar' }
                ],
                requireInteraction: payload.priority === 'high',
                silent: payload.silent || false,
                vibrate: payload.vibrate || [200, 100, 200]
            };
        }
    } catch (e) {

        if (event.data) {
            data.body = event.data.text();
        }
    }

    const options = {
        body: data.body,
        icon: data.icon,
        badge: data.badge,
        tag: data.tag,
        data: data.data,
        actions: data.actions,
        requireInteraction: data.requireInteraction,
        silent: data.silent,
        vibrate: data.vibrate,
        renotify: true
    };

    event.waitUntil(
        self.registration.showNotification(data.title, options)
    );
});

// Click en notificación
self.addEventListener('notificationclick', (event) => {

    
    event.notification.close();

    if (event.action === 'dismiss') {
        return;
    }

    const urlToOpen = event.notification.data?.url || '/';
    const ticketId = event.notification.data?.ticketId;

    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then((clientList) => {
                // Buscar ventana existente
                for (const client of clientList) {
                    if (client.url.includes(self.registration.scope)) {
                        // Enviar mensaje al cliente para abrir el ticket
                        if (ticketId) {
                            client.postMessage({
                                type: 'NOTIFICATION_CLICK',
                                ticketId: ticketId,
                                url: urlToOpen
                            });
                        }
                        return client.focus();
                    }
                }
                // Si no hay ventana abierta, abrir una nueva
                return clients.openWindow(urlToOpen);
            })
    );
});

// Cierre de notificación
self.addEventListener('notificationclose', (event) => {

    
    // Reportar cierre al servidor para métricas
    const notificationId = event.notification.data?.notificationId;
    if (notificationId) {
        fetch('/api/push/metrics', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                notificationId,
                action: 'closed',
                timestamp: Date.now()
            })
        }).catch(err => {});
    }
});

// Mensaje desde el cliente principal
self.addEventListener('message', (event) => {

    
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});
