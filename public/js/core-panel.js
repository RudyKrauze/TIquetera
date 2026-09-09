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
    return `<span class="badge badge-${safeStatus}">${window.escapeHtml(text)}</span>`;
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

                // Actualizar nombres de usuario en headers comunes
                const userElements = ['userName', 'currentUserName', 'headerUserName'];
                userElements.forEach(id => {
                    const el = document.getElementById(id);
                    if (el) el.textContent = window.currentUser.name;
                });

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

            const matches = tracking.includes(search) ||
                title.includes(search) ||
                desc.includes(search) ||
                creator.includes(search) ||
                email.includes(search) ||
                ticketSede.includes(search);

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
        } else {
            alert('No hay tickets para exportar');
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
        formatField(t.assigned_to_name || 'Sin asignar'),
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
    const isNew = window.isNewTicket ? window.isNewTicket(ticket.created_at) : false;
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
            <div><strong>🛠️ Asignado a:</strong> ${window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
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
            <button class="btn-page" ${currentPage <= 1 ? 'disabled' : ''} onclick="${onPageChangeFnName}(${currentPage - 1})" title="Página anterior">
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
        paginationHtml += `<button class="page-num" onclick="${onPageChangeFnName}(1)">1</button>`;
        if (startPage > 2) paginationHtml += `<span style="padding: 4px 2px; color: #9CA3AF;">...</span>`;
    }

    for (let p = startPage; p <= endPage; p++) {
        paginationHtml += `
            <button class="page-num ${p === currentPage ? 'active' : ''}" onclick="${onPageChangeFnName}(${p})">
                ${p}
            </button>
        `;
    }

    if (endPage < totalPages) {
        if (endPage < totalPages - 1) paginationHtml += `<span style="padding: 4px 2px; color: #9CA3AF;">...</span>`;
        paginationHtml += `<button class="page-num" onclick="${onPageChangeFnName}(${totalPages})">${totalPages}</button>`;
    }

    paginationHtml += `
            </div>
            <button class="btn-page" ${currentPage >= totalPages ? 'disabled' : ''} onclick="${onPageChangeFnName}(${currentPage + 1})" title="Página siguiente">
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
    const isNew = window.isNewTicket ? window.isNewTicket(ticket.created_at) : false;
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
            <div><strong>🛠️ Asignado:</strong> ${window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
        </div>
    </div>
    `;
};

window.renderKanbanBoard = function (containerId, tickets, columnPages, onColumnPageChangeName = 'changeColumnPage', isReadOnly = false) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (!tickets || tickets.length === 0) {
        container.innerHTML = '<div style="padding: 2.5rem; text-align: center; color: #6c757d; background: white; border-radius: 8px; border: 1px solid #e2e8f0; width: 100%;">No hay tickets para mostrar con los filtros seleccionados</div>';
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
                <button class="btn-col-page" ${page <= 1 ? 'disabled' : ''} onclick="event.stopPropagation(); ${onColumnPageChangeName}('${status}', ${page - 1})">◀ Anterior</button>
                <span class="col-page-info">${page} / ${totalPages} (${totalItems})</span>
                <button class="btn-col-page" ${page >= totalPages ? 'disabled' : ''} onclick="event.stopPropagation(); ${onColumnPageChangeName}('${status}', ${page + 1})">Siguiente ▶</button>
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
    const isNew = window.isNewTicket ? window.isNewTicket(ticket.created_at) : false;
    const timeAgo = window.formatRelativeTime ? window.formatRelativeTime(ticket.created_at) : (window.getRelativeTime ? window.getRelativeTime(ticket.created_at) : '');

    let quickButtons = '';
    if (!isReadOnly) {
        if (status === 'open') {
            quickButtons = `
                <button type="button" class="btn-quick-action action-in-progress" title="Mover a En Progreso" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'in-progress');">
                    🔵 En Progreso
                </button>
                <button type="button" class="btn-quick-action action-closed" title="Mover a Cerrado" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'closed');">
                    🟢 Cerrar
                </button>
            `;
        } else if (status === 'in-progress') {
            quickButtons = `
                <button type="button" class="btn-quick-action action-open" title="Mover a Pendiente" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'open');">
                    🟡 Pendiente
                </button>
                <button type="button" class="btn-quick-action action-closed" title="Mover a Cerrado" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'closed');">
                    🟢 Cerrar
                </button>
            `;
        } else if (status === 'closed') {
            quickButtons = `
                <button type="button" class="btn-quick-action action-open" title="Reabrir Ticket" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'open');">
                    🟡 Reabrir
                </button>
                <button type="button" class="btn-quick-action action-in-progress" title="Mover a En Progreso" onclick="event.stopPropagation(); window.triggerTicketStatusChange(${ticket.id}, 'in-progress');">
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
                <div title="${window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}"><strong>🛠️ Asignado:</strong> ${window.escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
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
        <div class="ticket-tabs-container">
            <button type="button" class="ticket-tab ${currentTab === 'open' ? 'active' : ''}" data-status="open" onclick="${onTabChangeFnName}('open')">
                <span>🟡</span>
                <span>Pendientes</span>
                <span class="tab-badge">${openCount}</span>
            </button>
            <button type="button" class="ticket-tab ${currentTab === 'in-progress' ? 'active' : ''}" data-status="in-progress" onclick="${onTabChangeFnName}('in-progress')">
                <span>🔵</span>
                <span>En Progreso</span>
                <span class="tab-badge">${inProgressCount}</span>
            </button>
            <button type="button" class="ticket-tab ${currentTab === 'closed' ? 'active' : ''}" data-status="closed" onclick="${onTabChangeFnName}('closed')">
                <span>🟢</span>
                <span>Cerrados</span>
                <span class="tab-badge">${closedCount}</span>
            </button>
        </div>
    `;

    let contentHtml = '';
    if (pageTickets.length === 0) {
        const tabLabel = currentTab === 'open' ? 'pendientes' : (currentTab === 'in-progress' ? 'en progreso' : 'cerrados');
        contentHtml = `
            <div style="padding: 3rem 1.5rem; text-align: center; color: #64748b; background: white; border-radius: 10px; border: 1px dashed #cbd5e1; margin-bottom: 1.5rem;">
                <div style="font-size: 2.2rem; margin-bottom: 0.5rem;">📭</div>
                <h3 style="font-size: 1.1rem; color: #1e293b; margin-bottom: 0.25rem;">No hay tickets ${tabLabel}</h3>
                <p style="font-size: 0.88rem;">No se encontraron tickets con los filtros y búsqueda actuales.</p>
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
        } else if (typeof showNotification === 'function') {
            showNotification(`✅ ${successMessage}`, 'success');
        } else {
            alert(successMessage);
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



