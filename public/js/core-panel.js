/**
 * core-panel.js - Librería de utilidades y estado central para los paneles del sistema de tickets.
 * Compartido por: administrador, gerencia, support, mantenimiento, rrhh, compras, reportes y notificaciones.
 */

// ==========================================
// 1. ESTADO GLOBAL COMPARTIDO
// ==========================================
window.currentUser = window.currentUser || null;
window.allTickets = window.allTickets || [];
window.filteredTickets = window.filteredTickets || [];
window.currentTicketId = window.currentTicketId || null;
window.refreshInterval = window.refreshInterval || null;
window.autoRefreshInterval = window.autoRefreshInterval || null;
window.isLoading = false;
window.urlTicketOpened = false;
window.activeTicketContextMenu = null;
window.kanbanDragTicketId = null;
window.kanbanDragSourceStatus = null;

// ==========================================
// SISTEMA DE REFRESCO REACTIVO (Anti-Egress)
// ==========================================
/**
 * Sistema centralizado de refresco de tickets.
 * - Escucha el evento 'ticket_updated' por Socket.IO emitido por el servidor.
 * - Cuando no hay socket disponible, usa un heartbeat de EMERGENCIA cada 5 minutos.
 * - ELIMINA la necesidad de setInterval cada 30s en cada módulo.
 *
 * Uso desde cualquier módulo:
 *   window.TicketRefresh.register(() => loadTickets(true));
 *   window.TicketRefresh.unregister();
 */
window.TicketRefresh = (function () {
    let _callback = null;          // función a llamar cuando hay cambios
    let _debounceTimer = null;     // evita múltiples llamadas simultáneas
    let _heartbeatTimer = null;    // fallback cada 5 min si el socket no está
    let _socketBound = false;      // ya se enlazó al socket de notificaciones

    const HEARTBEAT_MS = 5 * 60 * 1000; // 5 minutos (fallback de emergencia)
    const DEBOUNCE_MS  = 800;            // evita ráfagas de eventos

    function _triggerRefresh() {
        if (!_callback) return;
        clearTimeout(_debounceTimer);
        _debounceTimer = setTimeout(() => {
            if (!window.isLoading && _callback) {
                _callback();
            }
        }, DEBOUNCE_MS);
    }

    function _startHeartbeat() {
        if (_heartbeatTimer) return;
        _heartbeatTimer = setInterval(_triggerRefresh, HEARTBEAT_MS);
    }

    function _stopHeartbeat() {
        if (_heartbeatTimer) {
            clearInterval(_heartbeatTimer);
            _heartbeatTimer = null;
        }
    }

    function _bindToSocket() {
        if (_socketBound) return;
        // El NotificationSystem expone el socket en window.notificationSystem.socket
        // Intentamos enlazarnos cuando esté disponible
        const tryBind = () => {
            const ns = window.notificationSystem;
            if (ns && ns.socket) {
                ns.socket.on('ticket_updated', _triggerRefresh);
                ns.socket.on('connect', () => {
                    _stopHeartbeat(); // socket activo → ya no necesitamos heartbeat
                });
                ns.socket.on('disconnect', () => {
                    _startHeartbeat(); // socket caído → activar heartbeat
                });
                // Si el socket ya está conectado al momento del bind, detener heartbeat
                if (ns.isConnected) {
                    _stopHeartbeat();
                } else {
                    _startHeartbeat();
                }
                _socketBound = true;
            }
        };
        // Intentar inmediatamente y luego con retry si el sistema de notificaciones aún no cargó
        tryBind();
        if (!_socketBound) {
            let retries = 0;
            const interval = setInterval(() => {
                tryBind();
                if (_socketBound || ++retries > 20) clearInterval(interval);
            }, 500);
        }
    }

    return {
        /**
         * Registra el callback de refresco para el módulo actual.
         * Llámalo una sola vez al iniciar el módulo, reemplaza startAutoRefresh().
         * @param {Function} fn - función a llamar cuando hay cambios de tickets
         */
        register(fn) {
            _callback = fn;
            _socketBound = false; // resetear para re-enlazar si cambia el módulo
            _bindToSocket();
        },

        /**
         * Desregistra el callback (al hacer logout o cambiar de página).
         */
        unregister() {
            _callback = null;
            _stopHeartbeat();
        },

        /** Fuerza un refresco manual (e.g., al volver a la pestaña). */
        trigger: _triggerRefresh
    };
})();

// Refresco al volver a la pestaña si estuvo inactiva más de 2 minutos
(function () {
    let _hiddenAt = null;
    const STALE_MS = 2 * 60 * 1000;
    document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
            _hiddenAt = Date.now();
        } else if (_hiddenAt && (Date.now() - _hiddenAt) > STALE_MS) {
            if (window.TicketRefresh) window.TicketRefresh.trigger();
        }
    });
})();

// ==========================================
// 2. SEGURIDAD Y SANITIZACIÓN (XSS)
// ==========================================
/**
 * Escapa caracteres especiales de HTML para prevenir inyecciones XSS.
 * @param {string|null|undefined} text
 * @returns {string}
 */
window.escapeHtml = function (text) {
    if (text === null || text === undefined) return '';
    return String(text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
};

// ==========================================
// 3. FORMATEO DE FECHAS Y TIEMPO
// ==========================================
/**
 * Formatea una fecha ISO o string en formato local (Argentina / DD/MM/YYYY HH:mm).
 * @param {string|Date} dateInput
 * @param {boolean} [includeTime=true]
 * @returns {string}
 */
window.formatDate = function (dateInput, includeTime = true) {
    if (!dateInput) return '-';
    try {
        const date = new Date(dateInput);
        if (isNaN(date.getTime())) return String(dateInput);

        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();

        if (!includeTime) {
            return `${day}/${month}/${year}`;
        }

        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${day}/${month}/${year} ${hours}:${minutes}`;
    } catch (e) {
        return String(dateInput);
    }
};

/**
 * Retorna una representación relativa del tiempo transcurrido ("hace 5 min", "hace 2 horas").
 * @param {string|Date} dateInput
 * @returns {string}
 */
window.formatRelativeTime = function (dateInput) {
    if (!dateInput) return '';
    try {
        const date = new Date(dateInput);
        const now = new Date();
        const diffMs = now - date;
        const diffSec = Math.floor(diffMs / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHours = Math.floor(diffMin / 60);
        const diffDays = Math.floor(diffHours / 24);

        if (diffSec < 60) return 'hace un momento';
        if (diffMin < 60) return `hace ${diffMin} min`;
        if (diffHours < 24) return `hace ${diffHours} h`;
        if (diffDays === 1) return 'ayer';
        if (diffDays < 30) return `hace ${diffDays} días`;
        return window.formatDate(dateInput, false);
    } catch (e) {
        return '';
    }
};

// ==========================================
// 4. ETIQUETAS, ESTADOS Y PRIORIDADES
// ==========================================
/**
 * Traduce el código de estado a texto en español.
 * @param {string} status
 * @returns {string}
 */
window.getStatusText = function (status) {
    switch (status) {
        case 'open': return 'Pendiente';
        case 'in-progress': return 'En Progreso';
        case 'closed': return 'Cerrado';
        default: return status || 'Desconocido';
    }
};

/**
 * Genera el HTML de la insignia (badge) de estado.
 * @param {string} status
 * @returns {string}
 */
window.getStatusBadge = function (status) {
    const text = window.getStatusText(status);
    const safeStatus = window.escapeHtml(status || 'open');
    return `<span class="ticket-status status-${safeStatus}">${window.escapeHtml(text)}</span>`;
};

/**
 * Traduce la prioridad a texto en español.
 * @param {string} priority
 * @returns {string}
 */
window.getPriorityText = function (priority) {
    switch (priority) {
        case 'urgent': return 'Urgente';
        case 'high': return 'Alta';
        case 'medium': return 'Media';
        case 'low': return 'Baja';
        default: return priority || 'Media';
    }
};

/**
 * Genera el HTML de la insignia (badge) de prioridad.
 * @param {string} priority
 * @returns {string}
 */
window.getPriorityBadge = function (priority) {
    const text = window.getPriorityText(priority);
    const safePriority = window.escapeHtml(priority || 'medium');
    return `<span class="badge badge-priority-${safePriority}">${window.escapeHtml(text)}</span>`;
};

// ==========================================
// 5. AUTENTICACIÓN Y SESIÓN
// ==========================================
window.logout = function () {
    if (window.refreshInterval) clearInterval(window.refreshInterval);
    if (window.autoRefreshInterval) clearInterval(window.autoRefreshInterval);

    fetch('/api/logout', { method: 'POST', credentials: 'include' })
        .finally(() => {
            window.location.href = '/';
        });
};

window.showLogin = function () {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) loginForm.style.display = 'flex';
};

window.hideLogin = function () {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) loginForm.style.display = 'none';
};

window.togglePassword = function (inputId, button) {
    const input = document.getElementById(inputId);
    if (input) {
        if (input.type === 'password') {
            input.type = 'text';
            if (button) button.textContent = '🙈';
        } else {
            input.type = 'password';
            if (button) button.textContent = '👁️';
        }
    }
};

window.verifySession = function (allowedRoles, onSuccessCallback) {
    return fetch('/api/auth/verify', {
        credentials: 'include'
    })
        .then(async response => {
            if (response.status === 401 || response.status === 403) {
                // Token realmente inválido o expirado
                window.location.href = '/?error=invalid_token';
                return null;
            }
            if (response.status === 429) {
                // Límite de peticiones: NO es token inválido, no expulsar al usuario
                console.warn('⚠️ Rate limit alcanzado en verifySession (429)');
                document.body.style.visibility = 'visible';
                document.body.style.opacity = '1';
                if (typeof window.showToast === 'function') {
                    window.showToast('Demasiadas peticiones al servidor. Por favor espere unos segundos.', 'warning');
                }
                return null;
            }
            if (!response.ok) {
                throw new Error(`Error en verificación de sesión: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            if (!data) return;
            if (data.user && allowedRoles.includes(data.user.role)) {
                window.currentUser = data.user;

                // Actualizar nombres de usuario de forma unificada (#userName vs #currentUserName)
                if (typeof window.updateNavbarUserName === 'function') {
                    window.updateNavbarUserName(window.currentUser.name);
                }

                // Mostrar el documento
                document.body.style.visibility = 'visible';
                document.body.style.opacity = '1';
                document.body.style.transition = 'opacity 0.3s';

                window.hideLogin();

                if (typeof onSuccessCallback === 'function') {
                    onSuccessCallback(data.user);
                }
            } else {
                window.location.href = '/?error=access_denied';
            }
        })
        .catch(err => {
            console.error('Error de conexión o servidor en verifySession:', err);
            // No expulsar al usuario por fallos temporales de conexión o servidor
            document.body.style.visibility = 'visible';
            document.body.style.opacity = '1';
        });
};

// ==========================================
// 6. CLIENTE API ROBUSTO
// ==========================================
/**
 * Wrapper de fetch estandarizado con manejo de credenciales y redirección por sesión expirada.
 * @param {string} url
 * @param {RequestInit} [options={}]
 * @returns {Promise<any>}
 */
window.apiFetch = async function (url, options = {}) {
    const defaultHeaders = {
        'Accept': 'application/json'
    };

    if (options.body && typeof options.body === 'string' && !options.headers?.['Content-Type']) {
        defaultHeaders['Content-Type'] = 'application/json';
    }

    const config = {
        ...options,
        credentials: 'include',
        headers: {
            ...defaultHeaders,
            ...options.headers
        }
    };

    const response = await fetch(url, config);

    if (response.status === 401 || response.status === 403) {
        // Sesión expirada o no autorizada
        if (!url.includes('/api/auth/verify')) {
            if (typeof window.showToast === 'function') {
                window.showToast('Sesión expirada. Redirigiendo...', 'error');
            }
            setTimeout(() => {
                window.location.href = '/?error=session_expired';
            }, 1000);
        }
        throw new Error(`Acceso denegado (${response.status})`);
    }

    if (response.status === 429) {
        let rateLimitMsg = 'Demasiadas peticiones al servidor. Por favor espera unos segundos.';
        try {
            const errData = await response.json();
            if (errData && errData.error) rateLimitMsg = errData.error;
        } catch (_) {}
        if (typeof window.showToast === 'function') {
            window.showToast(rateLimitMsg, 'warning');
        }
        throw new Error(rateLimitMsg);
    }

    if (!response.ok) {
        let errorMsg = `Error en el servidor (${response.status})`;
        try {
            const errorJson = await response.json();
            if (errorJson && errorJson.error) errorMsg = errorJson.error;
        } catch (_) { }
        throw new Error(errorMsg);
    }

    return response.json();
};

// ==========================================
// 7. TOASTS Y NOTIFICACIONES VISUALES
// ==========================================
/**
 * Muestra un mensaje flotante tipo Toast.
 * @param {string} message
 * @param {'success'|'error'|'info'|'warning'} [type='success']
 * @param {number} [duration=3000]
 */
window.showToast = function (message, type = 'success', duration = 3000) {
    let container = document.getElementById('toastContainer');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toastContainer';
        container.style.position = 'fixed';
        container.style.bottom = '20px';
        container.style.right = '20px';
        container.style.zIndex = '99999';
        container.style.display = 'flex';
        container.style.flexDirection = 'column';
        container.style.gap = '10px';
        container.style.pointerEvents = 'none';
        document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    toast.style.padding = '12px 20px';
    toast.style.borderRadius = '8px';
    toast.style.color = '#FFFFFF';
    toast.style.fontSize = '14px';
    toast.style.fontWeight = '500';
    toast.style.boxShadow = '0 4px 12px rgba(0,0,0,0.15)';
    toast.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.pointerEvents = 'auto';

    const colors = {
        success: '#2F9E44',
        error: '#E03131',
        warning: '#F59F00',
        info: '#008B8B'
    };
    toast.style.backgroundColor = colors[type] || colors.info;
    toast.textContent = message;

    container.appendChild(toast);

    // Animación de entrada
    requestAnimationFrame(() => {
        toast.style.opacity = '1';
        toast.style.transform = 'translateY(0)';
    });

    // Salida automática
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(10px)';
        setTimeout(() => {
            if (toast.parentNode) toast.parentNode.removeChild(toast);
        }, 300);
    }, duration);
};

// ==========================================
// 8. FILTROS Y MANEJO DE FECHAS
// ==========================================
/**
 * Sincroniza las fechas mínimas entre inputs de filtro de fechas.
 * @param {string} [startId='startDateFilter']
 * @param {string} [endId='endDateFilter']
 */
window.updateDateMin = function (startId = 'startDateFilter', endId = 'endDateFilter') {
    const startInput = document.getElementById(startId);
    const endInput = document.getElementById(endId);
    if (!startInput || !endInput) return;

    if (startInput.value) {
        endInput.min = startInput.value;
        if (endInput.value && endInput.value < startInput.value) {
            endInput.value = '';
        }
    } else {
        endInput.removeAttribute('min');
    }
};

/**
 * Limpia los filtros de fecha.
 * @param {string} [startId='startDateFilter']
 * @param {string} [endId='endDateFilter']
 * @param {Function} [onClearCallback]
 */
window.clearDateFilters = function (startId = 'startDateFilter', endId = 'endDateFilter', onClearCallback) {
    const startInput = document.getElementById(startId);
    const endInput = document.getElementById(endId);
    if (startInput) startInput.value = '';
    if (endInput) {
        endInput.value = '';
        endInput.removeAttribute('min');
    }
    if (typeof onClearCallback === 'function') {
        onClearCallback();
    }
};

/**
 * Motor común de filtrado de tickets en memoria.
 * @param {Array<Object>} tickets
 * @param {Object} criteria - { status, priority, sede, search, startDate, endDate, department }
 * @returns {Array<Object>}
 */
window.filterTickets = function (tickets, criteria = {}) {
    if (!Array.isArray(tickets)) return [];

    const status = (criteria.status || '').toLowerCase();
    const priority = (criteria.priority || '').toLowerCase();
    const sede = criteria.sede || '';
    const department = criteria.department || '';
    const search = (criteria.search || '').toLowerCase().trim();
    const startDate = criteria.startDate ? new Date(criteria.startDate) : null;
    const endDate = criteria.endDate ? new Date(criteria.endDate) : null;

    if (endDate) {
        endDate.setHours(23, 59, 59, 999);
    }

    return tickets.filter(ticket => {
        // 1. Estado
        if (status && ticket.status !== status) return false;

        // 2. Prioridad
        if (priority && ticket.priority !== priority) return false;

        // 3. Sede
        if (sede && ticket.sede !== sede) return false;

        // 4. Departamento
        if (department && ticket.department !== department) return false;

        // 5. Rango de fechas
        if (startDate || endDate) {
            const ticketDate = new Date(ticket.created_at);
            if (startDate && ticketDate < startDate) return false;
            if (endDate && ticketDate > endDate) return false;
        }

        // 6. Búsqueda por texto (tracking_id, título, descripción, solicitante, sede)
        if (search) {
            const tracking = (ticket.tracking_id || '').toLowerCase();
            const title = (ticket.title || '').toLowerCase();
            const desc = (ticket.description || '').toLowerCase();
            const creator = (ticket.created_by_name || '').toLowerCase();
            const email = (ticket.created_by_email || '').toLowerCase();
            const ticketSede = (ticket.sede || '').toLowerCase();
            const tech = (ticket.assigned_technician || '').toLowerCase();

            const matches = tracking.includes(search) ||
                title.includes(search) ||
                desc.includes(search) ||
                creator.includes(search) ||
                email.includes(search) ||
                ticketSede.includes(search) ||
                tech.includes(search);

            if (!matches) return false;
        }

        return true;
    });
};

// ==========================================
// 9. EXPORTACIÓN UNIVERSAL A CSV
// ==========================================
/**
 * Exporta un array de tickets a formato CSV compatible con Excel (UTF-8 con BOM).
 * @param {Array<Object>} tickets
 * @param {string} [fileName='tickets.csv']
 */
window.exportTicketsToCSV = function (tickets, fileName = 'tickets.csv') {
    if (!Array.isArray(tickets) || tickets.length === 0) {
        if (typeof window.showToast === 'function') {
            window.showToast('No hay tickets para exportar', 'warning');
        } else if (typeof window.showNotification === 'function') {
            window.showNotification('No hay tickets para exportar', 'warning');
        } else if (typeof showNotification === 'function') {
            showNotification('No hay tickets para exportar', 'warning');
        }
        return;
    }

    const headers = [
        'ID Seguimiento',
        'Título',
        'Departamento',
        'Sede',
        'Prioridad',
        'Estado',
        'Solicitante',
        'Email Solicitante',
        'Asignado a',
        'Fecha Creación',
        'Última Actualización'
    ];

    const formatField = (field) => {
        if (field === null || field === undefined) return '""';
        const str = String(field).replace(/"/g, '""');
        return `"${str}"`;
    };

    const rows = tickets.map(t => [
        formatField(t.tracking_id),
        formatField(t.title),
        formatField(t.department),
        formatField(t.sede || 'No especificada'),
        formatField(window.getPriorityText(t.priority)),
        formatField(window.getStatusText(t.status)),
        formatField(t.created_by_name),
        formatField(t.created_by_email),
        formatField(t.assigned_technician ? `${t.assigned_technician} (${t.assigned_to_name || 'Área'})` : (t.assigned_to_name || 'Sin asignar')),
        formatField(window.formatDate(t.created_at)),
        formatField(window.formatDate(t.updated_at || t.created_at))
    ]);

    const csvContent = '\uFEFF' + [
        headers.map(h => `"${h}"`).join(';'),
        ...rows.map(r => r.join(';'))
    ].join('\r\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', fileName);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    if (typeof window.showToast === 'function') {
        window.showToast(`Exportados ${tickets.length} tickets exitosamente`, 'success');
    }
};

// ==========================================
// 10. DEEP LINKING POR URL (?openTicket=ID)
// ==========================================
/**
 * Abre automáticamente un ticket si el parámetro openTicket está presente en la URL.
 * @param {Function} showDetailsFn
 */
window.checkOpenTicketFromUrl = function (showDetailsFn) {
    if (window.urlTicketOpened) return;

    const urlParams = new URLSearchParams(window.location.search);
    const ticketId = urlParams.get('openTicket') || urlParams.get('ticket');

    if (ticketId) {
        const ticketIdInt = parseInt(ticketId);
        if (!isNaN(ticketIdInt)) {
            setTimeout(() => {
                if (typeof showDetailsFn === 'function') {
                    showDetailsFn(ticketIdInt);
                } else if (typeof window.showTicketDetails === 'function') {
                    window.showTicketDetails(ticketIdInt);
                }
                // Limpiar parámetro de la URL sin recargar
                const cleanUrl = window.location.pathname;
                window.history.replaceState({}, document.title, cleanUrl);
                window.urlTicketOpened = true;
            }, 350);
        }
    }
};

// ==========================================
// 11. SISTEMA UNIVERSAL DE PAGINACIÓN (5 TICKETS POR PÁGINA)
// ==========================================
window.ITEMS_PER_PAGE = 5;

/**
 * Genera el HTML de una tarjeta vertical de ticket.
 * @param {Object} ticket
 * @returns {string}
 */
window.buildVerticalTicketCard = function (ticket) {
    const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;
    const priorityText = window.getPriorityText ? window.getPriorityText(ticket.priority) : (ticket.priority === 'high' ? '🔴 Alta' : ticket.priority === 'medium' ? '🟡 Media' : '🟢 Baja');
    const statusText = window.getStatusText ? window.getStatusText(ticket.status) : ticket.status;
    const isNew = (ticket.status === 'open' && window.isNewTicket) ? window.isNewTicket(ticket.created_at) : false;
    const relativeTime = window.formatRelativeTime ? window.formatRelativeTime(ticket.created_at) : '';
    const formattedDate = window.formatDate ? window.formatDate(ticket.created_at) : '';

    return `
    <div class="ticket-item ticket-card-vertical priority-${ticket.priority || 'medium'}"
         onclick="showTicketDetails(${ticket.id})"
         tabindex="0"
         role="button"
         aria-label="Ticket ${trackingId} - ${statusText}">
        <div class="ticket-header">
            <div class="ticket-title">${window.escapeHtml(ticket.title)}</div>
            <div class="ticket-meta">
                <span class="ticket-status status-${ticket.status}">${statusText}</span>
                <span class="ticket-priority-pill priority-pill-${ticket.priority}">
                    ${ticket.priority === 'high' ? '🔴 Alta' : ticket.priority === 'medium' ? '🟡 Media' : '🟢 Baja'}
                </span>
                ${isNew ? '<span class="badge-new">✨ NUEVO</span>' : ''}
                <span class="ticket-tracking-chip">🔍 ${window.escapeHtml(trackingId)}</span>
                <span class="ticket-meta-time">${relativeTime}</span>
            </div>
        </div>
        ${ticket.description ? `<div class="ticket-description">${window.escapeHtml(ticket.description).substring(0, 140)}${ticket.description.length > 140 ? '...' : ''}</div>` : ''}
        <div class="ticket-info">
            <div><strong>📍 Sede:</strong> ${window.escapeHtml(ticket.sede || 'No especificada')}</div>
            <div><strong>📁 Depto:</strong> ${window.escapeHtml(ticket.department || 'General')}</div>
            <div><strong>👤 Solicitante:</strong> ${window.escapeHtml(ticket.created_by_name || 'Desconocido')}</div>
            <div><strong>🛠️ Asignado:</strong> ${ticket.assigned_technician ? `<span class="assigned-tech-badge">👤 ${window.escapeHtml(ticket.assigned_technician)}</span>` : window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
            <div><strong>📅 Fecha:</strong> ${formattedDate}</div>
        </div>
    </div>
    `;
};

/**
 * Renderiza los controles de paginación universal.
 * @param {string} containerId
 * @param {number} currentPage
 * @param {number} totalItems
 * @param {number} [itemsPerPage=5]
 * @param {string} [onPageChangeFnName='changePage']
 */
window.renderUniversalPagination = function (containerId, currentPage, totalItems, itemsPerPage = 5, onPageChangeFnName = 'changePage') {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (totalItems <= 0) {
        container.style.display = 'none';
        return;
    }

    const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;
    container.style.display = 'flex';

    const startIdx = ((currentPage - 1) * itemsPerPage) + 1;
    const endIdx = Math.min(currentPage * itemsPerPage, totalItems);

    let paginationHtml = `
        <div class="pagination-info">
            Mostrando <strong>${startIdx} - ${endIdx}</strong> de <strong>${totalItems}</strong> tickets (Página ${currentPage} de ${totalPages})
        </div>
        <div class="pagination-controls">
            <button class="btn-page" ${currentPage <= 1 ? 'disabled' : ''} onclick="${onPageChangeFnName}(${currentPage - 1})" title="Página anterior" aria-label="Página anterior">
                ◀ Anterior
            </button>
            <div class="page-numbers">
    `;

    // Smart pagination numbers
    let startPage = Math.max(1, currentPage - 2);
    let endPage = Math.min(totalPages, startPage + 4);
    if (endPage - startPage < 4) {
        startPage = Math.max(1, endPage - 4);
    }

    if (startPage > 1) {
        paginationHtml += `<button class="page-num" onclick="${onPageChangeFnName}(1)" aria-label="Ir a página 1">1</button>`;
        if (startPage > 2) paginationHtml += `<span class="pagination-ellipsis" aria-hidden="true">...</span>`;
    }

    for (let p = startPage; p <= endPage; p++) {
        paginationHtml += `
            <button class="page-num ${p === currentPage ? 'active' : ''}" onclick="${onPageChangeFnName}(${p})" aria-label="Ir a página ${p}" ${p === currentPage ? 'aria-current="page"' : ''}>
                ${p}
            </button>
        `;
    }

    if (endPage < totalPages) {
        if (endPage < totalPages - 1) paginationHtml += `<span class="pagination-ellipsis" aria-hidden="true">...</span>`;
        paginationHtml += `<button class="page-num" onclick="${onPageChangeFnName}(${totalPages})" aria-label="Ir a página ${totalPages}">${totalPages}</button>`;
    }

    paginationHtml += `
            </div>
            <button class="btn-page" ${currentPage >= totalPages ? 'disabled' : ''} onclick="${onPageChangeFnName}(${currentPage + 1})" title="Página siguiente" aria-label="Página siguiente">
                Siguiente ▶
            </button>
        </div>
    `;

    container.innerHTML = paginationHtml;
};

// ==========================================
// 12. TABLERO KANBAN UNIVERSAL (3 COLUMNAS + DRAG & DROP + 5 POR COLUMNA)
// ==========================================
window.buildKanbanCard = function (ticket, isReadOnly = false) {
    const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;
    const statusText = window.getStatusText ? window.getStatusText(ticket.status) : ticket.status;
    const priorityPill = ticket.priority === 'high' ? '🔴 Alta' : (ticket.priority === 'medium' ? '🟡 Media' : '🟢 Baja');
    const isNew = (ticket.status === 'open' && window.isNewTicket) ? window.isNewTicket(ticket.created_at) : false;
    const timeAgo = window.formatRelativeTime ? window.formatRelativeTime(ticket.created_at) : (window.getRelativeTime ? window.getRelativeTime(ticket.created_at) : '');

    return `
    <div class='ticket-item kanban-card priority-${ticket.priority || 'medium'}'
         onclick='showTicketDetails(${ticket.id})'
         draggable='${!isReadOnly}'
         data-ticket-id='${ticket.id}'
         data-status='${ticket.status}'
         tabindex="0"
         role="button"
         aria-label="Ticket ${trackingId} - ${statusText}"
         onkeydown='handleTicketKeydown(event, ${ticket.id}, "${ticket.status}")'
         oncontextmenu='${isReadOnly ? "event.preventDefault();" : `openTicketContextMenu(event, ${ticket.id}, "${ticket.status}")`}'
         ondragstart='${isReadOnly ? "event.preventDefault();" : "handleKanbanDragStart(event)"}'
         ondragend='handleKanbanDragEnd(event)'>
        <div class="ticket-header">
            <div class="ticket-title">${window.escapeHtml(ticket.title)}</div>
            <div class="ticket-meta">
                <span class="ticket-status status-${ticket.status}">${statusText}</span>
                <span class="ticket-priority-pill priority-pill-${ticket.priority || 'medium'}">
                    ${priorityPill}
                </span>
                ${isNew ? '<span class="badge-new">✨ NUEVO</span>' : ''}
                <span class="ticket-tracking-chip">🔍 ${window.escapeHtml(trackingId)}</span>
                <span class="ticket-meta-time">${timeAgo}</span>
            </div>
        </div>
        ${ticket.description ? `<div class="ticket-description">${window.escapeHtml(ticket.description).substring(0, 95)}${ticket.description.length > 95 ? '...' : ''}</div>` : ''}
        <div class="ticket-info">
            <div><strong>📍 Sede:</strong> ${window.escapeHtml(ticket.sede || 'No especificada')}</div>
            <div><strong>📁 Depto:</strong> ${window.escapeHtml(ticket.department || 'General')}</div>
            <div><strong>👤 Solicitante:</strong> ${window.escapeHtml(ticket.created_by_name || 'Desconocido')}</div>
            <div><strong>🛠️ Asignado:</strong> ${ticket.assigned_technician ? `<span class="assigned-tech-badge">👤 ${window.escapeHtml(ticket.assigned_technician)}</span>` : window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
        </div>
    </div>
    `;
};

window.renderKanbanBoard = function (containerId, tickets, columnPages, onColumnPageChangeName = 'changeColumnPage', isReadOnly = false) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (!tickets || tickets.length === 0) {
        container.innerHTML = '<div class="empty-state-box">No hay tickets para mostrar con los filtros seleccionados</div>';
        return;
    }

    const openTickets = tickets.filter(t => t.status === 'open');
    const inProgressTickets = tickets.filter(t => t.status === 'in-progress');
    const closedTickets = tickets.filter(t => t.status === 'closed');

    const itemsPerCol = 5;

    const buildColumn = (status, title, subtitle, colTickets) => {
        const totalItems = colTickets.length;
        const totalPages = Math.ceil(totalItems / itemsPerCol) || 1;
        let page = columnPages && columnPages[status] ? columnPages[status] : 1;
        if (page > totalPages) page = totalPages;
        if (page < 1) page = 1;
        if (columnPages) columnPages[status] = page;

        const startIdx = (page - 1) * itemsPerCol;
        const endIdx = startIdx + itemsPerCol;
        const pageTickets = colTickets.slice(startIdx, endIdx);

        const bodyContent = colTickets.length === 0
            ? `<div class='kanban-empty'>No hay tickets ${title.toLowerCase()}</div>`
            : pageTickets.map(t => window.buildKanbanCard(t, isReadOnly)).join('');

        const paginationHtml = totalPages > 1 ? `
            <div class="kanban-column-pagination">
                <button class="btn-col-page" ${page <= 1 ? 'disabled' : ''} onclick="event.stopPropagation(); ${onColumnPageChangeName}('${status}', ${page - 1})" aria-label="Página anterior en columna ${title}">◀ Anterior</button>
                <span class="col-page-info">${page} / ${totalPages} (${totalItems})</span>
                <button class="btn-col-page" ${page >= totalPages ? 'disabled' : ''} onclick="event.stopPropagation(); ${onColumnPageChangeName}('${status}', ${page + 1})" aria-label="Página siguiente en columna ${title}">Siguiente ▶</button>
            </div>
        ` : '';

        return `
        <div class="kanban-column" data-status="${status}">
            <div class="kanban-column-header">
                <div>
                    <div class="kanban-column-title">${title}</div>
                    <div class="kanban-column-subtitle">${subtitle}</div>
                </div>
                <div class="kanban-column-count">${totalItems}</div>
            </div>
            <div class="kanban-column-body"
                 data-status="${status}"
                 ondragover="handleKanbanDragOver(event)"
                 ondrop="handleKanbanDrop(event, '${status}')"
                 ondragleave="handleKanbanDragLeave(event)">
                ${bodyContent}
            </div>
            ${paginationHtml}
        </div>`;
    };

    container.innerHTML = `
        <div class="kanban-board">
            ${buildColumn('open', '🟡 Pendientes', 'Tickets por iniciar', openTickets)}
            ${buildColumn('in-progress', '🔵 En Progreso', 'Tickets en tratamiento', inProgressTickets)}
            ${buildColumn('closed', '🟢 Cerrados', 'Tickets resueltos', closedTickets)}
        </div>
    `;
};

// ==========================================
// 13. SISTEMA DE TABS + GRILLA 3X5 + ACCIONES RÁPIDAS
// ==========================================
window.ITEMS_PER_GRID_PAGE = 15;

/**
 * Genera el HTML de una tarjeta para la grilla 3x5 con botones de acción rápida.
 * @param {Object} ticket
 * @param {boolean} isReadOnly
 * @returns {string}
 */
window.buildGridTicketCard = function (ticket, isReadOnly = false) {
    const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;
    const status = ticket.status || 'open';
    const statusText = window.getStatusText ? window.getStatusText(status) : status;
    const priorityPill = ticket.priority === 'high' ? '🔴 Alta' : (ticket.priority === 'medium' ? '🟡 Media' : '🟢 Baja');
    const isNew = (ticket.status === 'open' && window.isNewTicket) ? window.isNewTicket(ticket.created_at) : false;
    const timeAgo = window.formatRelativeTime ? window.formatRelativeTime(ticket.created_at) : (window.getRelativeTime ? window.getRelativeTime(ticket.created_at) : '');

    let quickButtons = '';
    if (!isReadOnly) {
        if (status === 'open') {
            quickButtons = `
                <button type="button" class="btn-quick-action action-in-progress" title="Mover a En Progreso" aria-label="Mover a En Progreso" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'in-progress');">
                    🔵 En Progreso
                </button>
                <button type="button" class="btn-quick-action action-closed" title="Mover a Cerrado" aria-label="Mover a Cerrado" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'closed');">
                    🟢 Cerrar
                </button>
            `;
        } else if (status === 'in-progress') {
            quickButtons = `
                <button type="button" class="btn-quick-action action-open" title="Mover a Pendiente" aria-label="Mover a Pendiente" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'open');">
                    🟡 Pendiente
                </button>
                <button type="button" class="btn-quick-action action-closed" title="Mover a Cerrado" aria-label="Mover a Cerrado" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'closed');">
                    🟢 Cerrar
                </button>
            `;
        } else if (status === 'closed') {
            quickButtons = `
                <button type="button" class="btn-quick-action action-open" title="Reabrir Ticket" aria-label="Reabrir Ticket" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'open');">
                    🟡 Reabrir
                </button>
                <button type="button" class="btn-quick-action action-in-progress" title="Mover a En Progreso" aria-label="Mover a En Progreso" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'in-progress');">
                    🔵 En Progreso
                </button>
            `;
        }
    }

    return `
    <div class="ticket-item ticket-grid-card priority-${ticket.priority || 'medium'}"
         onclick="showTicketDetails(${ticket.id})"
         tabindex="0"
         role="button"
         aria-label="Ticket ${trackingId} - ${statusText}">
        <div>
            <div class="ticket-header">
                <div class="ticket-title" title="${window.escapeHtml(ticket.title)}">${window.escapeHtml(ticket.title)}</div>
            </div>
            <div class="ticket-meta">
                <span class="ticket-status status-${ticket.status}">${statusText}</span>
                <span class="ticket-priority-pill priority-pill-${ticket.priority || 'medium'}">${priorityPill}</span>
                ${isNew ? '<span class="badge-new">✨ NUEVO</span>' : ''}
                <span class="ticket-tracking-chip">🔍 ${window.escapeHtml(trackingId)}</span>
                <span class="ticket-meta-time">${timeAgo}</span>
            </div>
            ${ticket.description ? `<div class="ticket-description" title="${window.escapeHtml(ticket.description)}">${window.escapeHtml(ticket.description)}</div>` : ''}
        </div>

        <div>
            <div class="ticket-info">
                <div><strong>📍 Sede:</strong> ${window.escapeHtml(ticket.sede || 'Ciudad')}</div>
                <div><strong>📁 Depto:</strong> ${window.escapeHtml(ticket.department || 'General')}</div>
                <div title="${window.escapeHtml(ticket.created_by_name || 'Desconocido')}"><strong>👤 Solicitante:</strong> ${window.escapeHtml(ticket.created_by_name || 'Desconocido')}</div>
                <div title="${window.escapeHtml(ticket.assigned_technician ? `${ticket.assigned_technician} (${ticket.assigned_to_name || ''})` : (ticket.assigned_to_name || 'Sin asignar'))}"><strong>🛠️ Asignado:</strong> ${ticket.assigned_technician ? `<span class="assigned-tech-badge">👤 ${window.escapeHtml(ticket.assigned_technician)}</span>` : window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
            </div>

            ${quickButtons ? `<div class="ticket-quick-actions">${quickButtons}</div>` : ''}
        </div>
    </div>
    `;
};

window.triggerTicketStatusChange = function (ticketId, targetStatus) {
    if (typeof updateTicketStatus === 'function') {
        updateTicketStatus(ticketId, targetStatus);
    } else if (typeof window.updateTicketStatus === 'function') {
        window.updateTicketStatus(ticketId, targetStatus);
    }
};

window.renderTabbedTicketView = function (containerId, filteredTickets, activeTab, tabPages, onTabChangeFnName = 'switchTicketTab', onPageChangeFnName = 'changeTabPage', isReadOnly = false) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const allTicketsList = Array.isArray(filteredTickets) ? filteredTickets : [];

    const openCount = allTicketsList.filter(t => t.status === 'open').length;
    const inProgressCount = allTicketsList.filter(t => t.status === 'in-progress').length;
    const closedCount = allTicketsList.filter(t => t.status === 'closed').length;

    const currentTab = activeTab || 'open';
    const tabTickets = allTicketsList.filter(t => t.status === currentTab);

    const itemsPerPage = window.ITEMS_PER_GRID_PAGE || 15;
    const totalItems = tabTickets.length;
    const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;

    let currentPage = tabPages && tabPages[currentTab] ? tabPages[currentTab] : 1;
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    if (tabPages) tabPages[currentTab] = currentPage;

    const startIdx = (currentPage - 1) * itemsPerPage;
    const endIdx = startIdx + itemsPerPage;
    const pageTickets = tabTickets.slice(startIdx, endIdx);

    const tabsHtml = `
        <div class="ticket-tabs-container" role="tablist" aria-label="Filtrar tickets por estado">
            <button type="button" role="tab" aria-selected="${currentTab === 'open'}" class="ticket-tab ${currentTab === 'open' ? 'active' : ''}" data-status="open" onclick="${onTabChangeFnName}('open')">
                <span aria-hidden="true">🟡</span>
                <span>Pendientes</span>
                <span class="tab-badge">${openCount}</span>
            </button>
            <button type="button" role="tab" aria-selected="${currentTab === 'in-progress'}" class="ticket-tab ${currentTab === 'in-progress' ? 'active' : ''}" data-status="in-progress" onclick="${onTabChangeFnName}('in-progress')">
                <span aria-hidden="true">🔵</span>
                <span>En Progreso</span>
                <span class="tab-badge">${inProgressCount}</span>
            </button>
            <button type="button" role="tab" aria-selected="${currentTab === 'closed'}" class="ticket-tab ${currentTab === 'closed' ? 'active' : ''}" data-status="closed" onclick="${onTabChangeFnName}('closed')">
                <span aria-hidden="true">🟢</span>
                <span>Cerrados</span>
                <span class="tab-badge">${closedCount}</span>
            </button>
        </div>
    `;

    let contentHtml = '';
    if (pageTickets.length === 0) {
        const tabLabel = currentTab === 'open' ? 'pendientes' : (currentTab === 'in-progress' ? 'en progreso' : 'cerrados');
        contentHtml = `
            <div class="empty-state-box">
                <div class="empty-icon" aria-hidden="true">📭</div>
                <h3>No hay tickets ${tabLabel}</h3>
                <p>No se encontraron tickets con los filtros y búsqueda actuales.</p>
            </div>
        `;
    } else {
        contentHtml = `
            <div class="tickets-grid-3x5">
                ${pageTickets.map(t => window.buildGridTicketCard(t, isReadOnly)).join('')}
            </div>
        `;
    }

    container.innerHTML = tabsHtml + contentHtml;

    // Paginación universal
    const pagContainer = document.getElementById('paginationContainer');
    if (pagContainer) {
        if (totalItems > 0) {
            window.renderUniversalPagination('paginationContainer', currentPage, totalItems, itemsPerPage, onPageChangeFnName);
        } else {
            pagContainer.style.display = 'none';
        }
    }
};

// ==========================================
// 12. UTILIDAD UNIVERSAL DE COPIADO AL PORTAPAPELES
// ==========================================
/**
 * Copia texto al portapapeles de forma robusta con soporte para contextos seguros e inseguros (HTTP/HTTPS/Localhost).
 * @param {string} text
 * @param {string} [successMessage='Copiado al portapapeles']
 * @returns {Promise<boolean>}
 */
window.copyToClipboard = function (text, successMessage = 'Copiado al portapapeles') {
    if (!text) {
        return Promise.reject(new Error('No hay texto para copiar'));
    }

    function notifySuccess() {
        if (typeof window.showToast === 'function') {
            window.showToast(successMessage, 'success');
        } else if (typeof window.showSuccess === 'function') {
            window.showSuccess(successMessage);
        } else if (typeof window.showNotification === 'function') {
            window.showNotification(successMessage, 'success');
        } else if (typeof showNotification === 'function') {
            showNotification(successMessage, 'success');
        }
    }

    function fallbackExecCopy() {
        try {
            const textArea = document.createElement('textarea');
            textArea.value = text;
            textArea.style.position = 'fixed';
            textArea.style.top = '0';
            textArea.style.left = '0';
            textArea.style.width = '2em';
            textArea.style.height = '2em';
            textArea.style.padding = '0';
            textArea.style.border = 'none';
            textArea.style.outline = 'none';
            textArea.style.boxShadow = 'none';
            textArea.style.background = 'transparent';
            textArea.style.opacity = '0';
            textArea.setAttribute('readonly', '');
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();
            textArea.setSelectionRange(0, 99999);
            const successful = document.execCommand('copy');
            document.body.removeChild(textArea);
            if (successful) {
                notifySuccess();
                return Promise.resolve(true);
            } else {
                throw new Error('execCommand falló');
            }
        } catch (err) {
            console.error('Error en copiado fallback:', err);
            prompt('Copia manualmente este texto:', text);
            return Promise.reject(err);
        }
    }

    if (navigator.clipboard && window.isSecureContext) {
        return navigator.clipboard.writeText(text)
            .then(() => {
                notifySuccess();
                return true;
            })
            .catch(() => {
                return fallbackExecCopy();
            });
    } else {
        return fallbackExecCopy();
    }
};

// ==========================================
// 14. SISTEMA UNIVERSAL DE LIGHTBOX (PANTALLA COMPLETA PARA IMÁGENES Y ADJUNTOS)
// ==========================================
(function () {
    let lightboxEl = null;
    let escHandlerAttached = false;
    let closeTimeout = null;

    function normalizeAttachmentUrl(url) {
        if (!url) return '';
        if (typeof url === 'object' && url !== null) {
            url = url.url || url.src || url.path || '';
        }
        if (typeof url !== 'string') return '';
        let clean = url.trim().replace(/\\/g, '/');
        if (!clean.startsWith('http://') && !clean.startsWith('https://') && !clean.startsWith('data:') && !clean.startsWith('blob:') && !clean.startsWith('/')) {
            clean = '/' + clean;
        }
        return clean;
    }

    function createUniversalLightbox() {
        if (lightboxEl && document.body.contains(lightboxEl)) {
            return lightboxEl;
        }

        // Eliminar elementos residuales o conflictivos de versiones previas
        const oldLegacyIds = ['imageLightbox', 'lightboxModal', 'coreUniversalLightbox'];
        oldLegacyIds.forEach(id => {
            const oldEl = document.getElementById(id);
            if (oldEl) oldEl.remove();
        });

        lightboxEl = document.createElement('div');
        lightboxEl.id = 'coreUniversalLightbox';
        lightboxEl.setAttribute('role', 'dialog');
        lightboxEl.setAttribute('aria-modal', 'true');
        lightboxEl.setAttribute('aria-label', 'Visualizador de imagen adjunta');
        lightboxEl.style.cssText = `
            display: none;
            position: fixed;
            inset: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(10, 15, 29, 0.92);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            z-index: 999999;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 24px;
            box-sizing: border-box;
            opacity: 0;
            transition: opacity 0.22s cubic-bezier(0.16, 1, 0.3, 1);
            user-select: none;
        `;

        lightboxEl.innerHTML = `
            <!-- Barra superior con controles modernos -->
            <div id="coreLightboxHeader" style="position: absolute; top: 18px; right: 24px; display: flex; align-items: center; gap: 10px; z-index: 1000002; pointer-events: auto;">
                <a id="coreLightboxOpenNewTab" href="#" target="_blank" rel="noopener noreferrer" 
                   title="Abrir imagen original en nueva pestaña"
                   style="display: inline-flex; align-items: center; gap: 6px; padding: 8px 16px; background: rgba(255,255,255,0.14); color: #ffffff; text-decoration: none; border-radius: 20px; font-size: 13px; font-weight: 600; font-family: 'Montserrat', sans-serif; border: 1px solid rgba(255,255,255,0.25); backdrop-filter: blur(8px); transition: all 0.2s ease;">
                    <span style="font-size: 14px;">↗</span>
                    <span>Abrir original</span>
                </a>
                <a id="coreLightboxDownload" href="#" download="adjunto-ticket" 
                   title="Descargar imagen"
                   style="display: inline-flex; align-items: center; gap: 6px; padding: 8px 16px; background: rgba(255,255,255,0.14); color: #ffffff; text-decoration: none; border-radius: 20px; font-size: 13px; font-weight: 600; font-family: 'Montserrat', sans-serif; border: 1px solid rgba(255,255,255,0.25); backdrop-filter: blur(8px); transition: all 0.2s ease;">
                    <span style="font-size: 14px;">⬇</span>
                    <span>Descargar</span>
                </a>
                <button type="button" id="coreLightboxCloseBtn" 
                        title="Cerrar (Esc)"
                        aria-label="Cerrar imagen"
                        style="display: inline-flex; align-items: center; justify-content: center; width: 42px; height: 42px; background: rgba(255,255,255,0.18); color: #ffffff; border: 1px solid rgba(255,255,255,0.3); border-radius: 50%; font-size: 26px; cursor: pointer; line-height: 1; transition: all 0.2s ease; outline: none;">
                    &times;
                </button>
            </div>

            <!-- Spinner de carga -->
            <div id="coreLightboxSpinner" style="display: none; flex-direction: column; align-items: center; justify-content: center; gap: 14px; color: #ffffff;">
                <div style="width: 46px; height: 46px; border: 4px solid rgba(255,255,255,0.2); border-top-color: #6366f1; border-radius: 50%; animation: coreLightboxSpin 0.8s linear infinite;"></div>
                <span style="font-size: 14px; font-weight: 500; font-family: 'Montserrat', sans-serif; letter-spacing: 0.3px; opacity: 0.9;">Cargando imagen...</span>
            </div>

            <!-- Contenedor de Error si la imagen no existe o no carga -->
            <div id="coreLightboxError" style="display: none; flex-direction: column; align-items: center; gap: 12px; color: #fecaca; text-align: center; max-width: 420px; padding: 24px; background: rgba(220, 38, 38, 0.18); border: 1px solid rgba(239, 68, 68, 0.4); border-radius: 12px;">
                <span style="font-size: 34px;">⚠️</span>
                <span style="font-size: 15px; font-weight: 600; font-family: 'Montserrat', sans-serif;">No se pudo cargar la imagen adjunta</span>
                <span style="font-size: 12px; opacity: 0.85; font-family: 'Montserrat', sans-serif;">Es posible que el archivo haya expirado o la URL no esté disponible.</span>
                <a id="coreLightboxRetryLink" href="#" target="_blank" style="margin-top: 6px; color: #ffffff; text-decoration: underline; font-size: 13px; font-weight: 500;">Intentar abrir enlace directamente</a>
            </div>

            <!-- Contenedor centrado de la imagen -->
            <div style="display: flex; align-items: center; justify-content: center; width: 100%; height: 100%; max-height: calc(100vh - 80px); pointer-events: none;">
                <img id="coreLightboxImg" 
                     src="" 
                     alt="Adjunto de ticket en tamaño completo" 
                     style="max-width: 92vw; max-height: 84vh; width: auto; height: auto; object-fit: contain; border-radius: 10px; box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.9), 0 0 0 1px rgba(255, 255, 255, 0.15); pointer-events: auto; transform: scale(0.96); transition: transform 0.22s cubic-bezier(0.16, 1, 0.3, 1); display: none; cursor: zoom-out;">
            </div>
        `;

        // Inyectar estilos auxiliares
        if (!document.getElementById('coreLightboxStyles')) {
            const style = document.createElement('style');
            style.id = 'coreLightboxStyles';
            style.textContent = `
                @keyframes coreLightboxSpin {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }
                #coreLightboxCloseBtn:hover {
                    background: rgba(239, 68, 68, 0.95) !important;
                    border-color: rgba(239, 68, 68, 1) !important;
                    transform: scale(1.1);
                }
                #coreLightboxOpenNewTab:hover, #coreLightboxDownload:hover {
                    background: rgba(255, 255, 255, 0.28) !important;
                    border-color: rgba(255, 255, 255, 0.5) !important;
                    transform: translateY(-2px);
                }
                .attachment-thumb-wrapper:hover {
                    border-color: #008B8B !important;
                    transform: translateY(-2px);
                    box-shadow: 0 6px 14px rgba(0, 0, 0, 0.15);
                }
            `;
            document.head.appendChild(style);
        }

        document.body.appendChild(lightboxEl);

        // Click en botón cerrar
        const closeBtn = document.getElementById('coreLightboxCloseBtn');
        if (closeBtn) {
            closeBtn.onclick = function (e) {
                e.preventDefault();
                e.stopPropagation();
                window.closeLightbox();
            };
        }

        // Click en el fondo o en la imagen para cerrar
        lightboxEl.onclick = function (e) {
            const header = document.getElementById('coreLightboxHeader');
            const err = document.getElementById('coreLightboxError');
            if ((!header || !header.contains(e.target)) && (!err || !err.contains(e.target))) {
                window.closeLightbox();
            }
        };

        // Escuchar tecla ESC
        if (!escHandlerAttached) {
            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape' || e.key === 'Esc') {
                    if (lightboxEl && lightboxEl.style.display === 'flex') {
                        window.closeLightbox();
                    }
                }
            });
            escHandlerAttached = true;
        }

        return lightboxEl;
    }

    /**
     * Abre cualquier imagen en pantalla completa con diseño moderno y soporte para zoom/descarga.
     * @param {string} rawUrl
     */
    function openUniversalLightbox(rawUrl) {
        const url = normalizeAttachmentUrl(rawUrl);
        if (!url) return;

        createUniversalLightbox();

        if (closeTimeout) {
            clearTimeout(closeTimeout);
            closeTimeout = null;
        }

        const img = document.getElementById('coreLightboxImg');
        const spinner = document.getElementById('coreLightboxSpinner');
        const errorContainer = document.getElementById('coreLightboxError');
        const openNewTab = document.getElementById('coreLightboxOpenNewTab');
        const downloadBtn = document.getElementById('coreLightboxDownload');
        const retryLink = document.getElementById('coreLightboxRetryLink');

        if (openNewTab) openNewTab.href = url;
        if (retryLink) retryLink.href = url;
        if (downloadBtn) {
            downloadBtn.href = url;
            const filename = url.split('/').pop().split('?')[0] || 'adjunto-ticket';
            downloadBtn.setAttribute('download', filename);
        }

        if (img && spinner && errorContainer) {
            img.style.display = 'none';
            img.style.transform = 'scale(0.96)';
            errorContainer.style.display = 'none';
            spinner.style.display = 'flex';

            const onImageReady = () => {
                spinner.style.display = 'none';
                img.style.display = 'block';
                requestAnimationFrame(() => {
                    img.style.transform = 'scale(1)';
                });
            };

            img.onload = onImageReady;
            img.onerror = function () {
                spinner.style.display = 'none';
                img.style.display = 'none';
                errorContainer.style.display = 'flex';
            };

            img.src = url;

            if (img.complete && img.naturalWidth > 0) {
                onImageReady();
            }
        }

        lightboxEl.style.display = 'flex';
        if (window.ModalScrollLock) {
            window.ModalScrollLock.lock();
        } else {
            document.body.style.overflow = 'hidden';
        }
        requestAnimationFrame(() => {
            if (lightboxEl) lightboxEl.style.opacity = '1';
        });
    }

    /**
     * Cierra el visor de pantalla completa y restaura el scroll.
     * @param {Event} [event]
     */
    function closeUniversalLightbox(event) {
        if (lightboxEl) {
            lightboxEl.style.opacity = '0';
            if (closeTimeout) clearTimeout(closeTimeout);
            closeTimeout = setTimeout(() => {
                lightboxEl.style.display = 'none';
                const img = document.getElementById('coreLightboxImg');
                if (img) img.src = '';
                if (window.ModalScrollLock) {
                    window.ModalScrollLock.unlock();
                } else {
                    document.body.style.overflow = '';
                }
            }, 220);
        } else {
            if (window.ModalScrollLock) {
                window.ModalScrollLock.unlock();
            } else {
                document.body.style.overflow = '';
            }
        }

        // Limpieza de cualquier elemento legacy que pudiera estar abierto
        const legacy1 = document.getElementById('imageLightbox');
        if (legacy1) legacy1.style.display = 'none';
        const legacy2 = document.getElementById('lightboxModal');
        if (legacy2) legacy2.style.display = 'none';
    }

    // Exponer de forma global y segura
    window.openLightbox = openUniversalLightbox;
    window.closeLightbox = closeUniversalLightbox;
    window.viewFullImage = openUniversalLightbox;

    /**
     * Helper universal para renderizar la galería de adjuntos de forma consistente y protegida.
     * @param {string|Array} attachments
     * @returns {string} HTML seguro
     */
    window.renderTicketAttachments = function (attachments) {
        let files = [];
        try {
            if (typeof attachments === 'string') {
                files = JSON.parse(attachments);
            } else if (Array.isArray(attachments)) {
                files = attachments;
            }
        } catch (e) { }

        if (!files || files.length === 0) return '';

        return `
            <div class="attachments-section">
                <h4 class="attachments-section-title">
                    <span>📎</span> <span>Archivos Adjuntos (${files.length})</span>
                </h4>
                <div class="attachment-gallery" style="display: flex; gap: 10px; flex-wrap: wrap; margin-top: 10px;">
                    ${files.map(rawUrl => {
                        if (!rawUrl) return '';
                        const safeUrl = window.escapeHtml(normalizeAttachmentUrl(rawUrl));
                        return `
                            <div class="attachment-thumb-wrapper" 
                                 data-url="${safeUrl}"
                                 onclick="window.openLightbox ? window.openLightbox(this.getAttribute('data-url')) : window.open('${safeUrl}', '_blank')" 
                                 title="Clic para ver en pantalla completa"
                                 style="width: 68px; height: 68px;">
                                <img src="${safeUrl}" alt="Adjunto" loading="lazy" style="width: 100%; height: 100%; object-fit: cover;">
                            </div>
                        `;
                    }).join('')}
                </div>
            </div>
        `;
    };

    // ==========================================
    // SISTEMA UNIVERSAL DE BLOQUEO DE SCROLL EN MODALES (Scroll-Lock UX)
    // ==========================================
    window.ModalScrollLock = (function () {
        let _openCount = 0;
        let _originalBodyPaddingRight = '';
        let _originalHtmlOverflow = '';
        let _originalBodyOverflow = '';
        let _isLocked = false;

        function lock() {
            _openCount++;
            if (_isLocked) return;

            // Calcular ancho de barra de scroll para evitar salto visual (layout shift)
            const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
            if (scrollbarWidth > 0) {
                _originalBodyPaddingRight = document.body.style.paddingRight || '';
                document.body.style.paddingRight = `${scrollbarWidth}px`;
            }

            _originalHtmlOverflow = document.documentElement.style.overflow || '';
            _originalBodyOverflow = document.body.style.overflow || '';

            document.documentElement.classList.add('modal-open');
            document.body.classList.add('modal-open');
            document.documentElement.style.overflow = 'hidden';
            document.body.style.overflow = 'hidden';

            _isLocked = true;
        }

        function unlock() {
            _openCount = Math.max(0, _openCount - 1);
            if (_openCount > 0) return; // Todavía hay modales abiertos (ej. confirmación sobre tarea)

            if (!_isLocked) return;

            document.documentElement.classList.remove('modal-open');
            document.body.classList.remove('modal-open');
            document.documentElement.style.overflow = _originalHtmlOverflow;
            document.body.style.overflow = _originalBodyOverflow;

            if (_originalBodyPaddingRight !== '') {
                document.body.style.paddingRight = _originalBodyPaddingRight;
                _originalBodyPaddingRight = '';
            } else {
                document.body.style.paddingRight = '';
            }

            _isLocked = false;
        }

        function reset() {
            _openCount = 0;
            if (!_isLocked) return;
            document.documentElement.classList.remove('modal-open');
            document.body.classList.remove('modal-open');
            document.documentElement.style.overflow = _originalHtmlOverflow;
            document.body.style.overflow = _originalBodyOverflow;
            if (_originalBodyPaddingRight !== '') {
                document.body.style.paddingRight = _originalBodyPaddingRight;
                _originalBodyPaddingRight = '';
            } else {
                document.body.style.paddingRight = '';
            }
            _isLocked = false;
        }

        function isAnyModalVisible() {
            const modalSelectors = [
                '.task-modal-overlay',
                '.ticket-detail-modal',
                '.modal',
                '.modal-overlay',
                '.ticket-modal',
                '#dayTasksModalDialog',
                '#taskModalDialog',
                '#taskDetailModalDialog',
                '#confirmActionModal',
                '#shareTasksModalDialog',
                '#ticketModal',
                '#userModal',
                '#resetPasswordModal',
                '#coreUniversalLightbox'
            ];
            const elements = document.querySelectorAll(modalSelectors.join(','));
            for (const el of elements) {
                if (el.id === 'coreUniversalLightbox') {
                    if (el.style && el.style.display === 'flex') return true;
                    continue;
                }
                if (el.style && (el.style.display === 'flex' || el.style.display === 'block' || el.style.display === 'grid')) {
                    return true;
                }
                if (el.classList.contains('active') || el.classList.contains('show')) {
                    return true;
                }
                // Comprobación de visibilidad efectiva
                if (el.offsetParent !== null) {
                    const style = window.getComputedStyle(el);
                    if (style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0' && el.offsetHeight > 0) {
                        return true;
                    }
                }
            }
            return false;
        }

        function sync() {
            if (isAnyModalVisible()) {
                if (!_isLocked) lock();
            } else {
                if (_isLocked) reset();
            }
        }

        // Inicializar observador automático de modales en el DOM
        if (typeof MutationObserver !== 'undefined') {
            let syncRaf = null;
            const observer = new MutationObserver((mutations) => {
                let needsSync = false;
                for (const m of mutations) {
                    if (m.target === document.body || m.target === document.documentElement) continue;
                    const target = m.target;
                    if (target && target.classList && (
                        target.classList.contains('task-modal-overlay') ||
                        target.classList.contains('ticket-detail-modal') ||
                        target.classList.contains('modal') ||
                        target.classList.contains('modal-overlay') ||
                        target.classList.contains('ticket-modal') ||
                        (target.id && (target.id.includes('Modal') || target.id.includes('Lightbox') || target.id.includes('Dialog')))
                    )) {
                        needsSync = true;
                        break;
                    }
                }
                if (needsSync) {
                    if (syncRaf) cancelAnimationFrame(syncRaf);
                    syncRaf = requestAnimationFrame(() => {
                        sync();
                    });
                }
            });

            const startObserver = () => {
                if (document.body) {
                    observer.observe(document.body, {
                        attributes: true,
                        attributeFilter: ['style', 'class'],
                        subtree: true
                    });
                    sync();
                } else {
                    document.addEventListener('DOMContentLoaded', startObserver);
                }
            };

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', startObserver);
            } else {
                startObserver();
            }
        }

        // Prevenir scroll wheel / touchmove directamente sobre los backdrops oscuros
        const preventBackdropScroll = (e) => {
            if (document.body && document.body.classList.contains('modal-open')) {
                const target = e.target;
                if (target && target.classList && (
                    target.classList.contains('task-modal-overlay') ||
                    target.classList.contains('ticket-detail-modal') ||
                    target.classList.contains('modal-overlay') ||
                    target.classList.contains('modal')
                )) {
                    e.preventDefault();
                }
            }
        };

        window.addEventListener('wheel', preventBackdropScroll, { passive: false });
        window.addEventListener('touchmove', preventBackdropScroll, { passive: false });

        return {
            lock,
            unlock,
            reset,
            sync,
            isLocked: () => _isLocked,
            getVisibleModals
        };
    })();

    // ==========================================
    // GESTIÓN DE ACCESIBILIDAD Y TECLADO EN MODALES (WCAG 2.1 AA)
    // ==========================================
    let _lastActiveElementBeforeModal = null;

    function getVisibleModals() {
        const modalSelectors = [
            '#coreUniversalLightbox',
            '.confirm-dialog-overlay',
            '#confirmActionModal',
            '#shareTasksModalDialog',
            '#shareReportModal',
            '#taskDetailModalDialog',
            '#taskModalDialog',
            '#dayTasksModalDialog',
            '#ticketModal',
            '#userModal',
            '#resetPasswordModal',
            '#loginModal',
            '#trackingModal',
            '.task-modal-overlay',
            '.ticket-detail-modal',
            '.modal-overlay',
            '.modal'
        ];
        const elements = document.querySelectorAll(modalSelectors.join(','));
        const visible = [];
        for (const el of elements) {
            if (el.id === 'coreUniversalLightbox') {
                if (el.style && el.style.display === 'flex') visible.push(el);
                continue;
            }
            if (el.style && (el.style.display === 'flex' || el.style.display === 'block' || el.style.display === 'grid')) {
                visible.push(el);
                continue;
            }
            if (el.classList.contains('active') || el.classList.contains('show')) {
                visible.push(el);
                continue;
            }
            if (el.offsetParent !== null) {
                const s = window.getComputedStyle(el);
                if (s.display !== 'none' && s.visibility !== 'hidden' && s.opacity !== '0' && el.offsetHeight > 0) {
                    visible.push(el);
                }
            }
        }
        return visible;
    }

    function trapFocusInModal(modal, event) {
        if (!modal) return;
        const focusableSelectors = [
            'a[href]',
            'button:not([disabled])',
            'textarea:not([disabled])',
            'input:not([disabled]):not([type="hidden"])',
            'select:not([disabled])',
            '[tabindex]:not([tabindex="-1"])'
        ];
        const focusables = Array.from(modal.querySelectorAll(focusableSelectors.join(',')))
            .filter(el => {
                return el.offsetParent !== null && !el.hasAttribute('disabled') && window.getComputedStyle(el).visibility !== 'hidden';
            });

        if (focusables.length === 0) return;

        const first = focusables[0];
        const last = focusables[focusables.length - 1];

        if (event.shiftKey) {
            if (document.activeElement === first || !modal.contains(document.activeElement)) {
                event.preventDefault();
                last.focus();
            }
        } else {
            if (document.activeElement === last || !modal.contains(document.activeElement)) {
                event.preventDefault();
                first.focus();
            }
        }
    }

    function closeTopmostModal() {
        if (window.activeConfirmDialog) {
            window.closeConfirmDialog();
            return true;
        }

        const lightbox = document.getElementById('coreUniversalLightbox');
        if (lightbox && lightbox.style.display === 'flex') {
            if (typeof window.closeLightbox === 'function') {
                window.closeLightbox();
                return true;
            }
        }

        const visibleModals = getVisibleModals();
        if (visibleModals.length === 0) return false;

        const topModal = visibleModals[visibleModals.length - 1];

        // 1. Intentar clic en botón de cierre explícito dentro del modal
        const closeBtn = topModal.querySelector('.close-modal, .modal-close, .btn-close, [data-modal-close], button[aria-label*="Cerrar" i]');
        if (closeBtn && typeof closeBtn.click === 'function') {
            closeBtn.click();
            return true;
        }

        // 2. Funciones globales asociadas al ID del modal
        const closeFnMap = {
            'ticketModal': 'closeTicketModal',
            'taskModalDialog': 'closeTaskModal',
            'dayTasksModalDialog': 'closeDayTasksModal',
            'taskDetailModalDialog': 'closeTaskDetailModal',
            'shareTasksModalDialog': 'closeShareTasksModal',
            'shareReportModal': 'closeShareModal',
            'userModal': 'closeUserModal',
            'resetPasswordModal': 'closeResetPasswordModal',
            'confirmActionModal': 'closeConfirmActionModal',
            'trackingModal': 'closeTrackingModal',
            'loginModal': 'hideLogin'
        };

        if (topModal.id && closeFnMap[topModal.id] && typeof window[closeFnMap[topModal.id]] === 'function') {
            window[closeFnMap[topModal.id]]();
            return true;
        }

        // 3. Fallback de cierre directo
        topModal.style.display = 'none';
        if (window.ModalScrollLock) window.ModalScrollLock.unlock();
        return true;
    }

    // Listener global de teclado para Escape y Focus Trap
    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (closeTopmostModal()) {
                e.preventDefault();
                e.stopPropagation();
            }
        } else if (e.key === 'Tab') {
            const visibleModals = getVisibleModals();
            if (visibleModals.length > 0) {
                const topModal = visibleModals[visibleModals.length - 1];
                trapFocusInModal(topModal, e);
            }
        }
    });

    // Guardar elemento activo antes de abrir modales para restaurarlo al cerrar
    document.addEventListener('focusin', () => {
        const visibleModals = getVisibleModals();
        if (visibleModals.length === 0 && document.activeElement && document.activeElement !== document.body) {
            _lastActiveElementBeforeModal = document.activeElement;
        }
    });

    // Exponer restaurador de foco
    window.restoreFocusAfterModal = function () {
        if (_lastActiveElementBeforeModal && typeof _lastActiveElementBeforeModal.focus === 'function') {
            try {
                _lastActiveElementBeforeModal.focus();
            } catch (e) { }
            _lastActiveElementBeforeModal = null;
        }
    };

    // ==========================================
    // SISTEMA UNIFICADO DE NOTIFICACIONES TOAST (A11Y)
    // ==========================================
    window.showNotification = function (message, type = 'info', duration = 3500) {
        if (!message) return;

        let container = document.getElementById('toastContainer');
        if (!container) {
            container = document.createElement('div');
            container.id = 'toastContainer';
            container.className = 'toast-container';
            document.body.appendChild(container);
        }

        const safeType = ['success', 'error', 'warning', 'info'].includes(type) ? type : 'info';
        const toast = document.createElement('div');
        toast.className = `toast toast-${safeType}`;
        toast.setAttribute('role', safeType === 'error' || safeType === 'warning' ? 'alert' : 'status');
        toast.setAttribute('aria-live', 'polite');

        const icons = {
            success: '✅',
            error: '❌',
            warning: '⚠️',
            info: 'ℹ️'
        };

        const iconSpan = document.createElement('span');
        iconSpan.style.marginRight = '6px';
        iconSpan.textContent = icons[safeType] || 'ℹ️';

        const contentDiv = document.createElement('div');
        contentDiv.className = 'toast-content';
        contentDiv.textContent = message;

        const closeBtn = document.createElement('button');
        closeBtn.type = 'button';
        closeBtn.className = 'toast-close-btn';
        closeBtn.setAttribute('aria-label', 'Cerrar notificación');
        closeBtn.innerHTML = '&times;';

        const dismissToast = () => {
            toast.style.opacity = '0';
            toast.style.transform = 'translateX(24px)';
            setTimeout(() => {
                if (toast.parentNode) toast.remove();
            }, 220);
        };

        closeBtn.onclick = dismissToast;

        toast.appendChild(iconSpan);
        toast.appendChild(contentDiv);
        toast.appendChild(closeBtn);

        // Limitar a máximo 4 toasts visibles simultáneos
        while (container.children.length >= 4) {
            container.removeChild(container.firstChild);
        }

        container.appendChild(toast);

        if (duration > 0) {
            setTimeout(dismissToast, duration);
        }
    };

    // Alias global para compatibilidad con código existente
    window.showToast = window.showNotification;

    // ==========================================
    // MODAL DE CONFIRMACIÓN UNIVERSAL ACCESIBLE
    // ==========================================
    window.activeConfirmDialog = null;

    window.closeConfirmDialog = function () {
        if (window.activeConfirmDialog && window.activeConfirmDialog.overlay) {
            const overlay = window.activeConfirmDialog.overlay;
            overlay.style.opacity = '0';
            setTimeout(() => {
                if (overlay.parentNode) overlay.parentNode.removeChild(overlay);
            }, 180);
            if (window.ModalScrollLock) window.ModalScrollLock.unlock();
            window.restoreFocusAfterModal();
        }
        window.activeConfirmDialog = null;
    };

    window.openConfirmDialog = function (options) {
        const opts = options || {};
        const title = opts.title || 'Confirmar acción';
        const message = opts.message || '¿Estás seguro de continuar?';
        const confirmLabel = opts.confirmLabel || 'Confirmar';
        const cancelLabel = opts.cancelLabel || 'Cancelar';
        const isDanger = opts.isDanger !== false;

        window.closeConfirmDialog();

        const overlay = document.createElement('div');
        overlay.className = 'confirm-dialog-overlay';

        const dialog = document.createElement('div');
        dialog.className = 'confirm-dialog';
        dialog.setAttribute('role', 'dialog');
        dialog.setAttribute('aria-modal', 'true');
        dialog.setAttribute('aria-labelledby', 'coreConfirmDialogTitle');
        dialog.setAttribute('aria-describedby', 'coreConfirmDialogMsg');

        const titleEl = document.createElement('div');
        titleEl.id = 'coreConfirmDialogTitle';
        titleEl.className = 'confirm-dialog-title';
        titleEl.innerHTML = `<span>${isDanger ? '⚠️' : 'ℹ️'}</span><span>${window.escapeHtml ? window.escapeHtml(title) : title}</span>`;

        const messageEl = document.createElement('div');
        messageEl.id = 'coreConfirmDialogMsg';
        messageEl.className = 'confirm-dialog-message';
        messageEl.textContent = message;

        const actions = document.createElement('div');
        actions.className = 'confirm-dialog-actions';

        const cancelBtn = document.createElement('button');
        cancelBtn.type = 'button';
        cancelBtn.className = 'btn btn-outline';
        cancelBtn.style.cssText = 'padding: 8px 16px; border-radius: 6px; cursor: pointer;';
        cancelBtn.textContent = cancelLabel;

        const confirmBtn = document.createElement('button');
        confirmBtn.type = 'button';
        confirmBtn.className = isDanger ? 'btn btn-danger' : 'btn btn-primary';
        confirmBtn.style.cssText = 'padding: 8px 16px; border-radius: 6px; cursor: pointer;';
        confirmBtn.textContent = confirmLabel;

        actions.appendChild(cancelBtn);
        actions.appendChild(confirmBtn);

        dialog.appendChild(titleEl);
        dialog.appendChild(messageEl);
        dialog.appendChild(actions);
        overlay.appendChild(dialog);

        const onConfirm = () => {
            window.closeConfirmDialog();
            if (typeof opts.onConfirm === 'function') {
                opts.onConfirm();
            }
        };

        const onCancel = () => {
            window.closeConfirmDialog();
            if (typeof opts.onCancel === 'function') {
                opts.onCancel();
            }
        };

        cancelBtn.addEventListener('click', onCancel);
        confirmBtn.addEventListener('click', onConfirm);

        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) onCancel();
        });

        document.body.appendChild(overlay);
        if (window.ModalScrollLock) window.ModalScrollLock.lock();

        window.activeConfirmDialog = { overlay, onConfirm, onCancel };

        setTimeout(() => {
            (cancelBtn || confirmBtn).focus();
        }, 50);
    };

    window.showConfirmDialog = function (options) {
        return new Promise((resolve) => {
            window.openConfirmDialog({
                ...options,
                onConfirm: () => {
                    if (options && typeof options.onConfirm === 'function') options.onConfirm();
                    resolve(true);
                },
                onCancel: () => {
                    if (options && typeof options.onCancel === 'function') options.onCancel();
                    resolve(false);
                }
            });
        });
    };

    // ==========================================
    // 16. UNIFICACIÓN DE SELECTOR DE USUARIO EN NAVBAR (Fase 3)
    // ==========================================
    /**
     * Actualiza el nombre del usuario en cualquier variante de cabecera (#userName, #currentUserName, #headerUserName)
     * evitando sobreescribir campos <input id="userName"> en modales de gestión de usuarios.
     * @param {string} name
     */
    window.updateNavbarUserName = function (name) {
        if (!name) return;
        const selectors = [
            '#currentUserName',
            '#headerUserName',
            '.navbar #userName',
            '.user-info #userName',
            'span#userName',
            '[data-user-display]'
        ];
        selectors.forEach(sel => {
            document.querySelectorAll(sel).forEach(el => {
                if (el && el.tagName !== 'INPUT' && el.tagName !== 'TEXTAREA' && el.tagName !== 'SELECT') {
                    el.textContent = name;
                }
            });
        });
    };

    // ==========================================
    // 17. SISTEMA UNIVERSAL DE SKELETON LOADERS (Fase 2)
    // ==========================================
    /**
     * Genera una grilla de tarjetas skeleton para estados de carga de tickets.
     * @param {number} [count=6]
     * @returns {string}
     */
    window.renderSkeletonTicketGrid = function (count = 6) {
        const cards = Array.from({ length: count }).map(() => `
            <div class="skeleton-card" aria-hidden="true">
                <div>
                    <div class="skeleton skeleton-title"></div>
                    <div style="display: flex; gap: 6px; margin-bottom: 10px;">
                        <span class="skeleton skeleton-badge"></span>
                        <span class="skeleton skeleton-badge" style="width: 58px;"></span>
                    </div>
                    <div class="skeleton skeleton-line"></div>
                    <div class="skeleton skeleton-line medium"></div>
                </div>
                <div style="padding-top: 8px; border-top: 1px solid var(--color-border-subtle, #f1f5f9);">
                    <div class="skeleton skeleton-line short"></div>
                    <div class="skeleton skeleton-line medium" style="margin-bottom: 0;"></div>
                </div>
            </div>
        `).join('');

        return `
            <div class="tickets-grid-3x5" role="status" aria-busy="true" aria-label="Cargando tickets...">
                <span class="visually-hidden">Cargando tickets...</span>
                ${cards}
            </div>
        `;
    };

    /**
     * Genera filas skeleton para tablas de datos (usuarios, reportes, enlaces compartidos).
     * @param {number} [cols=6]
     * @param {number} [rows=4]
     * @returns {string}
     */
    window.renderSkeletonTableRows = function (cols = 6, rows = 4) {
        return Array.from({ length: rows }).map(() => {
            const cells = Array.from({ length: cols }).map((_, i) => `
                <td>
                    <div class="skeleton skeleton-line ${i === 0 ? 'medium' : (i === cols - 1 ? 'short' : '')}" style="margin-bottom: 0;"></div>
                </td>
            `).join('');
            return `<tr aria-hidden="true">${cells}</tr>`;
        }).join('');
    };

    /**
     * Genera bloques skeleton para detalles o historial dentro de un modal.
     * @returns {string}
     */
    window.renderSkeletonDetails = function () {
        return `
            <div role="status" aria-busy="true" aria-label="Cargando detalles..." style="padding: 12px 0;">
                <span class="visually-hidden">Cargando detalles...</span>
                <div class="skeleton skeleton-title" style="width: 55%; margin-bottom: 14px;"></div>
                <div class="skeleton skeleton-line"></div>
                <div class="skeleton skeleton-line medium"></div>
                <div class="skeleton skeleton-line short" style="margin-bottom: 16px;"></div>
                <div class="skeleton skeleton-line"></div>
                <div class="skeleton skeleton-line medium"></div>
            </div>
        `;
    };

    // ==========================================
    // 18. SINCRONIZADOR AUTOMÁTICO DE TABLAS RESPONSIVAS (Fase 4)
    // ==========================================
    /**
     * Sincroniza automáticamente los encabezados <th> de cualquier tabla hacia el atributo data-label
     * de cada celda <td> para que en pantallas móviles (<768px) se rendericen como tarjetas clave-valor.
     * @param {ParentNode} [root=document]
     */
    window.syncResponsiveTables = function (root = document) {
        if (!root || typeof root.querySelectorAll !== 'function') return;
        const tables = root.querySelectorAll('table');
        tables.forEach(table => {
            if (!table.classList.contains('responsive-table')) {
                table.classList.add('responsive-table');
            }
            const headers = Array.from(table.querySelectorAll('thead th')).map(th => (th.textContent || '').trim());
            if (headers.length === 0) return;

            const rows = table.querySelectorAll('tbody tr');
            rows.forEach(tr => {
                const cells = tr.querySelectorAll('td');
                cells.forEach((td, idx) => {
                    if (td.hasAttribute('colspan')) return;
                    if (!td.getAttribute('data-label') && headers[idx]) {
                        td.setAttribute('data-label', headers[idx]);
                    }
                });
            });
        });
    };

    let _tableSyncScheduled = false;
    function scheduleTableSync() {
        if (_tableSyncScheduled) return;
        _tableSyncScheduled = true;
        requestAnimationFrame(() => {
            _tableSyncScheduled = false;
            window.syncResponsiveTables(document);
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            window.syncResponsiveTables(document);
            if (window.MutationObserver && document.body) {
                const observer = new MutationObserver((mutations) => {
                    for (const m of mutations) {
                        if (m.type === 'childList' && m.addedNodes.length > 0) {
                            scheduleTableSync();
                            break;
                        }
                    }
                });
                observer.observe(document.body, { childList: true, subtree: true });
            }
        });
    } else {
        window.syncResponsiveTables(document);
        if (window.MutationObserver && document.body) {
            const observer = new MutationObserver((mutations) => {
                for (const m of mutations) {
                    if (m.type === 'childList' && m.addedNodes.length > 0) {
                        scheduleTableSync();
                        break;
                    }
                }
            });
            observer.observe(document.body, { childList: true, subtree: true });
        }
    }
})();

// ==========================================
// 19. GESTOR GLOBAL DE MODO OSCURO (ThemeManager)
// ==========================================
(function () {
    const STORAGE_KEY = 'ticket_theme';

    function getStoredTheme() {
        try {
            const saved = localStorage.getItem(STORAGE_KEY);
            if (saved === 'dark' || saved === 'light') return saved;
        } catch (_) {}
        return null;
    }

    function getPreferredTheme() {
        const stored = getStoredTheme();
        if (stored) return stored;
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            return 'dark';
        }
        return 'light';
    }

    function syncChartColors(isDark) {
        if (!window.Chart || !window.Chart.instances) return;
        const textColor = isDark ? '#cbd5e1' : '#4b5563';
        const gridColor = isDark ? 'rgba(148, 163, 184, 0.14)' : 'rgba(0, 0, 0, 0.06)';
        try {
            Object.values(window.Chart.instances).forEach(chart => {
                if (!chart || !chart.options) return;
                if (chart.options.scales) {
                    Object.values(chart.options.scales).forEach(scale => {
                        if (scale.ticks) scale.ticks.color = textColor;
                        if (scale.grid) scale.grid.color = gridColor;
                    });
                }
                if (chart.options.plugins && chart.options.plugins.legend && chart.options.plugins.legend.labels) {
                    chart.options.plugins.legend.labels.color = textColor;
                }
                chart.update('none');
            });
        } catch (_) {}
    }

    function updateToggleButtons(theme) {
        const isDark = theme === 'dark';
        const label = isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro';
        const icon = isDark ? '☀️' : '🌙';
        document.querySelectorAll('.theme-toggle-btn').forEach(btn => {
            btn.innerHTML = `<span aria-hidden="true">${icon}</span>`;
            btn.setAttribute('aria-label', label);
            btn.setAttribute('title', label);
            btn.setAttribute('aria-pressed', isDark ? 'true' : 'false');
        });
    }

    function applyTheme(theme, persist = false) {
        const normalized = theme === 'dark' ? 'dark' : 'light';
        document.documentElement.setAttribute('data-theme', normalized);
        if (document.body) {
            document.body.classList.toggle('dark-mode', normalized === 'dark');
        }
        if (persist) {
            try {
                localStorage.setItem(STORAGE_KEY, normalized);
            } catch (_) {}
        }
        updateToggleButtons(normalized);
        syncChartColors(normalized === 'dark');
        window.dispatchEvent(new CustomEvent('themechange', { detail: { theme: normalized } }));
    }

    function mountToggleButton() {
        if (document.querySelector('.theme-toggle-btn')) {
            updateToggleButtons(getPreferredTheme());
            return;
        }

        const btn = document.createElement('button');
        btn.type = 'button';
        btn.id = 'themeToggleBtn';
        btn.className = 'theme-toggle-btn';
        btn.addEventListener('click', () => window.ThemeManager.toggle());

        const userInfo = document.querySelector('.navbar .user-info');
        const navbarActions = document.querySelector('.navbar .navbar-actions');
        const publicNavActions = document.querySelector('.public-navbar .nav-actions');
        const headerActions = document.querySelector('.header .header-actions');
        const trackingActions = document.querySelector('.tracking-header .tracking-actions');

        if (userInfo) {
            const anchor = userInfo.querySelector('.notification-wrapper') || userInfo.querySelector('.logout-btn');
            if (anchor) {
                userInfo.insertBefore(btn, anchor);
            } else {
                userInfo.appendChild(btn);
            }
        } else if (navbarActions) {
            navbarActions.insertBefore(btn, navbarActions.firstChild);
        } else if (publicNavActions) {
            publicNavActions.insertBefore(btn, publicNavActions.firstChild);
        } else if (headerActions) {
            headerActions.appendChild(btn);
        } else if (trackingActions) {
            trackingActions.appendChild(btn);
        }

        updateToggleButtons(document.documentElement.getAttribute('data-theme') || getPreferredTheme());
    }

    function getToggleOrigin(triggerEvent) {
        if (triggerEvent && typeof triggerEvent.clientX === 'number' && (triggerEvent.clientX > 0 || triggerEvent.clientY > 0)) {
            return { x: triggerEvent.clientX, y: triggerEvent.clientY };
        }
        const btn = document.querySelector('.theme-toggle-btn');
        if (btn && typeof btn.getBoundingClientRect === 'function') {
            const rect = btn.getBoundingClientRect();
            if (rect.width > 0 && rect.height > 0) {
                return {
                    x: Math.round(rect.left + rect.width / 2),
                    y: Math.round(rect.top + rect.height / 2)
                };
            }
        }
        return {
            x: Math.round(window.innerWidth - 48),
            y: 36
        };
    }

    function animateToggleButtons() {
        document.querySelectorAll('.theme-toggle-btn').forEach(btn => {
            btn.classList.remove('is-toggling');
            void btn.offsetWidth;
            btn.classList.add('is-toggling');
            setTimeout(() => btn.classList.remove('is-toggling'), 550);
        });
    }

    function transitionThemeChange(nextTheme, triggerEvent) {
        const prefersReducedMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        if (!prefersReducedMotion && typeof document.startViewTransition === 'function') {
            const { x, y } = getToggleOrigin(triggerEvent);
            const endRadius = Math.ceil(Math.hypot(
                Math.max(x, window.innerWidth - x),
                Math.max(y, window.innerHeight - y)
            ));

            try {
                const root = document.documentElement;
                root.style.setProperty('--vt-x', `${x}px`);
                root.style.setProperty('--vt-y', `${y}px`);
                root.style.setProperty('--vt-r', `${endRadius}px`);

                document.startViewTransition(() => {
                    applyTheme(nextTheme, true);
                });

                animateToggleButtons();
                return;
            } catch (_) {}
        }

        // Fallback con transición CSS suave si el navegador no soporta View Transitions API
        if (!prefersReducedMotion) {
            document.documentElement.classList.add('theme-transitioning');
            setTimeout(() => {
                document.documentElement.classList.remove('theme-transitioning');
            }, 460);
        }
        applyTheme(nextTheme, true);
        animateToggleButtons();
    }

    window.ThemeManager = {
        getTheme() {
            return document.documentElement.getAttribute('data-theme') || getPreferredTheme();
        },
        setTheme(theme) {
            applyTheme(theme, true);
        },
        toggle(triggerEvent) {
            const next = this.getTheme() === 'dark' ? 'light' : 'dark';
            transitionThemeChange(next, triggerEvent);
            return next;
        },
        mount: mountToggleButton
    };

    window.toggleDarkMode = function (triggerEvent) {
        return window.ThemeManager.toggle(triggerEvent);
    };

    // Aplicar de inmediato antes del primer renderizado para evitar parpadeos (FOUC)
    applyTheme(getPreferredTheme(), false);

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            applyTheme(getPreferredTheme(), false);
            mountToggleButton();
        });
    } else {
        applyTheme(getPreferredTheme(), false);
        mountToggleButton();
    }

    // Escuchar cambios del sistema operativo si el usuario no fijó preferencia manual
    if (window.matchMedia) {
        try {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
                if (!getStoredTheme()) {
                    applyTheme(e.matches ? 'dark' : 'light', false);
                }
            });
        } catch (_) {}
    }
})();






// ==========================================================================
// 20. CONTRATO SDD v2.0 — ACCESIBILIDAD WCAG 2.2 AA, ESTADOS Y COMPONENTES
// ==========================================================================
(function () {
    /**
     * Etiqueta visual semántica unificada para prioridades (incluyendo Urgente vs Alta).
     * @param {string} priority
     * @returns {string}
     */
    window.formatPriorityLabel = function (priority) {
        switch ((priority || 'medium').toLowerCase()) {
            case 'urgent': return '🔴 Urgente';
            case 'high': return '🟠 Alta';
            case 'medium': return '🟡 Media';
            case 'low': return '🟢 Baja';
            default: return '🟡 Media';
        }
    };

    /**
     * Manejador de teclado accesible (Enter / Space) para abrir el detalle de un ticket.
     * @param {KeyboardEvent} event
     * @param {number|string} ticketId
     */
    window.handleCardTriggerKeydown = function (event, ticketId) {
        if (!event) return;
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.stopPropagation();
            if (typeof showTicketDetails === 'function') {
                showTicketDetails(ticketId);
            } else if (typeof window.showTicketDetails === 'function') {
                window.showTicketDetails(ticketId);
            }
        }
    };

    /**
     * Anunciador global aria-live="polite" para cambios dinámicos de filtros y paginación.
     * @param {string} message
     */
    window.announceA11yStatus = function (message) {
        if (!message || !document.body) return;
        let announcer = document.getElementById('a11yStatusAnnouncer');
        if (!announcer) {
            announcer = document.createElement('div');
            announcer.id = 'a11yStatusAnnouncer';
            announcer.className = 'visually-hidden';
            announcer.setAttribute('aria-live', 'polite');
            announcer.setAttribute('aria-atomic', 'true');
            document.body.appendChild(announcer);
        }
        announcer.textContent = '';
        requestAnimationFrame(() => {
            announcer.textContent = message;
        });
    };

    /**
     * Detecta si existen filtros activos de búsqueda, prioridad, sede o fechas en la vista actual.
     * @returns {boolean}
     */
    window.hasActiveTicketFilters = function () {
        const ids = ['searchInput', 'priorityFilter', 'startDateFilter', 'endDateFilter', 'sedeFilter', 'departmentFilter'];
        return ids.some(id => {
            const el = document.getElementById(id);
            return el && typeof el.value === 'string' && el.value.trim() !== '' && el.value !== 'all';
        });
    };

    /**
     * Restablece todos los filtros activos de tickets y refresca la vista (CTA Empty State).
     */
    window.resetAllTicketFilters = function () {
        const ids = ['searchInput', 'priorityFilter', 'startDateFilter', 'endDateFilter', 'sedeFilter', 'departmentFilter'];
        ids.forEach(id => {
            const el = document.getElementById(id);
            if (!el) return;
            if (el.tagName === 'SELECT') {
                const hasEmpty = Array.from(el.options).some(o => o.value === '');
                el.value = hasEmpty ? '' : el.options[0]?.value || '';
            } else {
                el.value = '';
                el.removeAttribute('min');
            }
        });
        if (typeof applyFilters === 'function') {
            applyFilters();
        } else if (typeof window.applyFilters === 'function') {
            window.applyFilters();
        }
        window.announceA11yStatus('Filtros restablecidos. Mostrando todos los tickets.');
    };

    /**
     * Genera tarjetas skeleton para la fila de KPIs (#statsGrid) evitando Layout Shift (CLS).
     * @param {number} [count=4]
     * @returns {string}
     */
    window.renderSkeletonStats = function (count = 4) {
        return Array.from({ length: count }).map(() => `
            <div class="skeleton-stat-card" aria-hidden="true">
                <div class="skeleton skeleton-title" style="width: 45%; height: 28px; margin-bottom: 4px;"></div>
                <div class="skeleton skeleton-line short" style="width: 68%; height: 14px; margin-bottom: 0;"></div>
            </div>
        `).join('');
    };

    /**
     * Validador de formularios accesible (WCAG 3.3.1 / 3.3.2).
     */
    window.A11yFormValidator = {
        setFieldError(inputEl, errorEl, message) {
            if (!inputEl) return;
            inputEl.classList.add('invalid');
            inputEl.classList.remove('valid');
            inputEl.setAttribute('aria-invalid', 'true');
            if (errorEl) {
                if (errorEl.id) {
                    inputEl.setAttribute('aria-describedby', errorEl.id);
                }
                if (message) errorEl.textContent = message;
                errorEl.setAttribute('role', 'alert');
                errorEl.classList.add('show');
            }
        },
        clearFieldError(inputEl, errorEl, markValid = true) {
            if (!inputEl) return;
            inputEl.classList.remove('invalid');
            if (markValid && inputEl.value && inputEl.value.trim()) {
                inputEl.classList.add('valid');
            }
            inputEl.setAttribute('aria-invalid', 'false');
            if (errorEl) {
                errorEl.classList.remove('show');
            }
        }
    };

    // Sobrescribir constructores de tarjetas con soporte para prioridad 'urgent' y WCAG 4.1.2
    window.buildVerticalTicketCard = function (ticket) {
        const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;
        const priority = (ticket.priority || 'medium').toLowerCase();
        const priorityPill = window.formatPriorityLabel(priority);
        const statusText = window.getStatusText ? window.getStatusText(ticket.status) : ticket.status;
        const isNew = (ticket.status === 'open' && window.isNewTicket) ? window.isNewTicket(ticket.created_at) : false;
        const relativeTime = window.formatRelativeTime ? window.formatRelativeTime(ticket.created_at) : '';
        const formattedDate = window.formatDate ? window.formatDate(ticket.created_at) : '';

        return `
        <div class="ticket-item ticket-card-vertical priority-${priority}"
             onclick="showTicketDetails(${ticket.id})"
             onkeydown="window.handleCardTriggerKeydown(event, ${ticket.id})"
             tabindex="0"
             role="button"
             aria-label="Ver detalles del ticket ${window.escapeHtml(trackingId)}: ${window.escapeHtml(ticket.title)} (${statusText}, prioridad ${window.getPriorityText(priority)})">
            <div class="ticket-header">
                <div class="ticket-title">${window.escapeHtml(ticket.title)}</div>
                <div class="ticket-meta">
                    <span class="ticket-status status-${ticket.status}">${statusText}</span>
                    <span class="ticket-priority-pill priority-pill-${priority}">${priorityPill}</span>
                    ${isNew ? '<span class="badge-new">✨ NUEVO</span>' : ''}
                    <span class="ticket-tracking-chip">🔍 ${window.escapeHtml(trackingId)}</span>
                    <span class="ticket-meta-time">${relativeTime}</span>
                </div>
            </div>
            ${ticket.description ? `<div class="ticket-description">${window.escapeHtml(ticket.description).substring(0, 140)}${ticket.description.length > 140 ? '...' : ''}</div>` : ''}
            <div class="ticket-info">
                <div><strong>📍 Sede:</strong> ${window.escapeHtml(ticket.sede || 'No especificada')}</div>
                <div><strong>📁 Depto:</strong> ${window.escapeHtml(ticket.department || 'General')}</div>
                <div><strong>👤 Solicitante:</strong> ${window.escapeHtml(ticket.created_by_name || 'Desconocido')}</div>
                <div><strong>🛠️ Asignado:</strong> ${ticket.assigned_technician ? `<span class="assigned-tech-badge">👤 ${window.escapeHtml(ticket.assigned_technician)}</span>` : window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
                <div><strong>📅 Fecha:</strong> ${formattedDate}</div>
            </div>
        </div>
        `;
    };

    window.buildKanbanCard = function (ticket, isReadOnly = false) {
        const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;
        const priority = (ticket.priority || 'medium').toLowerCase();
        const statusText = window.getStatusText ? window.getStatusText(ticket.status) : ticket.status;
        const priorityPill = window.formatPriorityLabel(priority);
        const isNew = (ticket.status === 'open' && window.isNewTicket) ? window.isNewTicket(ticket.created_at) : false;
        const timeAgo = window.formatRelativeTime ? window.formatRelativeTime(ticket.created_at) : '';

        return `
        <div class='ticket-item kanban-card priority-${priority}'
             onclick='showTicketDetails(${ticket.id})'
             draggable='${!isReadOnly}'
             data-ticket-id='${ticket.id}'
             data-status='${ticket.status}'
             tabindex="0"
             role="button"
             aria-label="Ticket ${window.escapeHtml(trackingId)} - ${statusText} - Prioridad ${window.getPriorityText(priority)}"
             onkeydown='if(typeof handleTicketKeydown === "function") handleTicketKeydown(event, ${ticket.id}, "${ticket.status}"); else window.handleCardTriggerKeydown(event, ${ticket.id});'
             oncontextmenu='${isReadOnly ? "event.preventDefault();" : `openTicketContextMenu(event, ${ticket.id}, "${ticket.status}")`}'
             ondragstart='${isReadOnly ? "event.preventDefault();" : "handleKanbanDragStart(event)"}'
             ondragend='handleKanbanDragEnd(event)'>
            <div class="ticket-header">
                <div class="ticket-title">${window.escapeHtml(ticket.title)}</div>
                <div class="ticket-meta">
                    <span class="ticket-status status-${ticket.status}">${statusText}</span>
                    <span class="ticket-priority-pill priority-pill-${priority}">${priorityPill}</span>
                    ${isNew ? '<span class="badge-new">✨ NUEVO</span>' : ''}
                    <span class="ticket-tracking-chip">🔍 ${window.escapeHtml(trackingId)}</span>
                    <span class="ticket-meta-time">${timeAgo}</span>
                </div>
            </div>
            ${ticket.description ? `<div class="ticket-description">${window.escapeHtml(ticket.description).substring(0, 95)}${ticket.description.length > 95 ? '...' : ''}</div>` : ''}
            <div class="ticket-info">
                <div><strong>📍 Sede:</strong> ${window.escapeHtml(ticket.sede || 'No especificada')}</div>
                <div><strong>📁 Depto:</strong> ${window.escapeHtml(ticket.department || 'General')}</div>
                <div><strong>👤 Solicitante:</strong> ${window.escapeHtml(ticket.created_by_name || 'Desconocido')}</div>
                <div><strong>🛠️ Asignado:</strong> ${ticket.assigned_technician ? `<span class="assigned-tech-badge">👤 ${window.escapeHtml(ticket.assigned_technician)}</span>` : window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
            </div>
        </div>
        `;
    };

    window.buildGridTicketCard = function (ticket, isReadOnly = false) {
        const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;
        const status = ticket.status || 'open';
        const priority = (ticket.priority || 'medium').toLowerCase();
        const statusText = window.getStatusText ? window.getStatusText(status) : status;
        const priorityPill = window.formatPriorityLabel(priority);
        const isNew = (ticket.status === 'open' && window.isNewTicket) ? window.isNewTicket(ticket.created_at) : false;
        const timeAgo = window.formatRelativeTime ? window.formatRelativeTime(ticket.created_at) : '';

        let quickButtons = '';
        if (!isReadOnly) {
            if (status === 'open') {
                quickButtons = `
                    <button type="button" class="btn-quick-action action-in-progress" title="Mover ticket ${window.escapeHtml(trackingId)} a En Progreso" aria-label="Mover ticket ${window.escapeHtml(trackingId)} a En Progreso" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'in-progress');">
                        🔵 En Progreso
                    </button>
                    <button type="button" class="btn-quick-action action-closed" title="Cerrar ticket ${window.escapeHtml(trackingId)}" aria-label="Cerrar ticket ${window.escapeHtml(trackingId)}" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'closed');">
                        🟢 Cerrar
                    </button>
                `;
            } else if (status === 'in-progress') {
                quickButtons = `
                    <button type="button" class="btn-quick-action action-open" title="Mover ticket ${window.escapeHtml(trackingId)} a Pendiente" aria-label="Mover ticket ${window.escapeHtml(trackingId)} a Pendiente" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'open');">
                        🟡 Pendiente
                    </button>
                    <button type="button" class="btn-quick-action action-closed" title="Cerrar ticket ${window.escapeHtml(trackingId)}" aria-label="Cerrar ticket ${window.escapeHtml(trackingId)}" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'closed');">
                        🟢 Cerrar
                    </button>
                `;
            } else if (status === 'closed') {
                quickButtons = `
                    <button type="button" class="btn-quick-action action-open" title="Reabrir ticket ${window.escapeHtml(trackingId)}" aria-label="Reabrir ticket ${window.escapeHtml(trackingId)}" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'open');">
                        🟡 Reabrir
                    </button>
                    <button type="button" class="btn-quick-action action-in-progress" title="Mover ticket ${window.escapeHtml(trackingId)} a En Progreso" aria-label="Mover ticket ${window.escapeHtml(trackingId)} a En Progreso" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'in-progress');">
                        🔵 En Progreso
                    </button>
                `;
            }
        }

        // Uso de <article> con .ticket-card-trigger hermano de .ticket-quick-actions (cumple WCAG 4.1.2)
        return `
        <article class="ticket-item ticket-grid-card priority-${priority}"
                 onclick="showTicketDetails(${ticket.id})">
            <div class="ticket-card-trigger"
                 tabindex="0"
                 role="button"
                 aria-label="Ver detalles del ticket ${window.escapeHtml(trackingId)}: ${window.escapeHtml(ticket.title)} (${statusText}, prioridad ${window.getPriorityText(priority)})"
                 onkeydown="window.handleCardTriggerKeydown(event, ${ticket.id})">
                <div class="ticket-header">
                    <div class="ticket-title" title="${window.escapeHtml(ticket.title)}">${window.escapeHtml(ticket.title)}</div>
                </div>
                <div class="ticket-meta">
                    <span class="ticket-status status-${ticket.status}">${statusText}</span>
                    <span class="ticket-priority-pill priority-pill-${priority}">${priorityPill}</span>
                    ${isNew ? '<span class="badge-new">✨ NUEVO</span>' : ''}
                    <span class="ticket-tracking-chip">🔍 ${window.escapeHtml(trackingId)}</span>
                    <span class="ticket-meta-time">${timeAgo}</span>
                </div>
                ${ticket.description ? `<div class="ticket-description" title="${window.escapeHtml(ticket.description)}">${window.escapeHtml(ticket.description)}</div>` : ''}
            </div>

            <div>
                <div class="ticket-info">
                    <div><strong>📍 Sede:</strong> ${window.escapeHtml(ticket.sede || 'Ciudad')}</div>
                    <div><strong>📁 Depto:</strong> ${window.escapeHtml(ticket.department || 'General')}</div>
                    <div title="${window.escapeHtml(ticket.created_by_name || 'Desconocido')}"><strong>👤 Solicitante:</strong> ${window.escapeHtml(ticket.created_by_name || 'Desconocido')}</div>
                    <div title="${window.escapeHtml(ticket.assigned_technician ? `${ticket.assigned_technician} (${ticket.assigned_to_name || ''})` : (ticket.assigned_to_name || 'Sin asignar'))}"><strong>🛠️ Asignado:</strong> ${ticket.assigned_technician ? `<span class="assigned-tech-badge">👤 ${window.escapeHtml(ticket.assigned_technician)}</span>` : window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
                </div>

                ${quickButtons ? `<div class="ticket-quick-actions">${quickButtons}</div>` : ''}
            </div>
        </article>
        `;
    };

    window.renderTabbedTicketView = function (containerId, filteredTickets, activeTab, tabPages, onTabChangeFnName = 'switchTicketTab', onPageChangeFnName = 'changeTabPage', isReadOnly = false) {
        const container = document.getElementById(containerId);
        if (!container) return;

        const allTicketsList = Array.isArray(filteredTickets) ? filteredTickets : [];

        const openCount = allTicketsList.filter(t => t.status === 'open').length;
        const inProgressCount = allTicketsList.filter(t => t.status === 'in-progress').length;
        const closedCount = allTicketsList.filter(t => t.status === 'closed').length;

        const currentTab = activeTab || 'open';
        const tabTickets = allTicketsList.filter(t => t.status === currentTab);

        const itemsPerPage = window.ITEMS_PER_GRID_PAGE || 15;
        const totalItems = tabTickets.length;
        const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;

        let currentPage = tabPages && tabPages[currentTab] ? tabPages[currentTab] : 1;
        if (currentPage > totalPages) currentPage = totalPages;
        if (currentPage < 1) currentPage = 1;
        if (tabPages) tabPages[currentTab] = currentPage;

        const startIdx = (currentPage - 1) * itemsPerPage;
        const endIdx = startIdx + itemsPerPage;
        const pageTickets = tabTickets.slice(startIdx, endIdx);

        const tabsHtml = `
            <div class="ticket-tabs-container" role="tablist" aria-label="Filtrar tickets por estado">
                <button type="button" role="tab" aria-selected="${currentTab === 'open'}" class="ticket-tab ${currentTab === 'open' ? 'active' : ''}" data-status="open" onclick="${onTabChangeFnName}('open')">
                    <span aria-hidden="true">🟡</span>
                    <span>Pendientes</span>
                    <span class="tab-badge">${openCount}</span>
                </button>
                <button type="button" role="tab" aria-selected="${currentTab === 'in-progress'}" class="ticket-tab ${currentTab === 'in-progress' ? 'active' : ''}" data-status="in-progress" onclick="${onTabChangeFnName}('in-progress')">
                    <span aria-hidden="true">🔵</span>
                    <span>En Progreso</span>
                    <span class="tab-badge">${inProgressCount}</span>
                </button>
                <button type="button" role="tab" aria-selected="${currentTab === 'closed'}" class="ticket-tab ${currentTab === 'closed' ? 'active' : ''}" data-status="closed" onclick="${onTabChangeFnName}('closed')">
                    <span aria-hidden="true">🟢</span>
                    <span>Cerrados</span>
                    <span class="tab-badge">${closedCount}</span>
                </button>
            </div>
        `;

        const tabLabel = currentTab === 'open' ? 'pendientes' : (currentTab === 'in-progress' ? 'en progreso' : 'cerrados');
        let contentHtml = '';
        if (pageTickets.length === 0) {
            const hasFilters = window.hasActiveTicketFilters();
            contentHtml = `
                <div class="empty-state-box" role="status">
                    <div class="empty-icon" aria-hidden="true">${hasFilters ? '🔍' : '📭'}</div>
                    <h3>No hay tickets ${tabLabel}</h3>
                    <p>${hasFilters ? 'No se encontraron tickets que coincidan con los filtros o búsqueda aplicados.' : 'Actualmente no existen tickets registrados en este estado.'}</p>
                    ${hasFilters ? `<button type="button" class="btn btn-outline btn-sm empty-state-cta" onclick="window.resetAllTicketFilters()">🔄 Limpiar filtros activos</button>` : ''}
                </div>
            `;
        } else {
            contentHtml = `
                <div class="tickets-grid-3x5">
                    ${pageTickets.map(t => window.buildGridTicketCard(t, isReadOnly)).join('')}
                </div>
            `;
        }

        container.innerHTML = tabsHtml + contentHtml;

        const pagContainer = document.getElementById('paginationContainer');
        if (pagContainer) {
            if (totalItems > 0) {
                window.renderUniversalPagination('paginationContainer', currentPage, totalItems, itemsPerPage, onPageChangeFnName);
            } else {
                pagContainer.style.display = 'none';
            }
        }

        window.announceA11yStatus(`Mostrando ${pageTickets.length} de ${totalItems} tickets ${tabLabel}. Página ${currentPage} de ${totalPages}.`);
    };

    // Navegación por flechas (ArrowLeft / ArrowRight) para cualquier contenedor role="tablist"
    document.addEventListener('keydown', (e) => {
        if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
        const target = e.target;
        if (!target || target.getAttribute('role') !== 'tab') return;
        const tablist = target.closest('[role="tablist"]');
        if (!tablist) return;

        const tabs = Array.from(tablist.querySelectorAll('[role="tab"]:not([disabled])'));
        if (tabs.length <= 1) return;

        const idx = tabs.indexOf(target);
        if (idx === -1) return;

        e.preventDefault();
        const nextIdx = e.key === 'ArrowRight'
            ? (idx + 1) % tabs.length
            : (idx - 1 + tabs.length) % tabs.length;

        const nextTab = tabs[nextIdx];
        if (nextTab) {
            nextTab.focus();
            nextTab.click();
        }
    });

    // Inicializar Skeletons automáticamente en #statsGrid y #ticketsList si están vacíos al arrancar
    function mountInitialSkeletons() {
        const statsGrid = document.getElementById('statsGrid');
        if (statsGrid && statsGrid.children.length === 0) {
            statsGrid.innerHTML = window.renderSkeletonStats(4);
        }
        const ticketsList = document.getElementById('ticketsList');
        if (ticketsList && ticketsList.children.length === 0) {
            ticketsList.innerHTML = window.renderSkeletonTicketGrid(6);
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', mountInitialSkeletons);
    } else {
        mountInitialSkeletons();
    }
})();
