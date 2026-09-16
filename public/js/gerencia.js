// Check authentication on load
window.addEventListener('load', function () {
    window.verifySession(['gerencia'], function (user) {
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
                if (data.user.role !== 'gerencia') {
                    errorDiv.textContent = 'Acceso denegado. Solo gerencia puede acceder a este panel.';
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

let ticketScope = 'assigned'; // 'assigned' | 'all'

function changeTicketScope() {
    const scopeEl = document.getElementById('scopeFilter');
    if (scopeEl) {
        ticketScope = scopeEl.value || 'assigned';
    }
    const titleEl = document.getElementById('ticketsViewTitle');
    if (titleEl) {
        titleEl.textContent = ticketScope === 'assigned' 
            ? 'Tickets Asignados a Gerencia' 
            : 'Todos los Tickets del Sistema';
    }
    if (typeof currentPage !== 'undefined') currentPage = 1;
    loadTickets();
}

function loadTickets(silentRefresh = false) {
    if (isLoading && !silentRefresh) return;

    isLoading = true;

    if (!silentRefresh) {
        const listEl = document.getElementById('ticketsList');
        if (listEl) {
            listEl.innerHTML = '<div style="padding: 2rem; text-align: center; color: #667eea;"><div style="display: inline-block; width: 40px; height: 40px; border: 4px solid #f3f3f3; border-top: 4px solid #667eea; border-radius: 50%; animation: spin 1s linear infinite;"></div><p style="margin-top: 1rem;">Cargando tickets...</p></div>';
        }
    }

    const url = (ticketScope === 'assigned' && currentUser && currentUser.id)
        ? `/api/tickets/assigned/${currentUser.id}`
        : '/api/tickets';

    fetch(url, {
        credentials: 'include'
    })
        .then(response => {
            if (!response.ok) {
                throw new Error('Error al cargar tickets');
            }
            return response.json();
        })
        .then(data => {
            allTickets = Array.isArray(data) ? data : (data.tickets || []);
            applyFilters();
            updateStats();
            isLoading = false;

            const countBadge = document.getElementById('ticketsCountBadge');
            if (countBadge && Array.isArray(allTickets)) {
                const activeCount = allTickets.filter(t => t.status !== 'closed').length;
                countBadge.textContent = activeCount;
            }

            // Verificar si hay un ticket para abrir desde URL
            checkOpenTicketFromUrl();
        })
        .catch(error => {

            isLoading = false;
            if (error.message.includes('401') || error.message.includes('403')) {
                logout();
            } else if (!silentRefresh) {
                const listEl = document.getElementById('ticketsList');
                if (listEl) {
                    listEl.innerHTML = '<div style="padding: 2rem; text-align: center; color: #dc3545;">❌ Error al cargar tickets. <button onclick="loadTickets()" style="margin-top: 1rem; padding: 0.5rem 1rem; background: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer;">Reintentar</button></div>';
                }
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

function updateStats() {
    const total = filteredTickets.length;
    const open = filteredTickets.filter(t => t.status === 'open').length;
    const inProgress = filteredTickets.filter(t => t.status === 'in-progress').length;
    const closed = filteredTickets.filter(t => t.status === 'closed').length;

    const statsGrid = document.getElementById('statsGrid');
    statsGrid.innerHTML = `
        <div class="stat-card">
            <div class="stat-number">${total}</div>
            <div class="stat-label">Asignados</div>
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

let filteredTickets = [];
let searchTerm = '';
let activeTicketTab = 'open';
let tabPages = { open: 1, 'in-progress': 1, closed: 1 };

function renderTickets() {
    if (typeof window.renderTabbedTicketView === 'function') {
        window.renderTabbedTicketView('ticketsList', filteredTickets, activeTicketTab, tabPages, 'switchTicketTab', 'changeTabPage', false);
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
            showNotification(`✅ Estado cambiado a: ${statusText}`, 'success');

            // Mantener cache local sincronizada
            if (Array.isArray(allTickets)) {
                const idx = allTickets.findIndex(t => String(t.id) === String(ticketId));
                if (idx !== -1) {
                    allTickets[idx] = { ...allTickets[idx], ...data };
                }
            }

            // Actualizar modal si está Pendiente
            syncModalTicketState(data);

            loadTickets(true);
            if (typeof opts.onSuccess === 'function') {
                opts.onSuccess(data);
            }
        })
        .catch(error => {

            showNotification('❌ Error al actualizar el estado del ticket', 'error');
            if (typeof opts.onError === 'function') {
                opts.onError(error);
            }
        });
}

function getDepartmentStaffList(department) {
    const dept = (department || '').toLowerCase();
    if (dept.includes('mantenimiento')) {
        return ['Franco', 'Cristian'];
    }
    if (dept.includes('sistema') || dept.includes('soporte')) {
        return ['Rodolfo', 'Matias'];
    }
    if (dept.includes('gerencia')) {
        return ['Claudio F.', 'Enrique O.', 'Matias B.'];
    }
    // Si audita todas las áreas o general, mostrar todo el personal
    return ['Claudio F.', 'Enrique O.', 'Matias B.', 'Rodolfo', 'Matias', 'Franco', 'Cristian'];
}

function renderStaffOptions(department, currentVal) {
    const staffList = getDepartmentStaffList(department);
    return staffList.map(name => {
        const selected = (currentVal && currentVal.trim().toLowerCase() === name.toLowerCase()) ? 'selected' : '';
        return `<option value="${escapeHtml(name)}" ${selected}>${escapeHtml(name)}</option>`;
    }).join('');
}

async function handleModalTechnicianChange(ticketId, selectEl) {
    const newTechnician = selectEl.value ? selectEl.value.trim() : null;
    const helpEl = document.getElementById(`ticketTechnicianHelp-${ticketId}`);
    
    try {
        selectEl.disabled = true;
        const response = await fetch(`/api/tickets/${ticketId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ assigned_technician: newTechnician })
        });
        
        if (!response.ok) {
            const errData = await response.json();
            throw new Error(errData.error || 'Error al asignar responsable');
        }
        
        const updatedTicket = await response.json();
        
        // Actualizar cache local
        if (Array.isArray(allTickets)) {
            const idx = allTickets.findIndex(t => String(t.id) === String(ticketId));
            if (idx !== -1) {
                allTickets[idx] = { ...allTickets[idx], ...updatedTicket };
            }
        }
        
        selectEl.setAttribute('data-current-technician', newTechnician || '');
        if (helpEl) {
            helpEl.innerHTML = newTechnician 
                ? `Asignado a: <strong style="color: #4F46E5;">${escapeHtml(newTechnician)}</strong>` 
                : 'Sin responsable asignado';
        }
        
        showNotification(newTechnician ? `✅ Ticket asignado a: ${newTechnician}` : 'ℹ️ Asignación de personal removida', 'success');
        
        // Recargar comentarios para reflejar el cambio en la línea de tiempo
        loadTicketComments(ticketId);
        
        // Refrescar lista de tickets
        renderTickets();
    } catch (err) {
        console.error('Error al cambiar técnico:', err);
        showNotification(`❌ ${err.message}`, 'error');
        selectEl.value = selectEl.getAttribute('data-current-technician') || '';
        if (helpEl) {
            helpEl.textContent = 'Error al actualizar asignación';
            helpEl.style.color = '#dc3545';
        }
    } finally {
        selectEl.disabled = false;
    }
}

function showTicketDetails(ticketId) {
    currentTicketId = ticketId;
    const ticket = allTickets.find(t => t.id === ticketId);

    if (!ticket) return;

    const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;

    const modal = document.getElementById('ticketModal');
    const modalBody = document.getElementById('modalBody');

    // Procesar adjuntos
    let attachmentsHtml = '';
    try {
        let files = [];
        if (typeof ticket.attachments === 'string') {
            files = JSON.parse(ticket.attachments);
        } else if (Array.isArray(ticket.attachments)) {
            files = ticket.attachments;
        }
        if (files.length > 0) {
            attachmentsHtml = `
                <div class="detail-row">
                    <div class="detail-label">📎 Archivos Adjuntos</div>
                    <div class="attachment-gallery">
                        ${files.map(url => `
                            <div class="attachment-thumb-wrapper" onclick="openLightbox('${url}')">
                                <img src="${url}" alt="Adjunto" loading="lazy">
                            </div>
                        `).join('')}
                    </div>
                </div>
            `;
        }
    } catch(e) {}

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

        <!-- Estado y Prioridad (Grid) -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 15px 0;">
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label" style="margin-bottom: 8px;">📊 Estado</div>
                <span class="ticket-status status-${ticket.status}">${getStatusText(ticket.status)}</span>
            </div>
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label" style="margin-bottom: 8px;">⚠️ Prioridad</div>
                <span class="ticket-priority-pill priority-pill-${ticket.priority}">
                    ${ticket.priority === 'high' ? '🔴 Alta' : ticket.priority === 'medium' ? '🟡 Media' : '🟢 Baja'}
                </span>
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
                <div class="detail-label">🔧 Área / Usuario Asignado</div>
                <div class="detail-value" id="ticketAssignedTo-${ticket.id}">${escapeHtml(ticket.assigned_to_name || 'Sin asignar')}</div>
            </div>
            <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div class="detail-label" style="margin-bottom: 6px;">👤 Personal Asignado</div>
                <select id="ticketTechnicianSelect-${ticket.id}" 
                        data-current-technician="${escapeHtml(ticket.assigned_technician || '')}"
                        onchange="handleModalTechnicianChange(${ticket.id}, this)"
                        style="width: 100%; padding: 7px 10px; border: 1px solid #ced4da; border-radius: 6px; background: white; font-weight: 600; color: #1e293b;">
                    <option value="">-- Sin asignar --</option>
                    ${renderStaffOptions(ticket.department, ticket.assigned_technician)}
                </select>
                <small id="ticketTechnicianHelp-${ticket.id}" style="display:block; margin-top:4px; font-size:0.75em; color:#6c757d;">
                    ${ticket.assigned_technician ? `Asignado a: <strong style="color: #4F46E5;">${escapeHtml(ticket.assigned_technician)}</strong>` : 'Selecciona el responsable interno'}
                </small>
            </div>
        </div>

        <div class="detail-row" style="margin: 0 0 15px 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
            <div class="detail-label">📅 Fecha de Creación</div>
            <div class="detail-value">${new Date(ticket.created_at).toLocaleString('es-ES')}</div>
        </div>

        <!-- Attachments -->
        <div class="attachments-section" style="${(!ticket.attachments || ticket.attachments.length === 0) ? 'display:none;' : ''}; background: #f8f9fa; padding: 15px; border-radius: 8px; border: 1px solid #e9ecef; margin-top: 15px;">
            <h4 style="margin: 0 0 10px 0; font-size: 0.95em; color: #2c3e50;">📎 Archivos Adjuntos</h4>
            <div class="attachment-gallery" style="display: flex; gap: 10px; flex-wrap: wrap; margin-top: 10px;">
                ${
                    (function(){
                        let files = [];
                        try {
                            if (typeof ticket.attachments === 'string') {
                                files = JSON.parse(ticket.attachments);
                            } else if (Array.isArray(ticket.attachments)) {
                                files = ticket.attachments;
                            }
                        } catch(e) { }
                        return files.map(url => `
                            <div class="attachment-thumb-wrapper" onclick="openLightbox('${url}')" style="width: 60px; height: 60px; border-radius: 8px; overflow: hidden; cursor: pointer; border: 1px solid #dee2e6;">
                                <img src="${url}" alt="Adjunto" loading="lazy" style="width: 100%; height: 100%; object-fit: cover;">
                            </div>
                        `).join('');
                    })()
                }
            </div>
        </div>

        <!-- Modo Solo Lectura -->
        <div style="margin: 20px 0; padding: 15px; border-radius: 8px; background: #e3f2fd; border: 1px solid #90caf9;">
            <div style="font-weight: 600; color: #1565c0; display: flex; align-items: center; gap: 6px;">
                <span>👁️</span><span>Modo Solo Lectura</span>
            </div>
            <p style="margin: 8px 0 0 0; font-size: 0.9em; color: #1976d2;">El panel de gerencia permite visualizar tickets pero no modificarlos.</p>
        </div>

        <!-- Historial -->
        <div style="margin-top: 30px;">
            <h3 style="color: #2c3e50; border-bottom: 2px solid #e1e8ed; padding-bottom: 10px; margin-bottom: 20px;">📋 Historial</h3>
            <div id="commentsList" class="timeline">
                <div style="text-align:center; padding: 2rem; color: #6c757d;">
                    Cargando historial...
                </div>
            </div>
        </div>
    `;

    modal.style.display = 'block';
    loadTicketComments(ticketId);
}

function closeTicketModal() {
    document.getElementById('ticketModal').style.display = 'none';
}

function loadTicketComments(ticketId) {
    // Nota: Se asume que el backend devuelve un array de objetos con: content, user_name, created_at, update_type
    fetch(`/api/tickets/${ticketId}/updates`, {
    })
        .then(response => {
            if (!response.ok) {
                throw new Error('Error al cargar comentarios');
            }
            return response.json();
        })
        .then(comments => {
            const commentsList = document.getElementById('commentsList');

            if (comments.length === 0) {
                commentsList.innerHTML = `
                    <div style="text-align:center; padding:2rem; background:#f9fafb; border-radius:8px; color:#6b7280; font-style:italic;">
                        No hay actividad registrada en este ticket.
                    </div>
                `;
                return;
            }

            commentsList.innerHTML = comments.map(comment => {
                const isSystem = !comment.user_name || comment.user_name === 'Sistema';
                const isStatusChange = comment.update_type === 'status_change';
                const isPriorityChange = comment.update_type === 'priority_change';
                const isReopened = comment.content && comment.content.includes('🔓');
                const isClosed = comment.content && comment.content.includes('🔒');
                
                // Determinación del nombre a mostrar (Área o Usuario)
                let displayName = comment.user_name || 'Usuario';
                
                // Mapeo e roles a áreas
                const roleMap = {
                    'administrador': 'Administración',
                    'support': 'Soporte Técnico',
                    'compras': 'Compras',
                    'rrhh': 'RRHH',
                    'mantenimiento': 'Mantenimiento',
                    'facturacion': 'Facturación',
                    'gerencia': 'Gerencia'
                };

                // Si tenemos el rol, usamos el nombre del área
                if (comment.user_role && roleMap[comment.user_role]) {
                    displayName = roleMap[comment.user_role];
                } else if (comment.role && roleMap[comment.role]) {
                     displayName = roleMap[comment.role];
                }

                // Si es el propio usuario, alinear a la derecha (opcional, pero mejora UX)
                const isMe = (currentUser && String(comment.user_id) === String(currentUser.id));
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
                <div class="comment-item ${isMe ? 'comment-own' : ''}" style="display:flex; gap:12px; margin-bottom:16px; ${isMe ? 'flex-direction:row-reverse;' : ''}">
                    <div class="comment-avatar ${isSystem ? 'system' : ''}" style="width:36px; height:36px; border-radius:50%; background:${isSystem ? '#e9ecef' : (isMe ? '#4dabf7' : '#e9ecef')}; color:${isSystem ? '#495057' : (isMe ? '#fff' : '#495057')}; display:flex; align-items:center; justify-content:center; font-weight:bold; font-size:0.9em; flex-shrink:0;">
                        ${avatarLetter}
                    </div>
                    <div class="comment-body" style="background:${isSystem ? '#f8f9fa' : (isMe ? '#e7f5ff' : '#f1f3f5')}; padding:12px 16px; border-radius:12px; box-shadow:0 1px 2px rgba(0,0,0,0.05); max-width:85%; ${borderStyle}">
                        <div class="comment-header" style="margin-bottom:6px; display:flex; align-items:center; gap:8px; flex-wrap:wrap; justify-content:${isMe ? 'flex-end' : 'flex-start'};">
                            <span class="comment-author" style="font-weight:600; font-size:0.95em; color:#343a40;">
                                ${escapeHtml(displayName)}
                            </span>
                            ${badgeHtml}
                            <span class="comment-date" style="font-size:0.8em; color:#868e96;">${getRelativeTime(comment.created_at)}</span>
                        </div>
                        <div class="comment-text" style="color:#212529; line-height:1.5;">
                            ${escapeHtml(comment.content).replace(/\n/g, '<br>')}
                        </div>
                    </div>
                </div>
                `;
            }).join('');
        })
        .catch(error => {

            const listEl = document.getElementById('commentsList');
            if (listEl) {
                listEl.innerHTML = '<p style="color: #ef4444; text-align:center;">Error al cargar comentarios. Intenta recargar.</p>';
            }
        });
}





function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 25px;
        background: ${type === 'success' ? '#d4edda' : type === 'error' ? '#f8d7da' : '#d1ecf1'};
        color: ${type === 'success' ? '#155724' : type === 'error' ? '#721c24' : '#0c5460'};
        border: 1px solid ${type === 'success' ? '#c3e6cb' : type === 'error' ? '#f5c6cb' : '#bee5eb'};
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 10001;
        animation: slideInRight 0.3s ease;
        font-weight: 600;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.animation = 'slideOutRight 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

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

function getPriorityText(priority) {
    switch (priority) {
        case 'high': return 'Alta';
        case 'medium': return 'Media';
        case 'low': return 'Baja';
        default: return priority;
    }
}

// Búsqueda
document.getElementById('searchInput').addEventListener('input', function (e) {
    searchTerm = e.target.value.toLowerCase();
    applyFilters();
});

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
            showNotification(`✅ Prioridad cambiada a: ${priorityText}`, 'success');

            // Mantener cache local sincronizada
            if (Array.isArray(allTickets)) {
                const idx = allTickets.findIndex(t => String(t.id) === String(ticketId));
                if (idx !== -1) {
                    allTickets[idx] = { ...allTickets[idx], ...data };
                }
            }

            // Actualizar modal si está Pendiente
            syncModalTicketState(data);

            loadMyTickets(true);
            if (typeof opts.onSuccess === 'function') {
                opts.onSuccess(data);
            }
        })
        .catch(error => {

            showNotification('❌ Error al actualizar la prioridad', 'error');
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
    
    // Definir elementos de prioridad al inicio para evitar ReferenceError
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
            if (updatedTicket.status === 'closed') {
                statusHelp.textContent = 'Ticket cerrado. Puedes reabrirlo cambiando el estado.';
                statusHelp.style.color = '#6c757d';
            } else {
                statusHelp.textContent = 'Estado actualizado correctamente.';
                statusHelp.style.color = '#2F9E44';
            }
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

    if (typeof updatedTicket.assigned_technician !== 'undefined') {
        const techSelect = document.getElementById(`ticketTechnicianSelect-${ticketId}`);
        const techHelp = document.getElementById(`ticketTechnicianHelp-${ticketId}`);
        if (techSelect) {
            techSelect.value = updatedTicket.assigned_technician || '';
            techSelect.setAttribute('data-current-technician', updatedTicket.assigned_technician || '');
        }
        if (techHelp) {
            techHelp.innerHTML = updatedTicket.assigned_technician 
                ? `Asignado a: <strong style="color: #4F46E5;">${escapeHtml(updatedTicket.assigned_technician)}</strong>` 
                : 'Selecciona el responsable interno';
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
                updatedAtEl.textContent = new Date(updatedTicket.updated_at).toLocaleString('es-ES');
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
                loadTicketComments(ticketId);
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

function isNewTicket(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffHours = (now - date) / (1000 * 60 * 60);
    return diffHours < 24;
}



// Event listeners para dropdowns de prioridad
function attachPriorityListeners() {
    document.querySelectorAll('.priority-dropdown').forEach(dropdown => {
        dropdown.addEventListener('change', function (e) {
            e.stopPropagation();
            const ticketId = this.getAttribute('data-ticket-id');
            const priority = this.value;
            if (priority) {
                updateTicketPriority(ticketId, priority);
            }
        });
    });
}

// Filtros
document.getElementById('statusFilter')?.addEventListener('change', applyFilters);
document.getElementById('priorityFilter')?.addEventListener('change', applyFilters);
document.getElementById('sortFilter')?.addEventListener('change', applyFilters);

// Close modal when clicking outside
document.getElementById('ticketModal').addEventListener('click', function (e) {
    if (e.target === this) {
        closeTicketModal();
    }
});

// Lightbox Functions (Delegated to core-panel.js)
function openLightbox(url) {
    if (typeof window.openLightbox === 'function') {
        window.openLightbox(url);
    }
}

function closeLightbox(event) {
    if (typeof window.closeLightbox === 'function') {
        window.closeLightbox(event);
    }
}

// ============================================
// GERENCIA-SPECIFIC FUNCTIONS
// ============================================

// Tabs functionality
function showTab(tabName) {
    const ticketsView = document.getElementById('ticketsView');
    const usersView = document.getElementById('usersView');
    const tabBtns = document.querySelectorAll('.tab-btn');

    tabBtns.forEach(btn => btn.classList.remove('active'));

    if (tabName === 'tickets') {
        ticketsView.style.display = 'block';
        usersView.style.display = 'none';
        document.getElementById('tabTickets').classList.add('active');
    } else if (tabName === 'users') {
        ticketsView.style.display = 'none';
        usersView.style.display = 'block';
        document.getElementById('tabUsers').classList.add('active');
        loadUsers();
    }
}

// Load users
function loadUsers() {
    const tbody = document.getElementById('usersTableBody');
    
    if (!tbody) return;
    
    tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 2rem;">Cargando usuarios...</td></tr>';

    fetch('/api/users', {
        credentials: 'include'
    })
        .then(response => {
            if (!response.ok) throw new Error('Error al cargar usuarios');
            return response.json();
        })
        .then(users => {
            if (users.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 2rem;">No hay usuarios registrados</td></tr>';
                return;
            }

            tbody.innerHTML = users.map(user => `
                <tr>
                    <td>${user.id}</td>
                    <td>${escapeHtml(user.name)}</td>
                    <td>${escapeHtml(user.email)}</td>
                    <td><span class="role-badge role-${user.role}">${getRoleText(user.role)}</span></td>
                    <td>${escapeHtml(user.department || '-')}</td>
                    <td>${new Date(user.created_at).toLocaleDateString('es-ES')}</td>
                    <td>
                        <span class="user-status-label ${user.active !== false ? 'active' : 'inactive'}">
                            ${user.active !== false ? 'Activo' : 'Inactivo'}
                        </span>
                    </td>
                    <td>
                        <span style="color: #6c757d; font-style: italic;">Solo lectura</span>
                    </td>
                </tr>
            `).join('');
        })
        .catch(error => {

            tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 2rem; color: #dc3545;">Error al cargar usuarios</td></tr>';
        });
}

function getRoleText(role) {
    const roles = {
        'administrador': '👑 Administrador',
        'gerencia': '📊 Gerencia',
        'support': '👥 Soporte',
        'facturacion': '💼 Facturación',
        'rrhh': '🏢 RRHH',
        'contact': '☎️ Contact',
        'mantenimiento': '🔧 Mantenimiento',
        'compras': '🛒 Compras'
    };
    return roles[role] || role;
}

function closeUserModal() {
    const modal = document.getElementById('userModal');
    if (modal) modal.style.display = 'none';
}

// Additional event listeners for gerencia HTML elements
document.addEventListener('DOMContentLoaded', function() {
    // Tab buttons
    const tabTicketsBtn = document.getElementById('tabTicketsBtn');
    const tabTasksBtn = document.getElementById('tabTasksBtn');
    const tabUsersBtn = document.getElementById('tabUsersBtn');
    if (tabTicketsBtn) tabTicketsBtn.addEventListener('click', () => switchGerenciaTab('tickets'));
    if (tabTasksBtn) tabTasksBtn.addEventListener('click', () => switchGerenciaTab('tasks'));
    if (tabUsersBtn) tabUsersBtn.addEventListener('click', () => switchGerenciaTab('users'));
    const tabTickets = document.getElementById('tabTickets');
    const tabUsers = document.getElementById('tabUsers');
    if (tabTickets) tabTickets.addEventListener('click', () => switchGerenciaTab('tickets'));
    if (tabUsers) tabUsers.addEventListener('click', () => switchGerenciaTab('users'));

    // Logout button
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) logoutBtn.addEventListener('click', logout);

    // Close modal buttons
    const closeTicketModalBtn = document.getElementById('closeTicketModalBtn');
    if (closeTicketModalBtn) closeTicketModalBtn.addEventListener('click', closeTicketModal);

    const closeUserModalBtn = document.getElementById('closeUserModalBtn');
    if (closeUserModalBtn) closeUserModalBtn.addEventListener('click', closeUserModal);

    const cancelUserBtn = document.getElementById('cancelUserBtn');
    if (cancelUserBtn) cancelUserBtn.addEventListener('click', closeUserModal);

    // Password toggle
    const togglePasswordBtn = document.getElementById('togglePasswordBtn');
    if (togglePasswordBtn) {
        togglePasswordBtn.addEventListener('click', function() {
            togglePassword('loginPassword', this);
        });
    }

    // Lightbox
    const lightboxCloseBtn = document.getElementById('lightboxCloseBtn');
    if (lightboxCloseBtn) lightboxCloseBtn.addEventListener('click', closeLightbox);

    const imageLightbox = document.getElementById('imageLightbox');
    if (imageLightbox) imageLightbox.addEventListener('click', closeLightbox);

    // Additional filters for gerencia
    const monthFilter = document.getElementById('monthFilter');
    const yearFilter = document.getElementById('yearFilter');
    if (monthFilter) monthFilter.addEventListener('change', applyFilters);
    if (yearFilter) yearFilter.addEventListener('change', applyFilters);
});

function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text).then(() => {
            showNotification('📋 Copiado!', 'success');
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
            showNotification('📋 Copiado!', 'success');
        } else {
            showNotification('❌ Error al copiar', 'error');
        }
    } catch (err) {

        showNotification('❌ Error al copiar', 'error');
    }

    document.body.removeChild(textArea);
}

// =======================================================
// TABLERO DE TAREAS & CALENDARIO - GERENCIA
// =======================================================

let currentGerenciaTab = 'tickets';
let allGerenciaTasks = [];
let taskChecklistBuilderItems = [];
let taskSearchDebounceTimer = null;
let currentCalendarDate = new Date();
let currentCalendarView = 'month'; // 'month' | 'workweek' | 'week' | 'agenda'
let currentSelectedDayKey = null;
let currentEditingTaskId = null;
let activeRecurrenceDays = [];

function switchGerenciaTab(tab) {
    currentGerenciaTab = tab;
    const tabTicketsBtn = document.getElementById('tabTicketsBtn');
    const tabTasksBtn = document.getElementById('tabTasksBtn');
    const tabUsersBtn = document.getElementById('tabUsersBtn');
    const ticketsView = document.getElementById('ticketsView');
    const tasksView = document.getElementById('tasksView');
    const usersView = document.getElementById('usersView');

    if (tabTicketsBtn) tabTicketsBtn.classList.remove('active');
    if (tabTasksBtn) tabTasksBtn.classList.remove('active');
    if (tabUsersBtn) tabUsersBtn.classList.remove('active');
    if (ticketsView) ticketsView.style.display = 'none';
    if (tasksView) tasksView.style.display = 'none';
    if (usersView) usersView.style.display = 'none';

    if (tab === 'tickets') {
        if (tabTicketsBtn) tabTicketsBtn.classList.add('active');
        if (ticketsView) ticketsView.style.display = 'block';
        loadTickets();
    } else if (tab === 'tasks') {
        if (tabTasksBtn) tabTasksBtn.classList.add('active');
        if (tasksView) tasksView.style.display = 'block';
        loadGerenciaTasks();
        loadGerenciaTaskStats();
    } else if (tab === 'users') {
        if (tabUsersBtn) tabUsersBtn.classList.add('active');
        if (usersView) usersView.style.display = 'block';
        loadUsers();
    }
}

async function loadGerenciaTasks() {
    const status = document.getElementById('taskStatusFilter')?.value || '';
    const priority = document.getElementById('taskPriorityFilter')?.value || '';
    const category = document.getElementById('taskCategoryFilter')?.value || '';
    const sede = document.getElementById('taskSedeFilter')?.value || '';
    const technician = document.getElementById('taskTechnicianFilter')?.value || '';
    const isRecurring = document.getElementById('taskRecurrenceFilter')?.value || '';
    const search = document.getElementById('taskSearchInput')?.value || '';

    const params = new URLSearchParams();
    params.append('department', 'Gerencia');
    if (status) params.append('status', status);
    if (priority) params.append('priority', priority);
    if (category && category !== 'all') params.append('category', category);
    if (sede && sede !== 'all' && sede !== 'Todas') params.append('sede', sede);
    if (technician && technician !== 'all') {
        params.append('assigned_technician', technician === 'Sin asignar' ? 'unassigned' : technician);
    }
    if (isRecurring) params.append('is_recurring', isRecurring);
    if (search) params.append('search', search);

    try {
        const response = await fetch(`/api/maintenance/tasks?${params.toString()}`, {
            credentials: 'include',
            headers: { 'Accept': 'application/json' }
        });

        if (!response.ok) throw new Error('Error al cargar tareas de gerencia');
        const tasks = await response.json();
        allGerenciaTasks = tasks;

        const countBadge = document.getElementById('tasksCountBadge');
        if (countBadge) {
            const activeCount = tasks.filter(t => t.status !== 'completed').length;
            countBadge.textContent = activeCount;
        }

        renderCalendar();
    } catch (err) {
        console.error('Error al cargar tareas de gerencia:', err);
        const container = document.getElementById('calendarDaysMatrix');
        if (container) {
            container.innerHTML = `
                <div style="grid-column: 1 / -1; text-align: center; padding: 2rem; color: #EF4444; background: white;">
                    ❌ Error al cargar tareas: ${escapeHtml(err.message)}
                    <br><button onclick="loadGerenciaTasks()" style="margin-top: 10px; padding: 6px 14px; background: #4F46E5; color: white; border: none; border-radius: 6px; cursor: pointer;">Reintentar</button>
                </div>
            `;
        }
    }
}

async function loadGerenciaTaskStats() {
    try {
        const response = await fetch('/api/maintenance/tasks-stats?department=Gerencia', {
            credentials: 'include',
            headers: { 'Accept': 'application/json' }
        });
        if (!response.ok) return;
        const stats = await response.json();

        if (document.getElementById('taskKpiTotal')) document.getElementById('taskKpiTotal').textContent = stats.total || 0;
        if (document.getElementById('taskKpiPending')) document.getElementById('taskKpiPending').textContent = stats.pending || 0;
        if (document.getElementById('taskKpiInProgress')) document.getElementById('taskKpiInProgress').textContent = stats.in_progress || 0;
        if (document.getElementById('taskKpiCompleted')) document.getElementById('taskKpiCompleted').textContent = stats.completed || 0;
        if (document.getElementById('taskKpiRecurring')) document.getElementById('taskKpiRecurring').textContent = stats.recurring_count || 0;
    } catch (_) {}
}

function debounceTaskSearch() {
    clearTimeout(taskSearchDebounceTimer);
    taskSearchDebounceTimer = setTimeout(() => {
        loadGerenciaTasks();
    }, 300);
}

// =======================================================
// MOTOR CALENDARIO ESTILO GOOGLE CALENDAR (GERENCIA)
// =======================================================

function calendarGoToday() {
    currentCalendarDate = new Date();
    renderCalendar();
}

function calendarPrev() {
    if (currentCalendarView === 'week' || currentCalendarView === 'workweek') {
        currentCalendarDate.setDate(currentCalendarDate.getDate() - 7);
    } else {
        currentCalendarDate.setMonth(currentCalendarDate.getMonth() - 1);
    }
    renderCalendar();
}

function calendarNext() {
    if (currentCalendarView === 'week' || currentCalendarView === 'workweek') {
        currentCalendarDate.setDate(currentCalendarDate.getDate() + 7);
    } else {
        currentCalendarDate.setMonth(currentCalendarDate.getMonth() + 1);
    }
    renderCalendar();
}

function setCalendarView(view) {
    currentCalendarView = view;
    document.getElementById('btnViewMonth')?.classList.toggle('active', view === 'month');
    document.getElementById('btnViewWorkWeek')?.classList.toggle('active', view === 'workweek');
    document.getElementById('btnViewWeek')?.classList.toggle('active', view === 'week');
    document.getElementById('btnViewAgenda')?.classList.toggle('active', view === 'agenda');

    const monthCont = document.getElementById('calendarMonthContainer');
    const weekCont = document.getElementById('calendarWeekContainer');
    const agendaCont = document.getElementById('calendarAgendaContainer');

    if (monthCont) monthCont.style.display = view === 'month' ? 'block' : 'none';
    if (weekCont) weekCont.style.display = (view === 'week' || view === 'workweek') ? 'block' : 'none';
    if (agendaCont) agendaCont.style.display = view === 'agenda' ? 'block' : 'none';

    renderCalendar();
}

function renderCalendar() {
    updateCalendarHeaderTitle();

    if (currentCalendarView === 'month') {
        renderCalendarMonth();
    } else if (currentCalendarView === 'week' || currentCalendarView === 'workweek') {
        renderCalendarWeek();
    } else if (currentCalendarView === 'agenda') {
        renderCalendarAgenda();
    }
}

function updateCalendarHeaderTitle() {
    const titleEl = document.getElementById('calendarCurrentTitle');
    if (!titleEl) return;

    const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    const year = currentCalendarDate.getFullYear();
    const month = currentCalendarDate.getMonth();

    if (currentCalendarView === 'week' || currentCalendarView === 'workweek') {
        const monday = getMonday(currentCalendarDate);
        const daysSpan = currentCalendarView === 'workweek' ? 4 : 6;
        const endDay = new Date(monday);
        endDay.setDate(endDay.getDate() + daysSpan);
        titleEl.textContent = `${monday.getDate()} ${months[monday.getMonth()].substring(0, 3)} - ${endDay.getDate()} ${months[endDay.getMonth()]} ${year}`;
    } else {
        titleEl.textContent = `${months[month]} de ${year}`;
    }
}

function getMonday(d) {
    const date = new Date(d);
    const day = (date.getDay() + 6) % 7;
    date.setDate(date.getDate() - day);
    date.setHours(0, 0, 0, 0);
    return date;
}

function formatDateKey(dateObj) {
    const y = dateObj.getFullYear();
    const m = String(dateObj.getMonth() + 1).padStart(2, '0');
    const d = String(dateObj.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
}

function getTasksForDay(dateKey) {
    return allGerenciaTasks.filter(task => {
        const targetDate = task.due_date ? task.due_date.substring(0, 10) : (task.created_at ? task.created_at.substring(0, 10) : '');
        return targetDate === dateKey;
    });
}

function renderCalendarMonth() {
    const matrixContainer = document.getElementById('calendarDaysMatrix');
    if (!matrixContainer) return;

    const year = currentCalendarDate.getFullYear();
    const month = currentCalendarDate.getMonth();

    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);

    let startDay = (firstDay.getDay() + 6) % 7;
    const daysInPrevMonth = new Date(year, month, 0).getDate();
    const daysInMonth = lastDay.getDate();

    const todayStr = formatDateKey(new Date());
    let cellsHtml = '';

    for (let i = startDay - 1; i >= 0; i--) {
        const dayNum = daysInPrevMonth - i;
        const dObj = new Date(year, month - 1, dayNum);
        const dKey = formatDateKey(dObj);
        cellsHtml += renderCalendarCell(dKey, dayNum, true, todayStr);
    }

    for (let d = 1; d <= daysInMonth; d++) {
        const dObj = new Date(year, month, d);
        const dKey = formatDateKey(dObj);
        cellsHtml += renderCalendarCell(dKey, d, false, todayStr);
    }

    const totalCellsSoFar = startDay + daysInMonth;
    const remaining = (7 - (totalCellsSoFar % 7)) % 7;
    for (let nextDay = 1; nextDay <= remaining; nextDay++) {
        const dObj = new Date(year, month + 1, nextDay);
        const dKey = formatDateKey(dObj);
        cellsHtml += renderCalendarCell(dKey, nextDay, true, todayStr);
    }

    matrixContainer.innerHTML = cellsHtml;
}

function renderCalendarCell(dateKey, dayNum, isOtherMonth, todayStr) {
    const isToday = dateKey === todayStr;
    const tasks = getTasksForDay(dateKey);
    const MAX_VISIBLE = 3;
    const visibleTasks = tasks.slice(0, MAX_VISIBLE);
    const extraCount = tasks.length - MAX_VISIBLE;

    let tasksHtml = visibleTasks.map(task => {
        const isCompleted = task.status === 'completed';
        const priorityClass = `priority-${task.priority || 'medium'}`;
        const prefix = isCompleted ? '✓ ' : (task.is_recurring ? '🔁 ' : '');
        return `
            <div class="calendar-task-pill ${priorityClass} ${isCompleted ? 'completed' : ''}"
                 onclick="event.stopPropagation(); openTaskDetailModal(${task.id})"
                 title="${escapeHtml(task.title)}">
                <span class="pill-text">${prefix}${escapeHtml(task.title)}</span>
            </div>
        `;
    }).join('');

    if (extraCount > 0) {
        tasksHtml += `
            <div class="calendar-task-pill-more" onclick="event.stopPropagation(); openDayTasksModal('${dateKey}')">
                +${extraCount} más...
            </div>
        `;
    }

    return `
        <div class="calendar-day-cell ${isOtherMonth ? 'other-month' : ''} ${isToday ? 'today' : ''}"
             onclick="openDayTasksModal('${dateKey}')">
            <div class="calendar-day-cell-header">
                <span class="calendar-day-number ${isToday ? 'today-badge' : ''}">${dayNum}</span>
                ${tasks.length > 0 ? `<span class="calendar-day-count-badge">${tasks.length}</span>` : ''}
            </div>
            <div class="calendar-day-events">
                ${tasksHtml}
            </div>
        </div>
    `;
}

function renderCalendarWeek() {
    const matrix = document.getElementById('calendarWeekMatrix');
    if (!matrix) return;

    const monday = getMonday(currentCalendarDate);
    const isWorkWeek = currentCalendarView === 'workweek';
    const daysCount = isWorkWeek ? 5 : 7;
    const todayStr = formatDateKey(new Date());

    const dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    let colsHtml = '';

    for (let i = 0; i < daysCount; i++) {
        const dObj = new Date(monday);
        dObj.setDate(monday.getDate() + i);
        const dateKey = formatDateKey(dObj);
        const isToday = dateKey === todayStr;
        const tasks = getTasksForDay(dateKey);

        const tasksHtml = tasks.map(task => {
            const isCompleted = task.status === 'completed';
            const priorityClass = `priority-${task.priority || 'medium'}`;
            const checklist = Array.isArray(task.checklist) ? task.checklist : [];
            const metrics = task.checklistMetrics || { total: checklist.length, completed: checklist.filter(c => c.done).length };
            const checkInfo = checklist.length > 0 ? `✓ ${metrics.completed}/${metrics.total}` : '';

            return `
                <div class="week-task-card ${priorityClass} ${isCompleted ? 'completed' : ''}"
                     onclick="openTaskDetailModal(${task.id})">
                    <div style="font-weight: 600; font-size: 0.85rem; color: #1E293B; margin-bottom: 4px;">
                        ${isCompleted ? '✅ ' : (task.is_recurring ? '🔁 ' : '')}${escapeHtml(task.title)}
                    </div>
                    <div style="display: flex; gap: 4px; flex-wrap: wrap; font-size: 0.72rem;">
                        <span style="background: #E2E8F0; padding: 1px 6px; border-radius: 4px;">${escapeHtml(task.category || 'General')}</span>
                        ${task.assigned_technician ? `<span style="background: #EEF2FF; color: #4338CA; font-weight: 600; padding: 1px 6px; border-radius: 4px;">👤 ${escapeHtml(task.assigned_technician)}</span>` : ''}
                        ${checkInfo ? `<span style="background: #FEF3C7; color: #92400E; padding: 1px 6px; border-radius: 4px;">${checkInfo}</span>` : ''}
                    </div>
                </div>
            `;
        }).join('');

        colsHtml += `
            <div class="calendar-week-column ${isToday ? 'today-col' : ''}">
                <div class="calendar-week-col-header ${isToday ? 'today-header' : ''}">
                    <span class="week-day-name">${dayNames[i]}</span>
                    <span class="week-day-num ${isToday ? 'today-badge' : ''}">${dObj.getDate()}</span>
                </div>
                <div class="calendar-week-col-body" onclick="openDayTasksModal('${dateKey}')">
                    ${tasksHtml.length ? tasksHtml : '<div style="color: #94A3B8; font-size: 0.75rem; text-align: center; padding: 1rem;">Sin tareas</div>'}
                </div>
            </div>
        `;
    }

    matrix.innerHTML = colsHtml;
}

function renderCalendarAgenda() {
    const container = document.getElementById('calendarAgendaList');
    if (!container) return;

    if (!allGerenciaTasks || allGerenciaTasks.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; padding: 3rem; color: #64748B;">
                📋 No hay tareas registradas para Gerencia con los filtros aplicados.
                <br><button onclick="openTaskModal()" style="margin-top: 12px; padding: 8px 16px; background: #4F46E5; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600;">➕ Crear primera tarea</button>
            </div>
        `;
        return;
    }

    const grouped = {};
    allGerenciaTasks.forEach(task => {
        const dateKey = task.due_date ? task.due_date.substring(0, 10) : 'Sin fecha límite';
        if (!grouped[dateKey]) grouped[dateKey] = [];
        grouped[dateKey].push(task);
    });

    const sortedDates = Object.keys(grouped).sort();
    let agendaHtml = '';

    sortedDates.forEach(dateKey => {
        const tasks = grouped[dateKey];
        agendaHtml += `
            <div class="agenda-date-group">
                <div class="agenda-date-header">
                    📅 ${dateKey} (${tasks.length} ${tasks.length === 1 ? 'tarea' : 'tareas'})
                </div>
                <div class="agenda-tasks-list">
                    ${tasks.map(task => {
                        const isCompleted = task.status === 'completed';
                        const priorityClass = `priority-${task.priority || 'medium'}`;
                        const checklist = Array.isArray(task.checklist) ? task.checklist : [];
                        const metrics = task.checklistMetrics || { total: checklist.length, completed: checklist.filter(c => c.done).length };
                        const checkInfo = checklist.length > 0 ? `✓ ${metrics.completed}/${metrics.total} pasos` : '';

                        return `
                            <div class="agenda-task-item ${priorityClass} ${isCompleted ? 'completed' : ''}"
                                 onclick="openTaskDetailModal(${task.id})">
                                <div style="display: flex; justify-content: space-between; align-items: center;">
                                    <span style="font-weight: 700; font-size: 0.95rem; color: #1E293B;">
                                        ${isCompleted ? '✅ ' : (task.is_recurring ? '🔁 ' : '')}${escapeHtml(task.title)}
                                    </span>
                                    <span class="task-status-badge ${task.status}">${task.status === 'completed' ? 'Completada' : (task.status === 'in-progress' ? 'En Progreso' : 'Pendiente')}</span>
                                </div>
                                ${task.description ? `<p style="font-size: 0.82rem; color: #64748B; margin: 4px 0;">${escapeHtml(task.description)}</p>` : ''}
                                <div style="display: flex; gap: 8px; font-size: 0.75rem; margin-top: 6px; flex-wrap: wrap;">
                                    <span class="badge">🏢 ${escapeHtml(task.category || 'General')}</span>
                                    <span class="badge">📍 ${escapeHtml(task.sede || 'Todas')}</span>
                                    ${task.assigned_technician ? `<span class="badge" style="background: #EEF2FF; color: #4338CA; font-weight: 600;">👤 ${escapeHtml(task.assigned_technician)}</span>` : ''}
                                    ${checkInfo ? `<span class="badge checklist">${checkInfo}</span>` : ''}
                                </div>
                            </div>
                        `;
                    }).join('')}
                </div>
            </div>
        `;
    });

    container.innerHTML = agendaHtml;
}

// Day Tasks Modal
function openDayTasksModal(dateKey) {
    currentSelectedDayKey = dateKey;
    const modal = document.getElementById('dayTasksModalDialog');
    const title = document.getElementById('dayTasksModalTitle');
    const badge = document.getElementById('dayTasksModalBadge');
    const body = document.getElementById('dayTasksListBody');

    if (!modal) return;

    const tasks = getTasksForDay(dateKey);
    if (title) title.textContent = `📅 Tareas del ${dateKey}`;
    if (badge) badge.textContent = `${tasks.length} ${tasks.length === 1 ? 'tarea' : 'tareas'}`;

    if (body) {
        if (tasks.length === 0) {
            body.innerHTML = '<div style="text-align: center; color: #94A3B8; padding: 2rem;">No hay tareas para este día.</div>';
        } else {
            body.innerHTML = tasks.map(task => {
                const isCompleted = task.status === 'completed';
                const priorityClass = `priority-${task.priority || 'medium'}`;
                const checklist = Array.isArray(task.checklist) ? task.checklist : [];
                const metrics = task.checklistMetrics || { total: checklist.length, completed: checklist.filter(c => c.done).length };
                const checkInfo = checklist.length > 0 ? `✓ ${metrics.completed}/${metrics.total} pasos` : '';

                return `
                    <div class="day-task-item ${priorityClass} ${isCompleted ? 'status-completed' : ''}"
                         onclick="openTaskFromDayModal(${task.id})"
                         style="padding: 12px; border-radius: 8px; border: 1px solid #E2E8F0; margin-bottom: 8px; cursor: pointer; background: white;">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                            <span style="font-weight: 700; color: #1E293B;">${isCompleted ? '✅ ' : (task.is_recurring ? '🔁 ' : '')}${escapeHtml(task.title)}</span>
                            <span class="day-task-status-pill ${task.status}">${task.status === 'completed' ? 'Completada' : (task.status === 'in-progress' ? 'En Progreso' : 'Pendiente')}</span>
                        </div>
                        <div style="display: flex; gap: 6px; font-size: 0.75rem; flex-wrap: wrap;">
                            <span style="background: #F1F5F9; padding: 2px 6px; border-radius: 4px;">🏷️ ${escapeHtml(task.category || 'General')}</span>
                            <span style="background: #F1F5F9; padding: 2px 6px; border-radius: 4px;">📍 ${escapeHtml(task.sede || 'Todas')}</span>
                            ${checkInfo ? `<span style="background: #FEF3C7; color: #92400E; padding: 2px 6px; border-radius: 4px;">${checkInfo}</span>` : ''}
                        </div>
                    </div>
                `;
            }).join('');
        }
    }

    modal.style.display = 'flex';
}

function closeDayTasksModal() {
    const modal = document.getElementById('dayTasksModalDialog');
    if (modal) modal.style.display = 'none';
}

function handleDayTasksAddClick() {
    const targetDate = currentSelectedDayKey;
    closeDayTasksModal();
    openTaskModal(null, targetDate);
}

function openTaskFromDayModal(taskId) {
    closeDayTasksModal();
    openTaskDetailModal(taskId);
}

// =======================================================
// CREACIÓN / EDICIÓN DE TAREAS Y CHECKLIST
// =======================================================

function openTaskModal(taskToEdit = null, defaultDate = null) {
    currentEditingTaskId = taskToEdit ? taskToEdit.id : null;
    const modal = document.getElementById('taskModalDialog');
    const titleEl = document.getElementById('taskModalTitle');
    const form = document.getElementById('taskFormElement');

    if (!modal) return;

    if (taskToEdit) {
        if (titleEl) titleEl.textContent = '✏️ Editar Tarea de Gerencia';
        document.getElementById('taskIdInput').value = taskToEdit.id;
        document.getElementById('taskTitleInput').value = taskToEdit.title || '';
        document.getElementById('taskDescInput').value = taskToEdit.description || '';
        document.getElementById('taskCategoryInput').value = taskToEdit.category || 'General';
        document.getElementById('taskPriorityInput').value = taskToEdit.priority || 'medium';
        document.getElementById('taskSedeInput').value = taskToEdit.sede || 'Todas';
        const assignedInput = document.getElementById('taskAssignedToInput') || document.getElementById('taskAssignedTechnicianInput');
        if (assignedInput) assignedInput.value = taskToEdit.assigned_technician || '';
        document.getElementById('taskDueDateInput').value = taskToEdit.due_date ? taskToEdit.due_date.substring(0, 10) : '';

        const isRec = Boolean(taskToEdit.is_recurring);
        const recCheckbox = document.getElementById('taskIsRecurringInput');
        if (recCheckbox) {
            recCheckbox.checked = isRec;
            toggleRecurrenceOptions(isRec);
        }
        if (taskToEdit.recurrence_interval) {
            document.getElementById('taskRecurrenceIntervalInput').value = taskToEdit.recurrence_interval;
        }

        taskChecklistBuilderItems = Array.isArray(taskToEdit.checklist) ? [...taskToEdit.checklist] : [];
    } else {
        if (titleEl) titleEl.textContent = '➕ Nueva Tarea de Gerencia';
        if (form) form.reset();
        document.getElementById('taskIdInput').value = '';
        if (defaultDate) {
            document.getElementById('taskDueDateInput').value = defaultDate;
        }
        toggleRecurrenceOptions(false);
        taskChecklistBuilderItems = [];
    }

    renderChecklistBuilderList();
    modal.style.display = 'flex';
}

function closeTaskModal() {
    const modal = document.getElementById('taskModalDialog');
    if (modal) modal.style.display = 'none';
}

function toggleRecurrenceOptions(show) {
    const div = document.getElementById('recurrenceOptionsDiv');
    if (div) div.style.display = show ? 'block' : 'none';
}

function handleRecurrenceIntervalChange(val) {
    const customDaysDiv = document.getElementById('recurrenceCustomDaysDiv');
    if (customDaysDiv) customDaysDiv.style.display = val === 'custom_days' ? 'block' : 'none';
}

function setRecurrenceDaysPreset(preset) {
    if (preset === 'workweek') {
        activeRecurrenceDays = [1, 2, 3, 4, 5];
    } else if (preset === 'all') {
        activeRecurrenceDays = [0, 1, 2, 3, 4, 5, 6];
    } else {
        activeRecurrenceDays = [];
    }
    updateRecurrenceDaysPills();
}

function toggleRecurrenceDay(dayNum) {
    const idx = activeRecurrenceDays.indexOf(dayNum);
    if (idx === -1) activeRecurrenceDays.push(dayNum);
    else activeRecurrenceDays.splice(idx, 1);
    updateRecurrenceDaysPills();
}

function updateRecurrenceDaysPills() {
    document.querySelectorAll('#customDaysButtonsContainer .day-pill-btn').forEach(btn => {
        const d = parseInt(btn.getAttribute('data-day'), 10);
        btn.classList.toggle('active', activeRecurrenceDays.includes(d));
    });
}

function addChecklistItemBuilder() {
    const input = document.getElementById('newChecklistItemInput');
    if (!input) return;
    const text = input.value.trim();
    if (!text) return;

    taskChecklistBuilderItems.push({
        id: `chk_${Date.now()}_${taskChecklistBuilderItems.length}`,
        text: text,
        done: false
    });

    input.value = '';
    renderChecklistBuilderList();
}

function removeChecklistItemBuilder(index) {
    taskChecklistBuilderItems.splice(index, 1);
    renderChecklistBuilderList();
}

function renderChecklistBuilderList() {
    const listEl = document.getElementById('checklistBuilderList');
    const emptyMsg = document.getElementById('emptyChecklistMsg');
    if (!listEl) return;

    if (taskChecklistBuilderItems.length === 0) {
        if (emptyMsg) emptyMsg.style.display = 'block';
        listEl.innerHTML = '';
        return;
    }

    if (emptyMsg) emptyMsg.style.display = 'none';
    listEl.innerHTML = taskChecklistBuilderItems.map((item, idx) => `
        <div style="display: flex; justify-content: space-between; align-items: center; padding: 6px 10px; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 6px; margin-bottom: 6px;">
            <span style="font-size: 0.88rem; color: #1E293B;">${escapeHtml(item.text)}</span>
            <button type="button" onclick="removeChecklistItemBuilder(${idx})" style="background: none; border: none; color: #EF4444; font-weight: 700; cursor: pointer;">&times;</button>
        </div>
    `).join('');
}

async function handleSaveTask(event) {
    event.preventDefault();

    const taskId = document.getElementById('taskIdInput')?.value;
    const title = document.getElementById('taskTitleInput')?.value;
    const description = document.getElementById('taskDescInput')?.value;
    const category = document.getElementById('taskCategoryInput')?.value;
    const priority = document.getElementById('taskPriorityInput')?.value;
    const sede = document.getElementById('taskSedeInput')?.value;
    const assignedTechnician = document.getElementById('taskAssignedToInput')?.value || document.getElementById('taskAssignedTechnicianInput')?.value || null;
    const dueDate = document.getElementById('taskDueDateInput')?.value;
    const isRecurring = document.getElementById('taskIsRecurringInput')?.checked;
    const recurrenceInterval = document.getElementById('taskRecurrenceIntervalInput')?.value;

    const payload = {
        title,
        description,
        category,
        priority,
        department: 'Gerencia',
        sede,
        assigned_technician: assignedTechnician,
        due_date: dueDate || null,
        is_recurring: isRecurring,
        recurrence_interval: recurrenceInterval,
        checklist: taskChecklistBuilderItems
    };

    const isEdit = Boolean(taskId);
    const url = isEdit ? `/api/maintenance/tasks/${taskId}` : '/api/maintenance/tasks';
    const method = isEdit ? 'PUT' : 'POST';

    try {
        const response = await fetch(url, {
            method,
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            const errData = await response.json();
            throw new Error(errData.error || 'Error al guardar tarea');
        }

        closeTaskModal();
        showNotification(`✅ Tarea de Gerencia ${isEdit ? 'actualizada' : 'creada'} exitosamente`, 'success');
        loadGerenciaTasks();
        loadGerenciaTaskStats();
    } catch (err) {
        showNotification(`❌ Error: ${err.message}`, 'error');
    }
}

// =======================================================
// DETALLE DE TAREA Y ACCIONES (CHECKLIST, ESTADO, BORRADO)
// =======================================================

function openTaskDetailModal(taskId) {
    const task = allGerenciaTasks.find(t => String(t.id) === String(taskId));
    if (!task) return;

    const modal = document.getElementById('taskDetailModalDialog');
    const headerTitle = document.getElementById('taskDetailModalHeaderTitle');
    const body = document.getElementById('taskDetailBody');

    if (!modal || !body) return;

    if (headerTitle) headerTitle.textContent = `📋 ${task.title}`;

    const checklist = Array.isArray(task.checklist) ? task.checklist : [];
    const completedItems = checklist.filter(c => c.done).length;
    const totalItems = checklist.length;
    const percent = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : (task.status === 'completed' ? 100 : 0);

    body.innerHTML = `
        <div style="margin-bottom: 16px;">
            <div style="display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 12px;">
                <span class="badge priority-${task.priority || 'medium'}">Prioridad: ${task.priority || 'Media'}</span>
                <span class="badge">Categoría: ${escapeHtml(task.category || 'General')}</span>
                <span class="badge">Sede: ${escapeHtml(task.sede || 'Todas')}</span>
                <span class="badge" style="background: #EEF2FF; color: #4338CA; font-weight: 700;">👤 Asignado: ${escapeHtml(task.assigned_technician || 'Sin asignar')}</span>
                ${task.due_date ? `<span class="badge">📅 Vence: ${task.due_date.substring(0, 10)}</span>` : ''}
                ${task.is_recurring ? '<span class="badge">🔁 Rutina Recurrente</span>' : ''}
            </div>

            ${task.description ? `<p style="font-size: 0.95rem; color: #334155; line-height: 1.6; background: #F8FAFC; padding: 12px; border-radius: 8px; border: 1px solid #E2E8F0;">${escapeHtml(task.description)}</p>` : ''}
        </div>

        <div style="margin-bottom: 20px;">
            <label style="display: block; font-size: 0.85rem; font-weight: 700; color: #334155; margin-bottom: 6px;">Estado de la Tarea:</label>
            <div style="display: flex; gap: 10px;">
                <button type="button" onclick="changeTaskStatus(${task.id}, 'pending')" style="padding: 6px 12px; border-radius: 6px; border: 1px solid #CBD5E1; cursor: pointer; background: ${task.status === 'pending' ? '#FEF3C7' : 'white'}; font-weight: ${task.status === 'pending' ? '700' : '400'};">🟡 Pendiente</button>
                <button type="button" onclick="changeTaskStatus(${task.id}, 'in-progress')" style="padding: 6px 12px; border-radius: 6px; border: 1px solid #CBD5E1; cursor: pointer; background: ${task.status === 'in-progress' ? '#E0F2FE' : 'white'}; font-weight: ${task.status === 'in-progress' ? '700' : '400'};">🔵 En Progreso</button>
                <button type="button" onclick="changeTaskStatus(${task.id}, 'completed')" style="padding: 6px 12px; border-radius: 6px; border: 1px solid #CBD5E1; cursor: pointer; background: ${task.status === 'completed' ? '#DCFCE7' : 'white'}; font-weight: ${task.status === 'completed' ? '700' : '400'};">🟢 Completada</button>
            </div>
        </div>

        ${checklist.length > 0 ? `
            <div style="margin-bottom: 20px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                    <label style="font-size: 0.85rem; font-weight: 700; color: #334155;">Checklist (${completedItems}/${totalItems} completados - ${percent}%):</label>
                </div>
                <div style="background: #E2E8F0; height: 8px; border-radius: 4px; overflow: hidden; margin-bottom: 12px;">
                    <div style="background: #10B981; width: ${percent}%; height: 100%; transition: width 0.3s ease;"></div>
                </div>
                <div style="display: flex; flex-direction: column; gap: 8px;">
                    ${checklist.map(item => `
                        <label style="display: flex; align-items: center; gap: 10px; font-size: 0.9rem; color: #1E293B; cursor: pointer;">
                            <input type="checkbox" ${item.done ? 'checked' : ''} onchange="toggleChecklistItem(${task.id}, '${item.id}', this.checked)" style="width: 18px; height: 18px; accent-color: #10B981;">
                            <span style="${item.done ? 'text-decoration: line-through; color: #94A3B8;' : ''}">${escapeHtml(item.text)}</span>
                        </label>
                    `).join('')}
                </div>
            </div>
        ` : ''}

        <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #E2E8F0; padding-top: 16px; margin-top: 16px;">
            <button type="button" onclick="deleteTask(${task.id})" style="padding: 8px 14px; background: #FEE2E2; color: #DC2626; border: none; border-radius: 6px; font-weight: 600; cursor: pointer;">
                🗑️ Eliminar Tarea
            </button>
            <div style="display: flex; gap: 8px;">
                <button type="button" onclick="closeTaskDetailModal(); openTaskModal(allGerenciaTasks.find(t => t.id === ${task.id}))" style="padding: 8px 14px; background: #E2E8F0; color: #1E293B; border: none; border-radius: 6px; font-weight: 600; cursor: pointer;">
                    ✏️ Editar
                </button>
                <button type="button" onclick="closeTaskDetailModal()" style="padding: 8px 14px; background: #4F46E5; color: white; border: none; border-radius: 6px; font-weight: 600; cursor: pointer;">
                    Listo
                </button>
            </div>
        </div>
    `;

    modal.style.display = 'flex';
}

function closeTaskDetailModal() {
    const modal = document.getElementById('taskDetailModalDialog');
    if (modal) modal.style.display = 'none';
}

async function toggleChecklistItem(taskId, itemId, newDone) {
    try {
        const response = await fetch(`/api/maintenance/tasks/${taskId}/checklist/${itemId}`, {
            method: 'PATCH',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ done: newDone })
        });

        if (!response.ok) throw new Error('Error al actualizar ítem de checklist');
        const updatedTask = await response.json();

        const idx = allGerenciaTasks.findIndex(t => t.id === taskId);
        if (idx !== -1) allGerenciaTasks[idx] = updatedTask;

        renderCalendar();
        openTaskDetailModal(taskId);
    } catch (err) {
        showNotification(`❌ Error: ${err.message}`, 'error');
    }
}

async function changeTaskStatus(taskId, newStatus) {
    try {
        const response = await fetch(`/api/maintenance/tasks/${taskId}/status`, {
            method: 'PATCH',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: newStatus })
        });

        if (!response.ok) throw new Error('Error al cambiar estado');
        const updatedTask = await response.json();

        const idx = allGerenciaTasks.findIndex(t => t.id === taskId);
        if (idx !== -1) allGerenciaTasks[idx] = updatedTask;

        showNotification(`✅ Estado actualizado a ${newStatus === 'completed' ? 'Completada' : (newStatus === 'in-progress' ? 'En Progreso' : 'Pendiente')}`, 'success');
        loadGerenciaTasks();
        loadGerenciaTaskStats();
        closeTaskDetailModal();
    } catch (err) {
        showNotification(`❌ Error: ${err.message}`, 'error');
    }
}

function deleteTask(taskId) {
    showConfirmDialog({
        icon: '🗑️',
        title: '¿Eliminar Tarea?',
        message: '¿Estás seguro de que deseas eliminar permanentemente esta tarea de Gerencia?',
        confirmText: 'Sí, Eliminar',
        isDanger: true,
        onConfirm: async () => {
            try {
                const response = await fetch(`/api/maintenance/tasks/${taskId}`, {
                    method: 'DELETE',
                    credentials: 'include'
                });

                if (!response.ok) throw new Error('Error al eliminar tarea');
                showNotification('✅ Tarea eliminada exitosamente', 'success');
                closeTaskDetailModal();
                loadGerenciaTasks();
                loadGerenciaTaskStats();
            } catch (err) {
                showNotification(`❌ Error: ${err.message}`, 'error');
            }
        }
    });
}

// Confirmation Dialog helper
let currentConfirmCallback = null;

function showConfirmDialog({ icon = '⚠️', title = '¿Confirmar?', message = '¿Estás seguro?', confirmText = 'Confirmar', isDanger = true, onConfirm = null }) {
    const modal = document.getElementById('confirmActionModal');
    const iconEl = document.getElementById('confirmIcon');
    const titleEl = document.getElementById('confirmTitle');
    const msgEl = document.getElementById('confirmMessage');
    const btnEl = document.getElementById('confirmActionButton');

    if (!modal) return;
    if (iconEl) iconEl.textContent = icon;
    if (titleEl) titleEl.textContent = title;
    if (msgEl) msgEl.textContent = message;
    if (btnEl) {
        btnEl.textContent = confirmText;
        btnEl.style.background = isDanger ? '#DC2626' : '#4F46E5';
        currentConfirmCallback = onConfirm;
        btnEl.onclick = () => {
            closeConfirmModal();
            if (typeof currentConfirmCallback === 'function') currentConfirmCallback();
        };
    }

    modal.style.display = 'flex';
}

function closeConfirmModal() {
    const modal = document.getElementById('confirmActionModal');
    if (modal) modal.style.display = 'none';
}

// =======================================================
// EXPORTACIÓN A CSV Y COMPARTIR TABLERO
// =======================================================

function exportTasksToCSV() {
    if (!allGerenciaTasks || allGerenciaTasks.length === 0) {
        showNotification('⚠️ No hay tareas para exportar', 'warning');
        return;
    }

    const headers = ['ID', 'Título', 'Descripción', 'Estado', 'Prioridad', 'Categoría', 'Sede', 'Responsable', 'Vencimiento', 'Recurrente', 'Checklist Progreso', 'Fecha Creación'];
    const rows = allGerenciaTasks.map(t => {
        const checklist = Array.isArray(t.checklist) ? t.checklist : [];
        const completed = checklist.filter(c => c.done).length;
        const progress = checklist.length > 0 ? `${completed}/${checklist.length}` : (t.status === 'completed' ? '100%' : '0%');

        return [
            t.id,
            `"${(t.title || '').replace(/"/g, '""')}"`,
            `"${(t.description || '').replace(/"/g, '""')}"`,
            t.status,
            t.priority,
            t.category,
            t.sede,
            `"${(t.assigned_technician || '').replace(/"/g, '""')}"`,
            t.due_date ? t.due_date.substring(0, 10) : '',
            t.is_recurring ? 'Sí' : 'No',
            progress,
            t.created_at ? t.created_at.substring(0, 10) : ''
        ];
    });

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Tareas_Gerencia_${formatDateKey(new Date())}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}

function openShareTasksModal() {
    const modal = document.getElementById('shareTasksModalDialog');
    if (!modal) return;
    modal.style.display = 'flex';
    loadActiveTaskShareLinks();
}

function closeShareTasksModal() {
    const modal = document.getElementById('shareTasksModalDialog');
    if (modal) modal.style.display = 'none';
}

function toggleTaskShareCustomDates() {
    const select = document.getElementById('shareTaskPeriodSelect');
    const container = document.getElementById('taskShareCustomDatesContainer');
    if (select && container) {
        container.style.display = select.value === 'custom' ? 'block' : 'none';
    }
}

async function generateTaskShareLink() {
    const title = document.getElementById('shareTaskTitleInput')?.value;
    const period = document.getElementById('shareTaskPeriodSelect')?.value || '7d';
    const expireInDays = document.getElementById('shareTaskExpireSelect')?.value || 7;
    const startDate = document.getElementById('shareTaskCustomStart')?.value;
    const endDate = document.getElementById('shareTaskCustomEnd')?.value;

    try {
        const response = await fetch('/api/maintenance/tasks/share', {
            method: 'POST',
            credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                title,
                period,
                expireInDays,
                startDate,
                endDate,
                department: 'Gerencia'
            })
        });

        if (!response.ok) {
            const errData = await response.json();
            throw new Error(errData.error || 'Error al generar enlace');
        }

        const data = await response.json();
        const resultBox = document.getElementById('taskShareResultBox');
        const urlInput = document.getElementById('generatedTaskShareUrl');

        if (resultBox && urlInput) {
            urlInput.value = data.url;
            resultBox.style.display = 'block';
        }

        showNotification('🔗 Enlace público generado con éxito', 'success');
        loadActiveTaskShareLinks();
    } catch (err) {
        showNotification(`❌ Error: ${err.message}`, 'error');
    }
}

function copyGeneratedTaskShareUrl() {
    const urlInput = document.getElementById('generatedTaskShareUrl');
    if (urlInput && urlInput.value) {
        copyToClipboard(urlInput.value);
    }
}

async function loadActiveTaskShareLinks() {
    const container = document.getElementById('activeTaskShareLinksList');
    if (!container) return;

    try {
        const response = await fetch('/api/maintenance/tasks/share?department=Gerencia', {
            credentials: 'include'
        });

        if (!response.ok) throw new Error('Error al cargar enlaces');
        const links = await response.json();

        if (links.length === 0) {
            container.innerHTML = '<div style="color: #9CA3AF; font-size: 0.82rem; text-align: center; padding: 10px;">No hay enlaces compartidos activos.</div>';
            return;
        }

        const baseUrl = window.location.origin;
        container.innerHTML = links.map(l => {
            const shareUrl = `${baseUrl}/tareas/publico/${l.token}`;
            return `
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 8px 12px; background: white; border: 1px solid #E2E8F0; border-radius: 6px; margin-bottom: 6px;">
                    <div>
                        <div style="font-weight: 600; font-size: 0.85rem; color: #1E293B;">${escapeHtml(l.title || 'Tablero Compartido')}</div>
                        <div style="font-size: 0.75rem; color: #64748B;">Período: ${l.period} | Creado: ${l.created_at ? l.created_at.substring(0, 10) : ''}</div>
                    </div>
                    <div style="display: flex; gap: 6px;">
                        <button type="button" onclick="copyToClipboard('${shareUrl}')" style="padding: 4px 8px; background: #E2E8F0; border: none; border-radius: 4px; font-size: 0.78rem; cursor: pointer;">📋 Copiar</button>
                        <button type="button" onclick="deleteTaskShareLink('${l.token}')" style="padding: 4px 8px; background: #FEE2E2; color: #DC2626; border: none; border-radius: 4px; font-size: 0.78rem; cursor: pointer;">🗑️</button>
                    </div>
                </div>
            `;
        }).join('');
    } catch (err) {
        container.innerHTML = `<div style="color: #EF4444; font-size: 0.82rem; text-align: center;">Error al cargar enlaces: ${escapeHtml(err.message)}</div>`;
    }
}

async function deleteTaskShareLink(token) {
    try {
        const response = await fetch(`/api/maintenance/tasks/share/${token}`, {
            method: 'DELETE',
            credentials: 'include'
        });

        if (!response.ok) throw new Error('Error al eliminar enlace');
        showNotification('✅ Enlace revocado exitosamente', 'success');
        loadActiveTaskShareLinks();
    } catch (err) {
        showNotification(`❌ Error: ${err.message}`, 'error');
    }
}

