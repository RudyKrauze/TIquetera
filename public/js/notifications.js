/**
 * Sistema de Notificaciones en Tiempo Real
 * =========================================
 * Maneja la conexión WebSocket, dropdown de notificaciones,
 * toasts push y sonidos de alerta.
 */

class NotificationSystem {
    constructor() {
        this.socket = null;
        this.isConnected = false;
        this.notificationCount = 0;
        this.notifications = [];
        this.audioContext = null;
        this.dropdownOpen = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 10;
        this.reconnectDelay = 1000;
        
        // Elementos DOM
        this.bellButton = null;
        this.badgeElement = null;
        this.dropdownElement = null;
        this.listElement = null;
        this.toastContainer = null;
        
        // Configuración
        this.config = {
            soundEnabled: true,
            toastDuration: 5000,
            maxToasts: 3
        };

        this.pollingInterval = null;

        // Bind de métodos
        this.handleNewNotification = this.handleNewNotification.bind(this);
        this.toggleDropdown = this.toggleDropdown.bind(this);
        this.closeDropdown = this.closeDropdown.bind(this);
        this.handleReconnect = this.handleReconnect.bind(this);
        this.handleOnline = this.handleOnline.bind(this);
        this.startPollingFallback = this.startPollingFallback.bind(this);
    }

    /**
     * Inicializa el sistema de notificaciones
     */
    async init() {
        this.createToastContainer();
        this.setupBellButton();
        this.setupDropdown();
        this.setupClickOutside();
        this.setupNetworkListeners();
        await this.connectWebSocket();
        await this.loadInitialNotifications();
        
        // Activar sondeo de respaldo periódico (cada 30s) para asegurar recepción
        // en arquitecturas serverless como Vercel donde los WebSockets no son persistentes
        this.startPollingFallback();
    }

    /**
     * Configura listeners de red para reconexión automática
     */
    setupNetworkListeners() {
        window.addEventListener('online', this.handleOnline);
        window.addEventListener('focus', () => {
            // Recargar notificaciones cuando la ventana recupera el foco
            if (this.isConnected) {
                this.loadInitialNotifications();
            }
        });
    }

    /**
     * Maneja reconexión cuando vuelve la red
     */
    handleOnline() {

        if (!this.isConnected && this.socket) {
            this.socket.connect();
        }
    }

    /**
     * Crea el contenedor de toasts
     */
    createToastContainer() {
        if (!document.querySelector('.notification-toast-container')) {
            this.toastContainer = document.createElement('div');
            this.toastContainer.className = 'notification-toast-container';
            this.toastContainer.setAttribute('role', 'alert');
            this.toastContainer.setAttribute('aria-live', 'polite');
            document.body.appendChild(this.toastContainer);
        } else {
            this.toastContainer = document.querySelector('.notification-toast-container');
        }
    }

    /**
     * Configura el botón de campana
     */
    setupBellButton() {
        this.bellButton = document.getElementById('notification-bell');
        this.badgeElement = document.getElementById('notification-badge');
        
        if (this.bellButton) {
            this.bellButton.addEventListener('click', this.toggleDropdown);
            this.bellButton.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    this.toggleDropdown();
                }
            });
        }
    }

    /**
     * Configura el dropdown
     */
    setupDropdown() {
        this.dropdownElement = document.getElementById('notification-dropdown');
        this.listElement = document.getElementById('notification-list');
        
        const markAllBtn = document.getElementById('mark-all-read-btn');
        if (markAllBtn) {
            markAllBtn.addEventListener('click', () => this.markAllAsRead());
        }
    }

    /**
     * Configura el cierre del dropdown al hacer clic fuera
     */
    setupClickOutside() {
        document.addEventListener('click', (e) => {
            if (this.dropdownOpen && 
                !e.target.closest('.notification-wrapper')) {
                this.closeDropdown();
            }
        });

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.dropdownOpen) {
                this.closeDropdown();
            }
        });
    }

    /**
     * Conecta al servidor WebSocket
     */
    async connectWebSocket() {
        return new Promise((resolve) => {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${window.location.protocol}//${window.location.host}`;
            
            // Cargar Socket.io desde CDN si no está disponible
            if (typeof io === 'undefined') {
                const script = document.createElement('script');
                script.src = 'https://cdn.socket.io/4.7.2/socket.io.min.js';
                script.onload = () => {
                    this.initializeSocket(wsUrl);
                    resolve();
                };
                document.head.appendChild(script);
            } else {
                this.initializeSocket(wsUrl);
                resolve();
            }
        });
    }

    /**
     * Inicializa la conexión Socket.io
     */
    initializeSocket(wsUrl) {
        this.socket = io(wsUrl, {
            transports: ['websocket', 'polling'],
            timeout: 10000,
            reconnection: true,
            reconnectionAttempts: this.maxReconnectAttempts,
            reconnectionDelay: this.reconnectDelay,
            reconnectionDelayMax: 5000
        });

        this.socket.on('connect', () => {

            this.isConnected = true;
            this.reconnectAttempts = 0;
            this.joinDepartment();
        });

        this.socket.on('disconnect', (reason) => {

            this.isConnected = false;
            
            // Si fue desconexión del servidor, intentar reconectar
            if (reason === 'io server disconnect') {
                this.socket.connect();
            }
        });

        this.socket.on('reconnect', (attemptNumber) => {

            this.loadInitialNotifications(); // Sincronizar notificaciones perdidas
        });

        this.socket.on('reconnect_attempt', (attemptNumber) => {

            this.reconnectAttempts = attemptNumber;
        });

        this.socket.on('reconnect_error', (error) => {

        });

        this.socket.on('reconnect_failed', () => {

            this.showConnectionError();
        });

        this.socket.on('joined', (data) => {

            this.socket.emit('request_count');
        });

        this.socket.on('new_notification', this.handleNewNotification);

        this.socket.on('notification_count', (data) => {
            this.updateBadge(data.count);
        });

        this.socket.on('error', (error) => {

        });
    }

    /**
     * Inicia polling de respaldo periódico
     */
    startPollingFallback() {
        if (this.pollingInterval) return;
        this.pollingInterval = setInterval(() => {
            this.loadInitialNotifications();
        }, 30000); // Cada 30 segundos
    }

    /**
     * Muestra error de conexión al usuario o activa degradación elegante
     */
    showConnectionError() {
        // En serverless, activar silenciosamente el sondeo periódico de respaldo
        this.startPollingFallback();
    }

    /**
     * Maneja reconexión manual
     */
    handleReconnect() {
        if (!this.isConnected && this.socket) {
            this.socket.connect();
        }
    }

    joinDepartment() {
        if (this.socket) {
            this.socket.emit('join_department', {});
        }
    }

    /**
     * Carga las notificaciones iniciales
     */
    async loadInitialNotifications() {
        try {
            const response = await fetch('/api/notifications/unread', {
                credentials: 'include'
            });
            
            if (response.ok) {
                this.notifications = await response.json();
                this.renderNotifications();
                this.updateBadge(this.notifications.length);
            }
        } catch (error) {

        }
    }

    /**
     * Maneja una nueva notificación recibida
     */
    handleNewNotification(notification) {

        
        // Agregar al inicio de la lista
        this.notifications.unshift(notification);
        
        // Mantener solo las últimas 5
        if (this.notifications.length > 5) {
            this.notifications = this.notifications.slice(0, 5);
        }
        
        // Actualizar UI
        this.renderNotifications();
        this.updateBadge(this.notificationCount + 1);
        
        // Mostrar toast
        this.showToast(notification);
        
        // Reproducir sonido
        if (this.config.soundEnabled) {
            this.playNotificationSound();
        }
    }

    /**
     * Renderiza las notificaciones en el dropdown
     */
    renderNotifications() {
        if (!this.listElement) return;
        
        if (this.notifications.length === 0) {
            this.listElement.innerHTML = `
                <div class="notification-empty">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                    </svg>
                    <p>No tienes notificaciones nuevas</p>
                </div>
            `;
            return;
        }

        this.listElement.innerHTML = this.notifications.map(notif => `
            <a href="#" class="notification-item unread" 
               data-id="${notif.id}" 
               data-ticket-id="${notif.ticketId || notif.ticket_id}"
               data-tracking-id="${notif.trackingId || notif.ticket_tracking_id}"
               role="listitem"
               tabindex="0">
                <div class="notification-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
                        <polyline points="14 2 14 8 20 8"/>
                    </svg>
                </div>
                <div class="notification-content">
                    <p class="notification-title">${this.escapeHtml(notif.title)}</p>
                    <p class="notification-message">${this.escapeHtml(notif.message || notif.createdByName || notif.created_by_name)}</p>
                    <span class="notification-time">${this.formatTime(notif.createdAt || notif.created_at)}</span>
                </div>
            </a>
        `).join('');

        // Agregar event listeners
        this.listElement.querySelectorAll('.notification-item').forEach(item => {
            item.addEventListener('click', (e) => this.handleNotificationClick(e, item));
            item.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    this.handleNotificationClick(e, item);
                }
            });
        });
    }

    /**
     * Maneja el clic en una notificación
     */
    async handleNotificationClick(e, item) {
        e.preventDefault();
        
        const notifId = item.dataset.id;
        const ticketId = item.dataset.ticketId;
        

        
        // Marcar como leída
        await this.markAsRead(notifId);
        
        // Cerrar dropdown
        this.closeDropdown();
        
        // Redirigir al ticket (abrir modal o ir a la página)
        if (ticketId) {
            // Intentar múltiples funciones de apertura de ticket
            if (typeof showTicketDetails === 'function') {

                showTicketDetails(parseInt(ticketId));
            } else if (typeof openTicketModal === 'function') {

                openTicketModal(parseInt(ticketId));
            } else {
                // Si no hay función de modal, intentar scroll al ticket en la lista
                const ticketElement = document.querySelector(`[data-ticket-id="${ticketId}"]`);
                if (ticketElement) {
                    ticketElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    ticketElement.classList.add('highlight-ticket');
                    setTimeout(() => ticketElement.classList.remove('highlight-ticket'), 2000);
                } else {

                }
            }
        }
    }

    /**
     * Marca una notificación como leída
     */
    async markAsRead(notifId) {
        try {
            await fetch(`/api/notifications/${notifId}/read`, {
                method: 'PUT',
                credentials: 'include'
            });
            
            // Actualizar lista local
            this.notifications = this.notifications.filter(n => n.id != notifId);
            this.renderNotifications();
            this.updateBadge(Math.max(0, this.notificationCount - 1));
        } catch (error) {

        }
    }

    /**
     * Marca todas las notificaciones como leídas
     */
    async markAllAsRead() {
        try {
            await fetch('/api/notifications/read-all', {
                method: 'PUT',
                credentials: 'include'
            });
            
            this.notifications = [];
            this.renderNotifications();
            this.updateBadge(0);
        } catch (error) {

        }
    }

    /**
     * Actualiza el badge contador
     */
    updateBadge(count) {
        this.notificationCount = count;
        
        if (this.badgeElement) {
            if (count > 0) {
                this.badgeElement.textContent = count > 99 ? '99+' : count;
                this.badgeElement.classList.remove('hidden');
            } else {
                this.badgeElement.classList.add('hidden');
            }
        }
    }

    /**
     * Muestra/oculta el dropdown
     */
    toggleDropdown() {
        if (this.dropdownOpen) {
            this.closeDropdown();
        } else {
            this.openDropdown();
        }
    }

    /**
     * Abre el dropdown
     */
    openDropdown() {
        if (this.dropdownElement) {
            this.dropdownElement.classList.add('active');
            this.dropdownOpen = true;
            this.bellButton?.setAttribute('aria-expanded', 'true');
        }
    }

    /**
     * Cierra el dropdown
     */
    closeDropdown() {
        if (this.dropdownElement) {
            this.dropdownElement.classList.remove('active');
            this.dropdownOpen = false;
            this.bellButton?.setAttribute('aria-expanded', 'false');
        }
    }

    /**
     * Muestra un toast de notificación
     */
    showToast(notification) {
        const toast = document.createElement('div');
        toast.className = 'notification-toast';
        toast.setAttribute('role', 'alert');
        toast.innerHTML = `
            <div class="notification-toast-icon">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
            </div>
            <div class="notification-toast-content">
                <p class="notification-toast-title">${this.escapeHtml(notification.title)}</p>
                <p class="notification-toast-message">${this.escapeHtml(notification.message || notification.createdByName || notification.created_by_name)}</p>
            </div>
            <button class="notification-toast-close" aria-label="Cerrar notificación">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"/>
                    <line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
            </button>
        `;

        // Click en el toast para ir al ticket
        toast.addEventListener('click', (e) => {
            if (!e.target.closest('.notification-toast-close')) {
                this.closeToast(toast);
                if (notification.ticketId || notification.ticket_id) {
                    const ticketId = notification.ticketId || notification.ticket_id;
                    if (typeof openTicketModal === 'function') {
                        openTicketModal(ticketId);
                    }
                }
            }
        });

        // Botón cerrar
        toast.querySelector('.notification-toast-close').addEventListener('click', (e) => {
            e.stopPropagation();
            this.closeToast(toast);
        });

        // Limitar número de toasts
        const existingToasts = this.toastContainer.querySelectorAll('.notification-toast');
        if (existingToasts.length >= this.config.maxToasts) {
            this.closeToast(existingToasts[0]);
        }

        this.toastContainer.appendChild(toast);

        // Auto-cerrar después de un tiempo
        setTimeout(() => {
            if (toast.parentNode) {
                this.closeToast(toast);
            }
        }, this.config.toastDuration);
    }

    /**
     * Cierra un toast
     */
    closeToast(toast) {
        toast.classList.add('hiding');
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    }

    /**
     * Reproduce el sonido de notificación
     */
    playNotificationSound() {
        try {
            // Crear contexto de audio si no existe
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }

            // Crear un sonido de notificación simple
            const oscillator = this.audioContext.createOscillator();
            const gainNode = this.audioContext.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(this.audioContext.destination);

            oscillator.frequency.setValueAtTime(800, this.audioContext.currentTime);
            oscillator.frequency.setValueAtTime(600, this.audioContext.currentTime + 0.1);
            
            gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.3);

            oscillator.start(this.audioContext.currentTime);
            oscillator.stop(this.audioContext.currentTime + 0.3);
        } catch (error) {

        }
    }

    /**
     * Formatea el tiempo relativo
     */
    formatTime(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 1) return 'Ahora mismo';
        if (diffMins < 60) return `Hace ${diffMins} min`;
        if (diffHours < 24) return `Hace ${diffHours}h`;
        if (diffDays < 7) return `Hace ${diffDays}d`;
        
        return date.toLocaleDateString('es-ES', { day: 'numeric', month: 'short' });
    }

    /**
     * Escapa HTML para prevenir XSS
     */
    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    /**
     * Habilita/deshabilita sonidos
     */
    setSoundEnabled(enabled) {
        this.config.soundEnabled = enabled;
    }

    /**
     * Desconecta el WebSocket
     */
    disconnect() {
        if (this.socket) {
            this.socket.disconnect();
            this.socket = null;
            this.isConnected = false;
        }
    }
}

// Crear instancia global
window.notificationSystem = new NotificationSystem();

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', () => {
    // Solo inicializar si existe el botón de notificaciones (usuario autenticado)
    if (document.getElementById('notification-bell')) {
        window.notificationSystem.init();
    }
});
