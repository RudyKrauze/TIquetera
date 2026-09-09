/**
 * Sistema de Notificaciones Push Nativas
 * =======================================
 * Maneja el registro del Service Worker, suscripción push,
 * preferencias de usuario y métricas.
 */

class PushNotificationSystem {
    constructor() {
        this.swRegistration = null;
        this.isSubscribed = false;
        this.vapidPublicKey = null;
        this.permissionStatus = 'default';
        
        // Preferencias por defecto
        this.preferences = {
            enabled: true,
            sound: true,
            newTickets: true,
            ticketUpdates: true,
            urgentOnly: false
        };

        this.loadPreferences();
    }

    /**
     * Inicializa el sistema de push notifications
     */
    async init() {
        // Verificar soporte
        if (!this.isSupported()) {

            return false;
        }

        try {
            // Obtener clave VAPID del servidor
            await this.fetchVapidKey();
            
            // Registrar Service Worker
            await this.registerServiceWorker();
            
            // Verificar estado actual
            await this.checkSubscriptionStatus();
            
            // Configurar listener para mensajes del SW
            this.setupMessageListener();
            

            return true;
        } catch (error) {

            return false;
        }
    }

    /**
     * Verifica si el navegador soporta push notifications
     */
    isSupported() {
        return 'serviceWorker' in navigator && 
               'PushManager' in window && 
               'Notification' in window;
    }

    /**
     * Obtiene la clave VAPID pública del servidor
     */
    async fetchVapidKey() {
        try {
            const response = await fetch('/api/push/vapid-key');
            const data = await response.json();
            this.vapidPublicKey = data.publicKey;
        } catch (error) {

            throw error;
        }
    }

    /**
     * Registra el Service Worker
     */
    async registerServiceWorker() {
        try {
            this.swRegistration = await navigator.serviceWorker.register('/sw.js', {
                scope: '/'
            });
            

            
            // Esperar a que esté activo
            if (this.swRegistration.installing) {
                await new Promise(resolve => {
                    this.swRegistration.installing.addEventListener('statechange', (e) => {
                        if (e.target.state === 'activated') resolve();
                    });
                });
            }
            
            return this.swRegistration;
        } catch (error) {

            throw error;
        }
    }

    /**
     * Verifica el estado de la suscripción actual
     */
    async checkSubscriptionStatus() {
        try {
            const subscription = await this.swRegistration.pushManager.getSubscription();
            this.isSubscribed = subscription !== null;
            this.permissionStatus = Notification.permission;
            


            
            return { isSubscribed: this.isSubscribed, permission: this.permissionStatus };
        } catch (error) {

            return { isSubscribed: false, permission: 'default' };
        }
    }

    /**
     * Solicita permiso y suscribe al usuario
     */
    async subscribe() {
        try {
            // Solicitar permiso
            const permission = await Notification.requestPermission();
            this.permissionStatus = permission;
            
            if (permission !== 'granted') {

                return { success: false, reason: 'permission_denied' };
            }

            // Convertir VAPID key
            const applicationServerKey = this.urlBase64ToUint8Array(this.vapidPublicKey);

            // Suscribir
            const subscription = await this.swRegistration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: applicationServerKey
            });



            // Enviar suscripción al servidor
            await this.sendSubscriptionToServer(subscription);
            
            this.isSubscribed = true;
            this.savePreferences();
            
            return { success: true, subscription };
        } catch (error) {

            return { success: false, reason: error.message };
        }
    }

    /**
     * Desuscribe al usuario
     */
    async unsubscribe() {
        try {
            const subscription = await this.swRegistration.pushManager.getSubscription();
            
            if (subscription) {
                // Notificar al servidor
                await this.removeSubscriptionFromServer(subscription);
                
                // Desuscribir localmente
                await subscription.unsubscribe();
            }
            
            this.isSubscribed = false;

            
            return { success: true };
        } catch (error) {

            return { success: false, reason: error.message };
        }
    }

    /**
     * Envía la suscripción al servidor
     */
    async sendSubscriptionToServer(subscription) {
        const response = await fetch('/api/push/subscribe', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'include',
            body: JSON.stringify({
                subscription: subscription.toJSON(),
                preferences: this.preferences
            })
        });

        if (!response.ok) {
            throw new Error('Error guardando suscripción en servidor');
        }

        return response.json();
    }

    /**
     * Elimina la suscripción del servidor
     */
    async removeSubscriptionFromServer(subscription) {
        const response = await fetch('/api/push/unsubscribe', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'include',
            body: JSON.stringify({
                endpoint: subscription.endpoint
            })
        });

        return response.json();
    }

    /**
     * Actualiza preferencias de notificación
     */
    async updatePreferences(newPreferences) {
        this.preferences = { ...this.preferences, ...newPreferences };
        this.savePreferences();
        
        if (this.isSubscribed) {
            const subscription = await this.swRegistration.pushManager.getSubscription();
            
            if (subscription) {
                await fetch('/api/push/preferences', {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    credentials: 'include',
                    body: JSON.stringify({
                        endpoint: subscription.endpoint,
                        preferences: this.preferences
                    })
                });
            }
        }
        
        return this.preferences;
    }

    /**
     * Guarda preferencias en localStorage
     */
    savePreferences() {
        localStorage.setItem('pushPreferences', JSON.stringify(this.preferences));
    }

    /**
     * Carga preferencias desde localStorage
     */
    loadPreferences() {
        const saved = localStorage.getItem('pushPreferences');
        if (saved) {
            this.preferences = { ...this.preferences, ...JSON.parse(saved) };
        }
    }

    /**
     * Configura listener para mensajes del Service Worker
     */
    setupMessageListener() {
        navigator.serviceWorker.addEventListener('message', (event) => {

            
            if (event.data.type === 'NOTIFICATION_CLICK') {
                // Abrir ticket si hay función disponible
                if (event.data.ticketId) {
                    if (typeof showTicketDetails === 'function') {
                        showTicketDetails(parseInt(event.data.ticketId));
                    } else if (typeof openTicketModal === 'function') {
                        openTicketModal(parseInt(event.data.ticketId));
                    }
                }
            }
        });
    }

    /**
     * Convierte base64 URL a Uint8Array para VAPID
     */
    urlBase64ToUint8Array(base64String) {
        const padding = '='.repeat((4 - base64String.length % 4) % 4);
        const base64 = (base64String + padding)
            .replace(/-/g, '+')
            .replace(/_/g, '/');

        const rawData = window.atob(base64);
        const outputArray = new Uint8Array(rawData.length);

        for (let i = 0; i < rawData.length; ++i) {
            outputArray[i] = rawData.charCodeAt(i);
        }
        return outputArray;
    }

    /**
     * Envía una notificación de prueba
     */
    async sendTestNotification() {
        const response = await fetch('/api/push/test', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'include'
        });

        return response.json();
    }

    /**
     * Obtiene métricas de notificaciones
     */
    async getMetrics() {
        const response = await fetch('/api/push/metrics', {
            credentials: 'include'
        });

        return response.json();
    }

    /**
     * Muestra el modal de preferencias de notificación
     */
    showPreferencesModal() {
        // Crear modal si no existe
        let modal = document.getElementById('push-preferences-modal');
        
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'push-preferences-modal';
            modal.className = 'push-modal-overlay';
            modal.innerHTML = this.getPreferencesModalHTML();
            document.body.appendChild(modal);
            this.setupPreferencesListeners();
        }

        // Actualizar valores
        this.updatePreferencesUI();
        modal.classList.add('active');
    }

    /**
     * Genera el HTML del modal de preferencias
     */
    getPreferencesModalHTML() {
        return `
            <div class="push-modal">
                <div class="push-modal-header">
                    <h2>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="24" height="24">
                            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                        </svg>
                        Preferencias de Notificaciones
                    </h2>
                    <button class="push-modal-close" aria-label="Cerrar">&times;</button>
                </div>
                
                <div class="push-modal-body">
                    <div class="push-status" id="push-status">
                        <div class="push-status-icon"></div>
                        <div class="push-status-text">
                            <strong>Estado de notificaciones</strong>
                            <span id="push-status-detail">Verificando...</span>
                        </div>
                    </div>

                    <div class="push-action-buttons" id="push-action-buttons">
                        <button id="push-enable-btn" class="push-btn push-btn-primary">
                            🔔 Activar notificaciones
                        </button>
                        <button id="push-disable-btn" class="push-btn push-btn-secondary" style="display: none;">
                            🔕 Desactivar notificaciones
                        </button>
                        <button id="push-test-btn" class="push-btn push-btn-outline" style="display: none;">
                            🧪 Enviar prueba
                        </button>
                    </div>

                    <div class="push-preferences-section" id="push-preferences-section" style="display: none;">
                        <h3>Tipos de notificación</h3>
                        
                        <label class="push-toggle">
                            <input type="checkbox" id="pref-new-tickets" checked>
                            <span class="push-toggle-slider"></span>
                            <span class="push-toggle-label">
                                <strong>Nuevos tickets</strong>
                                <small>Recibir alertas cuando se cree un ticket en tu área</small>
                            </span>
                        </label>

                        <label class="push-toggle">
                            <input type="checkbox" id="pref-ticket-updates" checked>
                            <span class="push-toggle-slider"></span>
                            <span class="push-toggle-label">
                                <strong>Actualizaciones de tickets</strong>
                                <small>Cambios de estado y comentarios en tickets asignados</small>
                            </span>
                        </label>

                        <label class="push-toggle">
                            <input type="checkbox" id="pref-urgent-only">
                            <span class="push-toggle-slider"></span>
                            <span class="push-toggle-label">
                                <strong>Solo urgentes</strong>
                                <small>Recibir solo notificaciones de prioridad alta</small>
                            </span>
                        </label>

                        <label class="push-toggle">
                            <input type="checkbox" id="pref-sound" checked>
                            <span class="push-toggle-slider"></span>
                            <span class="push-toggle-label">
                                <strong>Sonido</strong>
                                <small>Reproducir sonido con las notificaciones</small>
                            </span>
                        </label>
                    </div>

                    <div class="push-info">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="16" x2="12" y2="12"/>
                            <line x1="12" y1="8" x2="12.01" y2="8"/>
                        </svg>
                        <span>Las notificaciones push funcionan incluso cuando el navegador está en segundo plano.</span>
                    </div>
                </div>

                <div class="push-modal-footer">
                    <button class="push-btn push-btn-secondary push-modal-close-btn">Cerrar</button>
                </div>
            </div>
        `;
    }

    /**
     * Configura listeners del modal de preferencias
     */
    setupPreferencesListeners() {
        const modal = document.getElementById('push-preferences-modal');
        
        // Cerrar modal
        modal.querySelectorAll('.push-modal-close, .push-modal-close-btn').forEach(btn => {
            btn.addEventListener('click', () => modal.classList.remove('active'));
        });
        
        modal.addEventListener('click', (e) => {
            if (e.target === modal) modal.classList.remove('active');
        });

        // Botón activar
        document.getElementById('push-enable-btn').addEventListener('click', async () => {
            const result = await this.subscribe();
            if (result.success) {
                this.updatePreferencesUI();
                this.showToast('✅ Notificaciones activadas', 'success');
            } else if (result.reason === 'permission_denied') {
                this.showToast('⚠️ Permiso denegado. Actívalo en la configuración del navegador.', 'warning');
            }
        });

        // Botón desactivar
        document.getElementById('push-disable-btn').addEventListener('click', async () => {
            const result = await this.unsubscribe();
            if (result.success) {
                this.updatePreferencesUI();
                this.showToast('🔕 Notificaciones desactivadas', 'info');
            }
        });

        // Botón prueba
        document.getElementById('push-test-btn').addEventListener('click', async () => {
            await this.sendTestNotification();
            this.showToast('📤 Notificación de prueba enviada', 'info');
        });

        // Preferencias checkboxes
        const prefCheckboxes = ['pref-new-tickets', 'pref-ticket-updates', 'pref-urgent-only', 'pref-sound'];
        prefCheckboxes.forEach(id => {
            document.getElementById(id)?.addEventListener('change', (e) => {
                const key = id.replace('pref-', '').replace(/-([a-z])/g, (g) => g[1].toUpperCase());
                this.updatePreferences({ [key]: e.target.checked });
            });
        });
    }

    /**
     * Actualiza la UI de preferencias según el estado actual
     */
    async updatePreferencesUI() {
        const status = await this.checkSubscriptionStatus();
        
        const statusEl = document.getElementById('push-status');
        const statusDetail = document.getElementById('push-status-detail');
        const enableBtn = document.getElementById('push-enable-btn');
        const disableBtn = document.getElementById('push-disable-btn');
        const testBtn = document.getElementById('push-test-btn');
        const prefsSection = document.getElementById('push-preferences-section');

        if (status.permission === 'denied') {
            statusEl.className = 'push-status push-status-denied';
            statusDetail.textContent = 'Bloqueadas en el navegador';
            enableBtn.style.display = 'none';
            disableBtn.style.display = 'none';
            testBtn.style.display = 'none';
            prefsSection.style.display = 'none';
        } else if (status.isSubscribed) {
            statusEl.className = 'push-status push-status-active';
            statusDetail.textContent = 'Activas y funcionando';
            enableBtn.style.display = 'none';
            disableBtn.style.display = 'inline-flex';
            testBtn.style.display = 'inline-flex';
            prefsSection.style.display = 'block';
        } else {
            statusEl.className = 'push-status push-status-inactive';
            statusDetail.textContent = 'No activadas';
            enableBtn.style.display = 'inline-flex';
            disableBtn.style.display = 'none';
            testBtn.style.display = 'none';
            prefsSection.style.display = 'none';
        }

        // Actualizar checkboxes
        document.getElementById('pref-new-tickets').checked = this.preferences.newTickets;
        document.getElementById('pref-ticket-updates').checked = this.preferences.ticketUpdates;
        document.getElementById('pref-urgent-only').checked = this.preferences.urgentOnly;
        document.getElementById('pref-sound').checked = this.preferences.sound;
    }

    /**
     * Muestra un toast temporal
     */
    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `push-toast push-toast-${type}`;
        toast.textContent = message;
        document.body.appendChild(toast);
        
        setTimeout(() => toast.classList.add('active'), 10);
        setTimeout(() => {
            toast.classList.remove('active');
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }
}

// Instancia global
window.pushSystem = new PushNotificationSystem();

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', () => {
    window.pushSystem.init();
});
