let filteredTickets = [];
let editingUserId = null; // Added missing declaration

// Paginación
let currentPage = 1;
const itemsPerPage = 5;
let totalPages = 1;

window.addEventListener('load', function () {
    window.verifySession(['administrador', 'gerencia'], function (user) {
        // Ocultar botón de crear usuario si es gerencia
        if (user.role === 'gerencia') {
            const createBtn = document.getElementById('btnCreateUser');
            if (createBtn) createBtn.style.display = 'none';
        }
        
        loadTickets();
        startAutoRefresh();
    });
});

// Login form handler
document.getElementById('loginFormElement').addEventListener('submit', function (e) {
    e.preventDefault();

    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    const errorDiv = document.getElementById('loginError');

    errorDiv.textContent = '';

    fetch('/api/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({ email, password })
    })
        .then(response => response.json().catch(() => ({ error: 'Error de respuesta del servidor' })))
        .then(data => {
            if (data.token && data.user) {
                if (data.user.role !== 'administrador' && data.user.role !== 'gerencia') {
                    errorDiv.textContent = 'Acceso denegado. Solo administradores o gerencia pueden acceder.';
                    return;
                }
                currentUser = data.user;
                document.getElementById('currentUserName').textContent = currentUser.name;
                hideLogin();
                loadTickets();
                startAutoRefresh();
            } else {
                errorDiv.textContent = data.error || 'Error al iniciar sesión';
            }
        })
        .catch(error => {
            errorDiv.textContent = 'Error de conexión';
        });

});

function startAutoRefresh() {
    // Actualizar cada 30 segundos
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
    refreshInterval = setInterval(() => {
        if (currentUser && !isLoading) {
            loadTickets(true); // true = refresh silencioso
        }
    }, 30000);
}

function loadTickets(silentRefresh = false) {
    if (isLoading && !silentRefresh) return;

    isLoading = true;

    if (!silentRefresh) {
        document.getElementById('ticketsList').innerHTML = '<div style="padding: 2rem; text-align: center; color: #6c757d;"><div style="display: inline-block; width: 40px; height: 40px; border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; animation: spin 1s linear infinite;"></div><p style="margin-top: 1rem;">Cargando tickets...</p></div>';
    }

    fetch('/api/tickets')
        .then(response => {
            if (!response.ok) {
                throw new Error('Error al cargar tickets');
            }
            return response.json();
        })
        .then(data => {
            allTickets = data;
            applyFilters();
            updateStats();
            isLoading = false;

            // Verificar si hay un ticket para abrir desde URL (ej: ?openTicket=123)
            checkOpenTicketFromUrl();
        })
        .catch(error => {

            isLoading = false;
            if (error.message.includes('401') || error.message.includes('403')) {
                logout();
            } else if (!silentRefresh) {
                document.getElementById('ticketsList').innerHTML = '<div style="padding: 2rem; text-align: center; color: #dc3545;">❌ Error al cargar tickets. <button onclick="loadTickets()" style="margin-top: 1rem; padding: 0.5rem 1rem; background: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer;">Reintentar</button></div>';
            }
        });
}

// Verificar si hay un ticket para abrir desde la URL
let urlTicketOpened = false;
function checkOpenTicketFromUrl() {
    if (urlTicketOpened) return;

    const urlParams = new URLSearchParams(window.location.search);
    const ticketId = urlParams.get('openTicket');

    if (ticketId) {
        const ticketIdInt = parseInt(ticketId);

        setTimeout(() => {
            if (typeof showTicketDetails === 'function') {
                showTicketDetails(ticketIdInt);
            }

            const newUrl = window.location.pathname;
            window.history.replaceState({}, document.title, newUrl);
            urlTicketOpened = true;
        }, 300);
    }
}

function updateStats() {
    const total = allTickets.length;
    const open = allTickets.filter(t => t.status === 'open').length;
    const inProgress = allTickets.filter(t => t.status === 'in-progress').length;
    const closed = allTickets.filter(t => t.status === 'closed').length;

    const statsGrid = document.getElementById('statsGrid');
    statsGrid.innerHTML = `
        <div class="stat-card">
            <div class="stat-number">${total}</div>
            <div class="stat-label">Total Tickets</div>
            <div class="stat-bar"><div class="stat-bar-fill" style="width: 100%;"></div></div>
        </div>
        <div class="stat-card">
            <div class="stat-number">${open}</div>
            <div class="stat-label">Pendientes</div>
            <div class="stat-bar"><div class="stat-bar-fill" style="width: ${total > 0 ? (open / total * 100) : 0}%; background: #ffc107;"></div></div>
        </div>
        <div class="stat-card">
            <div class="stat-number">${inProgress}</div>
            <div class="stat-label">En Progreso</div>
            <div class="stat-bar"><div class="stat-bar-fill" style="width: ${total > 0 ? (inProgress / total * 100) : 0}%; background: #17a2b8;"></div></div>
        </div>
        <div class="stat-card">
            <div class="stat-number">${closed}</div>
            <div class="stat-label">Cerrados</div>
            <div class="stat-bar"><div class="stat-bar-fill" style="width: ${total > 0 ? (closed / total * 100) : 0}%; background: #28a745;"></div></div>
        </div>
    `;
}

let activeTicketTab = 'open';
let tabPages = { open: 1, 'in-progress': 1, closed: 1 };

function renderTickets() {
    const isReadOnly = currentUser && (currentUser.role === 'gerencia');
    if (typeof window.renderTabbedTicketView === 'function') {
        window.renderTabbedTicketView('ticketsList', filteredTickets, activeTicketTab, tabPages, 'switchTicketTab', 'changeTabPage', isReadOnly);
    }
}

function switchTicketTab(newTab) {
    activeTicketTab = newTab;
    renderTickets();
}

function changeTabPage(newPage) {
    tabPages[activeTicketTab] = newPage;
    renderTickets();
    const listEl = document.getElementById('ticketsList');
    if (listEl) listEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

window.switchTicketTab = switchTicketTab;
window.changeTabPage = changeTabPage;

function handleKanbanDragStart(event) {
    const card = event.currentTarget;
    kanbanDragTicketId = card.getAttribute('data-ticket-id');
    kanbanDragSourceStatus = card.getAttribute('data-status');
    if (event.dataTransfer) {
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', kanbanDragTicketId);
    }
    card.classList.add('dragging');
}

function handleKanbanDragEnd(event) {
    const card = event.currentTarget;
    card.classList.remove('dragging');
    kanbanDragTicketId = null;
    kanbanDragSourceStatus = null;
    document.querySelectorAll('.kanban-column.drag-over').forEach(col => col.classList.remove('drag-over'));
}

function handleKanbanDragOver(event) {
    event.preventDefault();
    if (event.dataTransfer) {
        event.dataTransfer.dropEffect = 'move';
    }
    const column = event.currentTarget.closest('.kanban-column');
    if (column) {
        column.classList.add('drag-over');
    }
}

function handleKanbanDragLeave(event) {
    const column = event.currentTarget.closest('.kanban-column');
    if (column) {
        column.classList.remove('drag-over');
    }
}

function handleKanbanDrop(event, targetStatus) {
    event.preventDefault();
    const column = event.currentTarget.closest('.kanban-column');
    if (column) {
        column.classList.remove('drag-over');
    }

    const ticketId = kanbanDragTicketId || (event.dataTransfer && event.dataTransfer.getData('text/plain'));
    if (!ticketId) return;

    if (targetStatus === kanbanDragSourceStatus) {
        kanbanDragTicketId = null;
        kanbanDragSourceStatus = null;
        return;
    }

    kanbanDragTicketId = null;
    kanbanDragSourceStatus = null;
    updateTicketStatus(ticketId, targetStatus);
}

function openTicketContextMenu(event, ticketId, currentStatus) {
    if (event) {
        event.preventDefault();
        event.stopPropagation();
    }

    closeActiveTicketContextMenu();

    const menu = document.createElement('div');
    menu.className = 'ticket-context-menu';
    menu.setAttribute('role', 'menu');
    menu.innerHTML = `
        <button type="button" role="menuitem" onclick="handleTicketContextMenuAction(${ticketId}, 'open')" ${currentStatus === 'open' ? 'disabled' : ''}>🟡 Mover a Pendiente</button>
        <button type="button" role="menuitem" onclick="handleTicketContextMenuAction(${ticketId}, 'in-progress')" ${currentStatus === 'in-progress' ? 'disabled' : ''}>🔵 Mover a En Progreso</button>
        <button type="button" role="menuitem" onclick="handleTicketContextMenuAction(${ticketId}, 'closed')" ${currentStatus === 'closed' ? 'disabled' : ''}>🟢 Mover a Cerrado</button>
    `;

    let clientX = event && typeof event.clientX === 'number' ? event.clientX : 0;
    let clientY = event && typeof event.clientY === 'number' ? event.clientY : 0;

    if (!clientX && !clientY && event && event.target) {
        const rect = event.target.getBoundingClientRect();
        clientX = rect.right - 8;
        clientY = rect.top + 8;
    }

    const scrollX = window.scrollX || window.pageXOffset;
    const scrollY = window.scrollY || window.pageYOffset;
    menu.style.left = (clientX + scrollX) + 'px';
    menu.style.top = (clientY + scrollY) + 'px';

    document.body.appendChild(menu);
    activeTicketContextMenu = menu;

    document.addEventListener('click', handleTicketContextMenuOutsideClick, { capture: true, once: true });
}

function handleTicketContextMenuAction(ticketId, targetStatus) {
    if (!ticketId || !targetStatus) return;
    closeActiveTicketContextMenu();
    updateTicketStatus(ticketId, targetStatus);
}

function closeActiveTicketContextMenu() {
    if (activeTicketContextMenu) {
        activeTicketContextMenu.remove();
        activeTicketContextMenu = null;
    }
}

function handleTicketContextMenuOutsideClick(event) {
    if (!activeTicketContextMenu) return;
    if (!activeTicketContextMenu.contains(event.target)) {
        closeActiveTicketContextMenu();
    }
}

function handleTicketKeydown(event, ticketId, currentStatus) {
    const key = event.key;

    if (key === 'Enter') {
        event.preventDefault();
        showTicketDetails(ticketId);
        return;
    }

    if ((key === 'F10' && event.shiftKey) || key === 'ContextMenu') {
        event.preventDefault();
        const card = event.currentTarget;
        const rect = card.getBoundingClientRect();
        const fakeEvent = {
            preventDefault: () => { },
            stopPropagation: () => { },
            clientX: rect.right - 8,
            clientY: rect.top + 8,
            target: card
        };
        openTicketContextMenu(fakeEvent, ticketId, currentStatus);
        return;
    }
}

function updateTicketStatus(ticketId, status, options) {
    const statusText = getStatusText(status);
    const opts = options || {};

    fetch(`/api/tickets/${ticketId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ status })
    })
        .then(response => {
            if (!response.ok) {
                throw new Error('Error al actualizar ticket');
            }
            return response.json();
        })
        .then(data => {
            showToast(`✅ Estado cambiado a: ${statusText}`, 'success');

            // Mantener cache local sincronizada
            if (Array.isArray(allTickets)) {
                const idx = allTickets.findIndex(t => String(t.id) === String(ticketId));
                if (idx !== -1) {
                    allTickets[idx] = { ...allTickets[idx], ...data };
                }
            }

            // Actualizar modal si está Pendiente
            syncModalTicketState(data);

            loadTickets();
            if (typeof opts.onSuccess === 'function') {
                opts.onSuccess(data);
            }
        })
        .catch(error => {

            showToast('❌ Error al actualizar el estado del ticket', 'error');
            if (typeof opts.onError === 'function') {
                opts.onError(error);
            }
        });
}

function syncModalTicketState(updatedTicket) {
    if (!updatedTicket || !updatedTicket.id) return;
    const ticketId = updatedTicket.id;

    // Actualizar cache local de tickets
    if (Array.isArray(allTickets)) {
        const idx = allTickets.findIndex(t => String(t.id) === String(ticketId));
        if (idx !== -1) {
            allTickets[idx] = { ...allTickets[idx], ...updatedTicket };
        }
    }

    const statusBadge = document.getElementById(`ticketStatusBadge-${ticketId}`);
    const statusSelect = document.getElementById(`ticketStatusSelect-${ticketId}`);
    const statusHelp = document.getElementById(`ticketStatusHelp-${ticketId}`);

    const priorityLabel = document.getElementById(`ticketPriorityLabel-${ticketId}`);
    const priorityCard = document.getElementById(`ticketPriorityCard-${ticketId}`);
    const prioritySelect = document.getElementById(`ticketPrioritySelect-${ticketId}`);
    const priorityHelp = document.getElementById(`ticketPriorityHelp-${ticketId}`);

    if (updatedTicket.status) {
        const statusText = getStatusText(updatedTicket.status);
        if (statusBadge) {
            statusBadge.textContent = statusText;
            statusBadge.className = `ticket-status status-${updatedTicket.status}`;
        }
        if (statusSelect) {
            statusSelect.value = updatedTicket.status;
            statusSelect.setAttribute('data-current-status', updatedTicket.status);
        }
        if (statusHelp) {
            statusHelp.textContent = 'Estado actualizado correctamente.';
            statusHelp.style.color = '#2F9E44';
        }
    }

    if (updatedTicket.priority) {
        let priorityText = '';
        let priorityColor = '';
        if (updatedTicket.priority === 'high') {
            priorityText = '🔴 Alta';
            priorityColor = '#dc3545';
        } else if (updatedTicket.priority === 'medium') {
            priorityText = '🟡 Media';
            priorityColor = '#ffc107';
        } else {
            priorityText = '🟢 Baja';
            priorityColor = '#28a745';
        }

        if (priorityLabel) {
            priorityLabel.textContent = priorityText;
        }
        if (priorityCard) {
            priorityCard.style.borderLeftColor = priorityColor;
        }
        if (prioritySelect) {
            prioritySelect.value = updatedTicket.priority;
            prioritySelect.setAttribute('data-current-priority', updatedTicket.priority);
        }
        if (priorityHelp) {
            priorityHelp.textContent = 'Prioridad actualizado correctamente.';
            priorityHelp.style.color = '#2F9E44';
        }
    }

    if (typeof updatedTicket.assigned_to_name !== 'undefined') {
        const assignedEl = document.getElementById(`ticketAssignedTo-${ticketId}`);
        if (assignedEl) {
            assignedEl.textContent = updatedTicket.assigned_to_name || 'No asignado';
        }
    }

    if (typeof updatedTicket.department !== 'undefined') {
        const deptEl = document.getElementById(`ticketDepartment-${ticketId}`);
        if (deptEl) {
            deptEl.textContent = updatedTicket.department || 'General';
        }
    }

    if (updatedTicket.updated_at) {
        const updatedAtEl = document.getElementById(`ticketUpdatedAt-${ticketId}`);
        if (updatedAtEl) {
            try {
                updatedAtEl.textContent = new Date(updatedTicket.updated_at).toLocaleString('es-ES', { dateStyle: 'long', timeStyle: 'short' });
            } catch (e) {
                // Ignorar errores de formato de fecha
            }
        }
    }
}

let activeConfirmDialog = null;

function closeConfirmDialog() {
    if (!activeConfirmDialog) return;
    const { overlay, keyHandler } = activeConfirmDialog;
    if (overlay && overlay.parentNode) {
        overlay.remove();
    }
    if (keyHandler) {
        document.removeEventListener('keydown', keyHandler);
    }
    activeConfirmDialog = null;
}

function openConfirmDialog(options) {
    const opts = options || {};
    const title = opts.title || 'Confirmar acción';
    const message = opts.message || '¿Estás seguro de continuar?';
    const confirmLabel = opts.confirmLabel || 'Confirmar';
    const cancelLabel = opts.cancelLabel || 'Cancelar';

    closeConfirmDialog();

    const overlay = document.createElement('div');
    overlay.className = 'confirm-dialog-overlay';
    overlay.style.cssText = `
        position: fixed;
        inset: 0;
        background: rgba(15, 23, 42, 0.55);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 12000;
    `;

    const dialog = document.createElement('div');
    dialog.className = 'confirm-dialog';
    dialog.setAttribute('role', 'dialog');
    dialog.setAttribute('aria-modal', 'true');
    dialog.style.cssText = `
        background: #111827;
        color: #F9FAFB;
        border-radius: 12px;
        padding: 20px 22px;
        max-width: 420px;
        width: 100%;
        box-shadow: 0 20px 40px rgba(15, 23, 42, 0.5);
    `;

    const titleEl = document.createElement('div');
    titleEl.style.cssText = 'font-weight: 600; font-size: 1.05rem; margin-bottom: 6px; display:flex; align-items:center; gap:8px;';
    titleEl.innerHTML = '<span>⚠️</span><span>' + title + '</span>';

    const messageEl = document.createElement('div');
    messageEl.style.cssText = 'font-size: 0.9rem; color: #E5E7EB; margin-bottom: 16px;';
    messageEl.textContent = message;

    const actions = document.createElement('div');
    actions.style.cssText = 'display:flex; justify-content:flex-end; gap: 10px; margin-top: 6px;';

    const cancelBtn = document.createElement('button');
    cancelBtn.type = 'button';
    cancelBtn.className = 'btn btn-outline';
    cancelBtn.textContent = cancelLabel;

    const confirmBtn = document.createElement('button');
    confirmBtn.type = 'button';
    confirmBtn.className = 'btn btn-danger';
    confirmBtn.textContent = confirmLabel;

    actions.appendChild(cancelBtn);
    actions.appendChild(confirmBtn);

    dialog.appendChild(titleEl);
    dialog.appendChild(messageEl);
    dialog.appendChild(actions);
    overlay.appendChild(dialog);

    const onConfirm = () => {
        closeConfirmDialog();
        if (typeof opts.onConfirm === 'function') {
            opts.onConfirm();
        }
    };

    const onCancel = () => {
        closeConfirmDialog();
        if (typeof opts.onCancel === 'function') {
            opts.onCancel();
        }
    };

    cancelBtn.addEventListener('click', onCancel);
    confirmBtn.addEventListener('click', onConfirm);

    const keyHandler = (event) => {
        if (event.key === 'Escape') {
            event.preventDefault();
            onCancel();
        }
    };

    overlay.addEventListener('click', (event) => {
        if (event.target === overlay) {
            onCancel();
        }
    });

    document.addEventListener('keydown', keyHandler);

    activeConfirmDialog = { overlay, keyHandler };
    document.body.appendChild(overlay);

    confirmBtn.focus();
}

function handleModalStatusChange(ticketId, selectEl) {
    if (!selectEl) return;

    const newStatus = selectEl.value;
    const currentStatus = selectEl.getAttribute('data-current-status');
    const helpEl = document.getElementById(`ticketStatusHelp-${ticketId}`);

    if (!newStatus || newStatus === currentStatus) {
        return;
    }

    const performUpdate = () => {
        selectEl.disabled = true;
        if (helpEl) {
            helpEl.textContent = 'Actualizando estado...';
            helpEl.style.color = '#6c757d';
        }

        updateTicketStatus(ticketId, newStatus, {
            onSuccess: function () {
                selectEl.disabled = false;
                selectEl.setAttribute('data-current-status', newStatus);
                if (helpEl) {
                    helpEl.textContent = 'Estado actualizado correctamente.';
                    helpEl.style.color = '#2F9E44';
                }

                const badge = document.getElementById(`ticketStatusBadge-${ticketId}`);
                if (badge) {
                    badge.textContent = getStatusText(newStatus);
                    badge.className = `ticket-status status-${newStatus}`;
                }
            },
            onError: function () {
                selectEl.disabled = false;
                selectEl.value = currentStatus;
                if (helpEl) {
                    helpEl.textContent = 'No se pudo actualizar el estado. Intenta nuevamente.';
                    helpEl.style.color = '#dc3545';
                }
            }
        });
    };

    if (newStatus === 'closed') {
        openConfirmDialog({
            title: 'Cerrar ticket',
            message: '¿Seguro que deseas cerrar este ticket? Esta acción puede ser definitiva.',
            confirmLabel: 'Cerrar ticket',
            cancelLabel: 'Cancelar',
            onConfirm: performUpdate,
            onCancel: function () {
                selectEl.value = currentStatus;
                if (helpEl) {
                    helpEl.textContent = 'Cambio de estado cancelado.';
                    helpEl.style.color = '#6c757d';
                }
            }
        });
        return;
    }

    performUpdate();
}

function handleModalPriorityChange(ticketId, selectEl) {
    if (!selectEl) return;

    const newPriority = selectEl.value;
    const currentPriority = selectEl.getAttribute('data-current-priority');
    const helpEl = document.getElementById(`ticketPriorityHelp-${ticketId}`);

    if (!newPriority || newPriority === currentPriority) {
        return;
    }

    selectEl.disabled = true;
    if (helpEl) {
        helpEl.textContent = 'Actualizando prioridad...';
        helpEl.style.color = '#6c757d';
    }

    updateTicketPriority(ticketId, newPriority, {
        onSuccess: function () {
            selectEl.disabled = false;
            selectEl.setAttribute('data-current-priority', newPriority);
            if (helpEl) {
                helpEl.textContent = 'Prioridad actualizada correctamente.';
                helpEl.style.color = '#2F9E44';
            }
        },
        onError: function () {
            selectEl.disabled = false;
            selectEl.value = currentPriority;
            if (helpEl) {
                helpEl.textContent = 'No se pudo actualizar la prioridad. Intenta nuevamente.';
                helpEl.style.color = '#dc3545';
            }
        }
    });
}

function showToast(message, type = 'info') {
    // Limpiar mensaje de iconos duplicados (✔✖✅❌🔴🟢🟡)
    const cleanMessage = (message || '').replace(/[✔✖✅❌🔴🟢🟡⚠️]/g, '').trim();

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <div class="toast-content">
            <strong>${type === 'success' ? 'Éxito' : type === 'error' ? 'Error' : 'Aviso'}</strong>
            <span>${cleanMessage}</span>
        </div>
    `;

    const closeToast = () => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    };

    // Contenedor de toasts (esquina inferior derecha, máximo 3 visibles)
    let container = document.getElementById('toastContainer');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toastContainer';
        container.style.position = 'fixed';
        container.style.bottom = '20px';
        container.style.right = '20px';
        container.style.display = 'flex';
        container.style.flexDirection = 'column';
        container.style.alignItems = 'flex-end';
        container.style.gap = '10px';
        container.style.zIndex = '10000';
        document.body.appendChild(container);
    }

    // Si ya hay 3 toasts, eliminar el más antiguo
    if (container.children.length >= 3) {
        container.removeChild(container.firstElementChild);
    }

    container.appendChild(toast);
    requestAnimationFrame(() => toast.classList.add('show'));

    setTimeout(closeToast, 4000);
}

function updateDateMin() {
    const startDate = document.getElementById('startDateFilter').value;
    const endDateInput = document.getElementById('endDateFilter');
    
    if (startDate) {
        endDateInput.min = startDate;
        // Si la fecha de fin ya seleccionada es anterior a la nueva fecha de inicio, limpiarla
        if (endDateInput.value && endDateInput.value < startDate) {
            endDateInput.value = '';
        }
    } else {
        endDateInput.removeAttribute('min');
    }
}

function clearDateFilters() {
    document.getElementById('startDateFilter').value = '';
    document.getElementById('endDateFilter').value = '';
    document.getElementById('endDateFilter').removeAttribute('min');
    applyFilters();
}

function applyFilters() {
    const statusFilter = document.getElementById('statusFilter')?.value || '';
    const priorityFilter = document.getElementById('priorityFilter')?.value || '';
    const startDate = document.getElementById('startDateFilter').value;
    const endDate = document.getElementById('endDateFilter').value;
    const sortFilter = document.getElementById('sortFilter').value;

    filteredTickets = allTickets.filter(ticket => {
        const statusMatch = !statusFilter || ticket.status === statusFilter;
        const priorityMatch = !priorityFilter || ticket.priority === priorityFilter;

        // Filtro de rango de fechas
        let dateMatch = true;
        if (startDate || endDate) {
             // Convertimos la fecha del ticket a YYYY-MM-DD (local) para comparar solo la fecha
            const ticketDate = new Date(ticket.created_at);
            const ticketDateStr = ticketDate.toLocaleDateString('en-CA'); // Formato YYYY-MM-DD
            
            if (startDate && endDate) {
                dateMatch = ticketDateStr >= startDate && ticketDateStr <= endDate;
            } else if (startDate) {
                dateMatch = ticketDateStr >= startDate;
            } else if (endDate) {
                dateMatch = ticketDateStr <= endDate;
            }
        }

        // Búsqueda
        const searchMatch = !searchTerm ||
            ticket.title.toLowerCase().includes(searchTerm) ||
            ticket.description.toLowerCase().includes(searchTerm) ||
            (ticket.created_by_name && ticket.created_by_name.toLowerCase().includes(searchTerm)) ||
            (ticket.created_by_email && ticket.created_by_email.toLowerCase().includes(searchTerm)) ||
            (ticket.department && ticket.department.toLowerCase().includes(searchTerm));

        return statusMatch && priorityMatch && dateMatch && searchMatch;
    });

    // Ordenamiento
    sortTickets(filteredTickets, sortFilter);

    tabPages = { open: 1, 'in-progress': 1, closed: 1 };
    renderTickets();
}

function sortTickets(tickets, sortType) {
    const priorityValue = { high: 3, medium: 2, low: 1 };
    const statusValue = { open: 1, 'in-progress': 2, closed: 3 };

    switch (sortType) {
        case 'date-asc':
            tickets.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
            break;
        case 'date-desc':
            tickets.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
            break;
        case 'priority-desc':
            tickets.sort((a, b) => priorityValue[b.priority] - priorityValue[a.priority]);
            break;
        case 'priority-asc':
            tickets.sort((a, b) => priorityValue[a.priority] - priorityValue[b.priority]);
            break;
        case 'status':
            tickets.sort((a, b) => statusValue[a.status] - statusValue[b.status]);
            break;
        default:
            tickets.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    }
}

async function showTicketDetails(ticketId) {
    const ticket = allTickets.find(t => t.id === ticketId);
    if (!ticket) return;

    const modal = document.getElementById('ticketModal');
    const modalBody = document.getElementById('modalBody');

    const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;

    // Mostrar loading inicial
    modalBody.innerHTML = `
        <div style="text-align: center; padding: 2rem;">
            <div style="display: inline-block; width: 40px; height: 40px; border: 4px solid rgba(102, 126, 234, 0.3); border-top-color: #667eea; border-radius: 50%; animation: spin 1s linear infinite;"></div>
            <p style="margin-top: 15px; color: #6c757d;">Cargando detalles...</p>
        </div>
    `;
    modal.style.display = 'block';

    // Cargar actualizaciones del ticket
    let updates = [];
    try {
        const response = await fetch(`/api/tickets/${ticketId}/updates`, {
        });
        if (response.ok) {
            updates = await response.json();
        }
    } catch (error) {

    }

    modalBody.innerHTML = `
        <!-- Tracking ID (Estilo Gerencia) -->
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; text-align: center;">
            <div style="font-size: 0.9em; opacity: 0.9; margin-bottom: 5px;">🔍 Número de Seguimiento</div>
            <div style="font-size: 1.8em; font-weight: bold; letter-spacing: 2px; font-family: monospace;">${escapeHtml(trackingId)}</div>
            <button onclick="copyToClipboard('${trackingId}')" style="background: rgba(255,255,255,0.2); border: none; color: white; padding: 8px 16px; border-radius: 5px; cursor: pointer; margin-top: 10px; font-size: 0.9em;">
                📋 Copiar
            </button>
        </div>

        <div class="detail-row" style="margin-bottom: 15px;">
            <div class="detail-label" style="font-size: 0.85em; color: #6c757d; font-weight: 600; margin-bottom: 5px;">📋 Título</div>
            <div class="detail-value" style="font-size: 1.2em; font-weight: 600; color: #2c3e50;">${escapeHtml(ticket.title)}</div>
        </div>

        <div class="detail-row" style="margin-bottom: 15px;">
            <div class="detail-label" style="font-size: 0.85em; color: #6c757d; font-weight: 600; margin-bottom: 5px;">📝 Descripción</div>
            <div class="detail-value" style="white-space: pre-wrap; background: #f8f9fa; padding: 15px; border-radius: 8px;">${escapeHtml(ticket.description)}</div>
        </div>

        <div class="detail-row" style="margin-bottom: 15px;">
            <div class="detail-label" style="font-size: 0.85em; color: #6c757d; font-weight: 600; margin-bottom: 5px;">⚠️ Área Afectada</div>
            <div class="detail-value" style="font-size: 1.1em; color: #d63384; font-weight: 600;">${escapeHtml(ticket.affected_area || 'No especificada')}</div>
        </div>

        <div class="detail-row" style="margin-bottom: 15px;">
            <div class="detail-label" style="font-size: 0.85em; color: #6c757d; font-weight: 600; margin-bottom: 5px;">🏢 Sede</div>
            <div class="detail-value" style="font-size: 1.1em; color: #0d6efd; font-weight: 600;">${escapeHtml(ticket.sede || 'No especificada')}</div>
        </div>

        <!-- Estado y Prioridad (Grid Interactivo) -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 15px 0;">
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label" style="margin-bottom: 8px;">📊 Estado</div>
                <select id="ticketStatusSelect-${ticket.id}" 
                        data-current-status="${ticket.status}" 
                        onchange="handleModalStatusChange(${ticket.id}, this)" 
                        ${ticket.status === 'closed' ? 'disabled' : ''} 
                        style="width: 100%; padding: 8px; border: 1px solid #ced4da; border-radius: 5px; background: white; font-weight: 500;">
                    <option value="open" ${ticket.status === 'open' ? 'selected' : ''}>🟡 Pendiente</option>
                    <option value="in-progress" ${ticket.status === 'in-progress' ? 'selected' : ''}>🔵 En Progreso</option>
                    <option value="closed" ${ticket.status === 'closed' ? 'selected' : ''}>🟢 Cerrado</option>
                </select>
                <small style="display:block; margin-top:5px; font-size:0.75em; color:#6c757d;">
                    ${ticket.status === 'closed' ? 'Ticket cerrado.' : 'Cambiar estado.'}
                </small>
            </div>
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label" style="margin-bottom: 8px;">⚠️ Prioridad</div>
                <select id="ticketPrioritySelect-${ticket.id}" 
                        data-current-priority="${ticket.priority}" 
                        onchange="handleModalPriorityChange(${ticket.id}, this)" 
                        style="width: 100%; padding: 8px; border: 1px solid #ced4da; border-radius: 5px; background: white; font-weight: 500;">
                    <option value="high" ${ticket.priority === 'high' ? 'selected' : ''}>🔴 Alta</option>
                    <option value="medium" ${ticket.priority === 'medium' ? 'selected' : ''}>🟡 Media</option>
                    <option value="low" ${ticket.priority === 'low' ? 'selected' : ''}>🟢 Baja</option>
                </select>
            </div>
        </div>

        <!-- Info Grid -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 15px 0;">
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label">🏢 Departamento</div>
                <div class="detail-value">${escapeHtml(ticket.department || 'General')}</div>
            </div>
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label">👤 Creado por</div>
                <div class="detail-value">
                    ${escapeHtml(ticket.created_by_name || 'Anónimo')}<br>
                    <small style="color:#6c757d">${escapeHtml(ticket.created_by_email || '')}</small>
                </div>
            </div>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 15px 0;">
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label">🔧 Asignado a</div>
                <div class="detail-value" id="ticketAssignedTo-${ticket.id}">
                    ${escapeHtml(ticket.assigned_to_name || 'Sin asignar')}<br>
                    <small style="color:#6c757d; font-size:0.8em; cursor:pointer; text-decoration:underline;" onclick="assignTicketToSelf(${ticket.id})">
                        ${ticket.assigned_to ? 'Reasignar a mí' : 'Asignarme este ticket'}
                    </small>
                </div>
            </div>
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label">📅 Fecha de Creación</div>
                <div class="detail-value">${new Date(ticket.created_at).toLocaleString('es-ES')}</div>
            </div>
        </div>

        <!-- Attachments -->
        ${window.renderTicketAttachments ? window.renderTicketAttachments(ticket.attachments) : ''}

        <!-- Comment Form -->
        <div class="comment-form" style="margin-top: 20px; padding: 15px; background: #fff3cd; border: 1px solid #ffeeba; border-radius: 8px;">
            <h4 style="font-size:0.95rem; font-weight:600; color:#856404; margin-bottom:1rem;">📝 Agregar respuesta</h4>
            
            

            <div style="margin-top: 10px;">
                <textarea id="commentText" placeholder="Escribe tu respuesta aquí..." style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; min-height: 80px;"></textarea>
            </div>
            <div style="margin-top:10px; text-align:right;">
                <button onclick="addComment()" style="background: #17a2b8; color: white; border: none; padding: 8px 15px; border-radius: 5px; cursor: pointer; font-weight: 600;">
                    Enviar Comentario
                </button>
            </div>
        </div>

        <!-- History -->
        ${updates.length > 0 ? `
            <div style="margin-top: 30px;">
                <h3 style="color: #2c3e50; border-bottom: 2px solid #e1e8ed; padding-bottom: 10px; margin-bottom: 20px;">📋 Historial</h3>
                <div class="timeline">
                    ${updates.map(update => {
                        const isSystem = !update.user_name || update.user_name === 'Sistema';
                        const isStatusChange = update.update_type === 'status_change';
                        const isPriorityChange = update.update_type === 'priority_change';
                        const isReopened = update.content && update.content.includes('🔓');
                        const isClosed = update.content && update.content.includes('🔒');
                        
                        let displayName = update.user_name || 'Usuario';
                        const roleMap = {
                            'administrador': 'Administración',
                            'support': 'Soporte Técnico',
                            'compras': 'Compras',
                            'rrhh': 'RRHH',
                            'mantenimiento': 'Mantenimiento',
                            'facturacion': 'Facturación',
                            'gerencia': 'Gerencia'
                        };

                        if (update.user_role && roleMap[update.user_role]) {
                            displayName = roleMap[update.user_role];
                        } else if (update.role && roleMap[update.role]) {
                             displayName = roleMap[update.role];
                        }

                        const isMe = (currentUser && String(update.user_id) === String(currentUser.id));
                        const avatarLetter = isReopened ? '🔓' : (isClosed ? '🔒' : (isSystem ? '⚙️' : (displayName.charAt(0).toUpperCase())));

                        let badgeHtml = '';
                        let borderStyle = '';
                        if (isReopened) {
                            badgeHtml = '<span style="font-size:0.75em; background:#DCFCE7; color:#15803D; padding:2px 8px; border-radius:10px; font-weight:700;">🔓 Reabierto</span>';
                            borderStyle = 'border-left:4px solid #10B981;';
                        } else if (isClosed) {
                            badgeHtml = '<span style="font-size:0.75em; background:#FEE2E2; color:#DC2626; padding:2px 8px; border-radius:10px; font-weight:700;">🔒 Cerrado</span>';
                            borderStyle = 'border-left:4px solid #EF4444;';
                        } else if (isStatusChange) {
                            badgeHtml = '<span style="font-size:0.75em; background:#fff3cd; color:#856404; padding:2px 8px; border-radius:10px; font-weight:600;">🔄 Estado</span>';
                            borderStyle = 'border-left:4px solid #f59f00;';
                        } else if (isPriorityChange) {
                            badgeHtml = '<span style="font-size:0.75em; background:#E0F2FE; color:#0369A1; padding:2px 8px; border-radius:10px; font-weight:600;">⚠️ Prioridad</span>';
                            borderStyle = 'border-left:4px solid #0284C7;';
                        }

                        return `
                        <div class="timeline-item ${isMe ? 'comment-own' : ''}" style="display:flex; gap:12px; margin-bottom:16px; ${isMe ? 'flex-direction:row-reverse;' : ''}">
                            <div class="timeline-avatar ${isSystem ? 'system' : ''}" style="width:36px; height:36px; border-radius:50%; background:${isSystem ? '#e9ecef' : (isMe ? '#4dabf7' : '#e9ecef')}; color:${isSystem ? '#495057' : (isMe ? '#fff' : '#495057')}; display:flex; align-items:center; justify-content:center; font-weight:bold; font-size:0.9em; flex-shrink:0;">
                                ${avatarLetter}
                            </div>
                            <div class="timeline-content-wrapper" style="background:${isSystem ? '#f8f9fa' : (isMe ? '#e7f5ff' : '#f1f3f5')}; padding:12px 16px; border-radius:12px; box-shadow:0 1px 2px rgba(0,0,0,0.05); max-width:85%; ${borderStyle}">
                                <div class="timeline-header" style="margin-bottom:6px; display:flex; align-items:center; gap:8px; flex-wrap:wrap; justify-content:${isMe ? 'flex-end' : 'flex-start'};">
                                    <span class="timeline-user" style="font-weight:600; font-size:0.95em; color:#343a40;">${escapeHtml(displayName)}</span>
                                    ${badgeHtml}
                                    <span class="timeline-date" style="font-size:0.8em; color:#868e96;">${getRelativeTime(update.created_at)}</span>
                                </div>
                                <div class="timeline-content" style="color:#212529; line-height:1.5;">${escapeHtml(update.content).replace(/\n/g, '<br>')}</div>
                            </div>
                        </div>
                        `
                    }).join('')}
                </div>
            </div>
        ` : `
            <div style="margin-top: 30px;">
                <h3 style="color: #2c3e50; border-bottom: 2px solid #e1e8ed; padding-bottom: 10px; margin-bottom: 20px;">📋 Historial</h3>
                <div class="timeline">
                    <div style="text-align:center; padding:2rem; color:#6c757d;">
                        No hay actividad aún en este ticket.
                    </div>
                </div>
            </div>
        `}
    `;
}

function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).then(() => {
            showToast('📋 Tracking ID copiado al portapapeles', 'success');
        }).catch(err => {

            fallbackCopyTextToClipboard(text);
        });
    } else {
        fallbackCopyTextToClipboard(text);
    }
}

function fallbackCopyTextToClipboard(text) {
    var textArea = document.createElement("textarea");
    textArea.value = text;
    
    // Avoid scrolling to bottom
    textArea.style.top = "0";
    textArea.style.left = "0";
    textArea.style.position = "fixed";
    textArea.style.opacity = "0";

    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
        var successful = document.execCommand('copy');
        if (successful) {
            showToast('📋 Tracking ID copiado al portapapeles', 'success');
        } else {
            showToast('❌ Error al copiar', 'error');
        }
    } catch (err) {

        showToast('❌ Error al copiar', 'error');
    }

    document.body.removeChild(textArea);
}

function closeTicketModal() {
    document.getElementById('ticketModal').style.display = 'none';
}

// Cerrar modal al hacer click fuera
document.getElementById('ticketModal').addEventListener('click', function (e) {
    if (e.target === this) {
        closeTicketModal();
    }
});

function getStatusText(status) {
    switch (status) {
        case 'open': return 'Pendiente';
        case 'in-progress': return 'En Progreso';
        case 'closed': return 'Cerrado';
        default: return status;
    }
}

// Función para escapar HTML y prevenir XSS
function escapeHtml(text) {
    if (text === null || text === undefined) return '';
    return String(text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

function updateTicketPriority(ticketId, priority, options) {
    const opts = options || {};
    fetch(`/api/tickets/${ticketId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ priority })
    })
        .then(response => {
            if (!response.ok) {
                throw new Error('Error al actualizar prioridad');
            }
            return response.json();
        })
        .then(data => {
            const priorityText = priority === 'high' ? '🔴 Alta' : priority === 'medium' ? '🟡 Media' : '🟢 Baja';

            // Actualizar cache y modal
            syncModalTicketState(data);

            showToast(`✅ Prioridad cambiada a: ${priorityText}`, 'success');
            loadTickets();

            if (typeof opts.onSuccess === 'function') {
                opts.onSuccess(data);
            }
        })
        .catch(error => {

            showToast('❌ Error al actualizar la prioridad', 'error');
            if (typeof opts.onError === 'function') {
                opts.onError(error);
            }
        });
}

function getRelativeTime(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now - date;
    const diffSecs = Math.floor(diffMs / 1000);
    const diffMins = Math.floor(diffSecs / 60);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffSecs < 60) return 'Hace unos segundos';
    if (diffMins < 60) return `Hace ${diffMins} min`;
    if (diffHours < 24) return `Hace ${diffHours}h`;
    if (diffDays < 7) return `Hace ${diffDays}d`;
    return date.toLocaleDateString('es-ES');
}

function isNewTicket(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffHours = (now - date) / (1000 * 60 * 60);
    return diffHours < 24;
}

function getPriorityText(priority) {
    switch (priority) {
        case 'high': return 'Alta';
        case 'medium': return 'Media';
        case 'low': return 'Baja';
        default: return priority;
    }
}

// Búsqueda con debounce
let searchTerm = '';
let searchTimeout = null;
document.getElementById('searchInput').addEventListener('input', function (e) {
    searchTerm = e.target.value.toLowerCase();

    // Cancelar búsqueda anterior
    if (searchTimeout) {
        clearTimeout(searchTimeout);
    }

    // Esperar 300ms antes de buscar
    searchTimeout = setTimeout(() => {
        applyFilters();
    }, 300);
});

// Auto-refresh cada 30 segundos

function startAutoRefresh() {
    // Limpiar interval existente
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
    }

    // Refresh cada 30 segundos
    autoRefreshInterval = setInterval(() => {
        loadTickets(true); // true = silent refresh
    }, 30000);
}

function stopAutoRefresh() {
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
    }
}

// Iniciar auto-refresh al cargar tickets
// Movido a loadTickets success para evitar doble llamada o conflictos
// window.addEventListener('load', () => {
//     startAutoRefresh();
// });

// Filter functionality
document.getElementById('statusFilter')?.addEventListener('change', applyFilters);
document.getElementById('priorityFilter')?.addEventListener('change', applyFilters);
document.getElementById('sortFilter')?.addEventListener('change', applyFilters);

// Agregar estilos de animación
const style = document.createElement('style');
style.textContent = `
    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
    @keyframes slideInRight {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
    @keyframes slideOutRight {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(100%); opacity: 0; }
    }
`;
document.head.appendChild(style);

// ============================================
// GESTIÓN DE TABS
// ============================================
function showTab(tabName) {
    const tabs = document.querySelectorAll('.tab-btn');
    tabs.forEach(tab => tab.classList.remove('active'));

    if (tabName === 'tickets') {
        document.getElementById('ticketsView').style.display = 'block';
        document.getElementById('usersView').style.display = 'none';
        tabs[0].classList.add('active');
        startAutoRefresh(); // Reiniciar auto-refresh en tickets
    } else if (tabName === 'users') {
        document.getElementById('ticketsView').style.display = 'none';
        document.getElementById('usersView').style.display = 'block';
        tabs[1].classList.add('active');
        stopAutoRefresh(); // Detener auto-refresh en usuarios
        loadUsers();
    }
}

// ============================================
// GESTIÓN DE USUARIOS
// ============================================
// ============================================
let allUsers = [];

function loadUsers() {
    fetch('/api/users/all', {
        credentials: 'include'
    })
        .then(response => {
            if (!response.ok) throw new Error('Error al cargar usuarios');
            return response.json();
        })
        .then(users => {
            allUsers = users;
            renderUsers();
        })
        .catch(error => {

            showToast('Error al cargar usuarios', 'error');
        });
}

function renderUsers() {
    const tbody = document.getElementById('usersTableBody');
    const isAdmin = currentUser && currentUser.role === 'administrador';
    const isGerencia = currentUser && currentUser.role === 'gerencia';

    tbody.innerHTML = allUsers.map(user => {
        const isProtectedUser = (user.role === 'administrador' || user.role === 'gerencia');
        const isDefaultAdmin = user.role === 'administrador' && user.email === 'admin@tiquetera.com';
        
        // Gerencia no puede modificar nada. 
        // Admin puede modificar todo excepto al admin por defecto y otros protegidos si no es necesario (logica original)
        // Ajustamos para que isAdmin sea la llave principal, y gerencia siempre false.
        // Habilitamos modificación para el admin por defecto para permitir cambio de contraseña (el backend protege campos críticos)
        const canModify = !isGerencia && (isAdmin || !isProtectedUser);

        return `
        <tr>
            <td>${user.id}</td>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td><span class="role-badge role-${user.role}">${getRoleLabel(user.role)}</span></td>
            <td>${user.department || '-'}</td>
            <td>${formatDate(user.created_at)}</td>
            <td>
                <div class="user-status-toggle">
                    <label class="switch">
                        <input type="checkbox" ${user.active ? 'checked' : ''} onchange="toggleUserActive(${user.id}, this.checked)" ${(!canModify || isDefaultAdmin) ? 'disabled' : ''}>
                        <span class="switch-slider" style="${(!canModify) ? 'cursor: not-allowed; opacity: 0.6;' : ''}"></span>
                    </label>
                    <span class="user-status-label ${user.active ? 'active' : 'inactive'}">
                        ${user.active ? 'Activo' : 'Inactivo'}
                    </span>
                </div>
            </td>
            <td>
                ${canModify ? `
                    <button class="btn-icon btn-edit" onclick="openEditUserModal(${user.id})" title="Editar">
                        ✏️
                    </button>
                    ${isAdmin ? `
                        <button class="btn-icon btn-key" onclick="openResetPasswordModal(${user.id}, '${user.name}')" title="Restablecer Contraseña">
                            🔑
                        </button>
                    ` : ''}
                ` : '<span style="color: #6c757d;">Protegido</span>'}
            </td>
        </tr>
        `;
    }).join('');
}

function getRoleLabel(role) {
    const labels = {
        'administrador': '👑 Administrador',
        'gerencia': '🎯 Gerencia',
        'support': '👥 Soporte',
        'facturacion': '💼 Facturación',
        'rrhh': '🏢 RRHH',
        'contact': '☎️ Contact'
    };
    return labels[role] || role;
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('es-ES', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

function openCreateUserModal() {
    editingUserId = null;
    document.getElementById('userModalTitle').textContent = '✨ Crear Nuevo Usuario';
    document.getElementById('userForm').reset();
    document.getElementById('userId').value = '';
    document.getElementById('passwordGroup').style.display = 'block';
    document.getElementById('userPassword').required = true;
    document.getElementById('userSubmitBtn').textContent = '✅ Crear Usuario';
    document.getElementById('userError').style.display = 'none';
    document.getElementById('userModal').style.display = 'block';
}

function openEditUserModal(userId) {
    editingUserId = userId;
    const user = allUsers.find(u => u.id === userId);
    if (!user) return;

    document.getElementById('userModalTitle').textContent = '✏️ Editar Usuario';
    document.getElementById('userId').value = user.id;
    document.getElementById('userName').value = user.name;
    document.getElementById('userEmail').value = user.email;
    document.getElementById('userRole').value = user.role;
    document.getElementById('userDepartment').value = user.department || '';
    document.getElementById('passwordGroup').style.display = 'none';
    document.getElementById('userPassword').required = false;
    document.getElementById('userSubmitBtn').textContent = '✅ Guardar Cambios';
    document.getElementById('userError').style.display = 'none';
    document.getElementById('userModal').style.display = 'block';
}

function closeUserModal() {
    document.getElementById('userModal').style.display = 'none';
    document.getElementById('userForm').reset();
    editingUserId = null;
}

// ============================================
// MODAL DE RESET PASSWORD
// ============================================

function openResetPasswordModal(userId, userName) {
    document.getElementById('resetUserId').value = userId;
    document.getElementById('resetUserName').value = userName;
    document.getElementById('newPassword').value = '';
    document.getElementById('confirmPassword').value = '';
    document.getElementById('resetPasswordError').style.display = 'none';
    document.getElementById('resetPasswordModal').style.display = 'flex';
}

function closeResetPasswordModal() {
    document.getElementById('resetPasswordModal').style.display = 'none';
    document.getElementById('resetPasswordForm').reset();
}

async function handleResetPassword(e) {
    e.preventDefault();

    const userId = document.getElementById('resetUserId').value;
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;
    const errorDiv = document.getElementById('resetPasswordError');
    const submitBtn = document.getElementById('resetPasswordSubmitBtn');

    // Validaciones
    if (newPassword.length < 6) {
        errorDiv.textContent = 'La contraseña debe tener al menos 6 caracteres';
        errorDiv.style.display = 'block';
        return;
    }

    if (newPassword !== confirmPassword) {
        errorDiv.textContent = 'Las contraseñas no coinciden';
        errorDiv.style.display = 'block';
        return;
    }

    errorDiv.style.display = 'none';
    submitBtn.disabled = true;
    submitBtn.textContent = '⏳ Cambiando...';

    try {
        const response = await fetch(`/api/users/${userId}/reset-password`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ newPassword })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Error al cambiar contraseña');
        }

        showToast('✅ Contraseña actualizada exitosamente', 'success');
        closeResetPasswordModal();

    } catch (error) {
        errorDiv.textContent = error.message;
        errorDiv.style.display = 'block';
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = '🔑 Cambiar Contraseña';
    }
}

// Form submit handler
document.getElementById('userForm').addEventListener('submit', async function (e) {
    e.preventDefault();

    const name = document.getElementById('userName').value.trim();
    const email = document.getElementById('userEmail').value.trim();
    const password = document.getElementById('userPassword').value.trim();
    const role = document.getElementById('userRole').value;
    const department = document.getElementById('userDepartment').value.trim();
    const errorDiv = document.getElementById('userError');
    const submitBtn = document.getElementById('userSubmitBtn');

    errorDiv.style.display = 'none';

    // VALIDACIONES FRONTEND
    if (!name) {
        errorDiv.textContent = 'El nombre es requerido';
        errorDiv.style.display = 'block';
        return;
    }

    if (!email || !email.includes('@')) {
        errorDiv.textContent = 'Email válido es requerido';
        errorDiv.style.display = 'block';
        return;
    }

    if (!editingUserId && !password) {
        errorDiv.textContent = 'La contraseña es requerida para crear usuario';
        errorDiv.style.display = 'block';
        return;
    }

    if (password && password.length < 6) {
        errorDiv.textContent = 'La contraseña debe tener al menos 6 caracteres';
        errorDiv.style.display = 'block';
        return;
    }

    if (!role) {
        errorDiv.textContent = 'El rol es requerido';
        errorDiv.style.display = 'block';
        return;
    }

    submitBtn.disabled = true;
    submitBtn.textContent = '⏳ Guardando...';

    try {
        const url = editingUserId ? `/api/users/${editingUserId}` : '/api/users';
        const method = editingUserId ? 'PUT' : 'POST';

        const body = { name, email, role, department };
        if (!editingUserId || password) {
            body.password = password;
        }

        const response = await fetch(url, {
            method,
            credentials: 'include',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        const data = await response.json();

        if (response.ok) {
            showToast(editingUserId ? 'Usuario actualizado exitosamente' : 'Usuario creado exitosamente', 'success');
            closeUserModal();
            // Recargar usuarios después de un breve delay
            setTimeout(() => loadUsers(), 300);
        } else {
            errorDiv.textContent = data.error || 'Error al guardar usuario';
            errorDiv.style.display = 'block';
        }
    } catch (error) {
        errorDiv.textContent = 'Error de conexión';
        errorDiv.style.display = 'block';
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = editingUserId ? '✅ Guardar Cambios' : '✅ Crear Usuario';
    }
});

async function toggleUserActive(userId, isActive) {
    try {
        const response = await fetch(`/api/users/${userId}`, {
            method: 'PUT',
            credentials: 'include',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ active: isActive })
        });

        const data = await response.json();

        if (response.ok) {
            showToast(isActive ? 'Usuario activado exitosamente' : 'Usuario desactivado exitosamente', 'success');
            loadUsers();
        } else {
            showToast(data.error || 'Error al actualizar estado del usuario', 'error');
        }
    } catch (error) {
        showToast('Error de conexión', 'error');
    }
}

// Lightbox universal provisto por core-panel.js (window.openLightbox / window.closeLightbox)

async function addComment() {
    const commentText = document.getElementById('commentText').value.trim();

    if (!commentText) {
        showToast('Por favor, escribe un comentario', 'error');
        return;
    }

    if (!currentTicketId) {
        showToast('❌ Error: No se ha seleccionado un ticket', 'error');
        return;
    }

    try {
        const response = await fetch(`/api/tickets/${currentTicketId}/updates`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                content: commentText,
                user_id: currentUser.id,
                update_type: 'comment'
            })
        });

        if (!response.ok) throw new Error('Error al agregar comentario');
        
        document.getElementById('commentText').value = '';
        showToast('✅ Comentario agregado exitosamente', 'success');
        
        // Refresh ticket details
        showTicketDetails(currentTicketId);
        
    } catch (error) {

        showToast('❌ Error al agregar comentario', 'error');
    }
}

function getRelativeTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('es-ES', {
        day: 'numeric',
        month: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
    }).replace(',', ' -');
}
