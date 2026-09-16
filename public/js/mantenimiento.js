        // Check authentication on load
        window.addEventListener('load', function () {
            window.verifySession(['mantenimiento', 'administrador', 'gerencia'], function (user) {
                currentUser = user;
                loadMyTickets();
                loadMaintenanceTaskStats();
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
                        if (data.user.role !== 'mantenimiento' && data.user.role !== 'administrador' && data.user.role !== 'gerencia') {
                            errorDiv.textContent = 'Acceso denegado. Solo personal de mantenimiento, administración o gerencia puede acceder.';
                            return;
                        }
                        currentUser = data.user;
                        document.getElementById('userName').textContent = currentUser.name;
                        hideLogin();
                        loadMyTickets();
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
                    loadMyTickets(true); // true = refresh silencioso
                }
            }, 30000);
        }

        function loadMyTickets(silentRefresh = false) {
            if (isLoading && !silentRefresh) return;

            isLoading = true;

            if (!silentRefresh) {
                document.getElementById('ticketsList').innerHTML = '<div style="padding: 2rem; text-align: center; color: #28a745;"><div style="display: inline-block; width: 40px; height: 40px; border: 4px solid #f3f3f3; border-top: 4px solid #28a745; border-radius: 50%; animation: spin 1s linear infinite;"></div><p style="margin-top: 1rem;">Cargando tickets...</p></div>';
            }

            fetch(`/api/tickets/assigned/${currentUser.id}`, {
            })
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

                    // Verificar si hay un ticket para abrir desde URL
                    checkOpenTicketFromUrl();
                })
                .catch(error => {

                    isLoading = false;
                    if (error.message.includes('401') || error.message.includes('403')) {
                        logout();
                    } else if (!silentRefresh) {
                        document.getElementById('ticketsList').innerHTML = '<div style="padding: 2rem; text-align: center; color: #dc3545;">❌ Error al cargar tickets. <button onclick="loadMyTickets()" style="margin-top: 1rem; padding: 0.5rem 1rem; background: #28a745; color: white; border: none; border-radius: 5px; cursor: pointer;">Reintentar</button></div>';
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

            const clientX = event.clientX;
            const clientY = event.clientY;
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

                    loadMyTickets(true);
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
                
                if (Array.isArray(allTickets)) {
                    const idx = allTickets.findIndex(t => String(t.id) === String(ticketId));
                    if (idx !== -1) {
                        allTickets[idx] = { ...allTickets[idx], ...updatedTicket };
                    }
                }
                
                selectEl.setAttribute('data-current-technician', newTechnician || '');
                if (helpEl) {
                    helpEl.innerHTML = newTechnician 
                        ? `Asignado a: <strong style="color: #7E22CE;">${escapeHtml(newTechnician)}</strong>` 
                        : 'Sin responsable asignado';
                }
                
                showNotification(newTechnician ? `✅ Ticket asignado a: ${newTechnician}` : 'ℹ️ Asignación de personal removida', 'success');
                
                loadTicketComments(ticketId);
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

        async function showTicketDetails(ticketId) {
            const ticket = allTickets.find(t => t.id === ticketId);
            if (!ticket) return;

            currentTicketId = ticketId;
            const modal = document.getElementById('ticketModal');
            const modalBody = document.getElementById('modalBody');

            const trackingId = ticket.tracking_id || `TKT-${String(ticket.id).padStart(5, '0')}`;

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
                                class="filter-select"
                                style="width: 100%; padding: 8px; border: 1px solid #ced4da; border-radius: 5px; background: white; font-weight: 500;"
                                ${ticket.status === 'closed' ? 'disabled' : ''}>
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
                                class="priority-dropdown"
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
                        <div class="detail-label">🏢 Sede</div>
                        <div class="detail-value" style="font-size: 1.1em; color: #0d6efd; font-weight: 600;">${escapeHtml(ticket.sede || 'No especificada')}</div>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 15px 0;">
                    <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                        <div class="detail-label">👤 Creado por</div>
                        <div class="detail-value">
                            ${escapeHtml(ticket.created_by_name || 'Anónimo')}<br>
                            <small style="color:#6c757d">${escapeHtml(ticket.created_by_email || '')}</small>
                        </div>
                    </div>
                    <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                        <div class="detail-label">🔧 Área Asignada</div>
                        <div class="detail-value" id="ticketAssignedTo-${ticket.id}">
                            ${escapeHtml(ticket.assigned_to_name || 'Sin asignar')}
                        </div>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin: 15px 0;">
                    <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                        <div class="detail-label" style="margin-bottom: 6px;">👤 Personal Asignado</div>
                        <select id="ticketTechnicianSelect-${ticket.id}" 
                                data-current-technician="${escapeHtml(ticket.assigned_technician || '')}"
                                onchange="handleModalTechnicianChange(${ticket.id}, this)"
                                style="width: 100%; padding: 7px 10px; border: 1px solid #ced4da; border-radius: 6px; background: white; font-weight: 600; color: #1e293b;">
                            <option value="">-- Sin asignar --</option>
                            <option value="Franco" ${ticket.assigned_technician === 'Franco' ? 'selected' : ''}>Franco</option>
                            <option value="Cristian" ${ticket.assigned_technician === 'Cristian' ? 'selected' : ''}>Cristian</option>
                        </select>
                        <small id="ticketTechnicianHelp-${ticket.id}" style="display:block; margin-top:4px; font-size:0.75em; color:#6c757d;">
                            ${ticket.assigned_technician ? `Asignado a: <strong style="color: #7E22CE;">${escapeHtml(ticket.assigned_technician)}</strong>` : 'Selecciona el técnico responsable'}
                        </small>
                    </div>
                    <div class="detail-row" style="margin: 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                        <div class="detail-label">📅 Fecha de Creación</div>
                        <div class="detail-value">${new Date(ticket.created_at).toLocaleString('es-ES')}</div>
                    </div>
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
                <div style="margin-top: 30px;">
                    <h3 style="color: #2c3e50; border-bottom: 2px solid #e1e8ed; padding-bottom: 10px; margin-bottom: 20px;">📋 Historial</h3>
                    <div id="commentsList" class="timeline">
                            <div style="text-align:center; padding:2rem; color:#6c757d;">
                            Cargando historial...
                        </div>
                    </div>
                </div>
            `;

            modal.style.display = 'flex';
            loadTicketComments(ticketId);
        }

        function closeTicketModal() {
            document.getElementById('ticketModal').style.display = 'none';
        }

        function loadTicketComments(ticketId) {
            fetch(`/api/tickets/${ticketId}/updates`, {
            })
            .then(response => {
                if (!response.ok) throw new Error('Error al cargar comentarios');
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

                    // Si es el propio usuario, alinear a la derecha
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

                document.getElementById('commentsList').innerHTML = '<p style="color: #dc3545;">Error al cargar comentarios</p>';
            });
        }



        function addComment() {
            const commentText = document.getElementById('commentText').value.trim();

            if (!commentText) {
                alert('Por favor, escribe un comentario');
                return;
            }

            fetch(`/api/tickets/${currentTicketId}/updates`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    content: commentText,
                    user_id: currentUser.id,
                    update_type: 'comment'
                })
            })
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Error al agregar comentario');
                    }
                    return response.json();
                })
                .then(data => {
                    document.getElementById('commentText').value = '';
                    showNotification('✅ Comentario agregado exitosamente', 'success');
                    loadTicketComments(currentTicketId);
                })
                .catch(error => {

                    showNotification('❌ Error al agregar comentario', 'error');
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
                        ? `Asignado a: <strong style="color: #7E22CE;">${escapeHtml(updatedTicket.assigned_technician)}</strong>` 
                        : 'Selecciona el técnico responsable';
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

        }

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

        // =======================================================
        // TABLERO DE TAREAS & CHECKLIST - MANTENIMIENTO
        // =======================================================

        let currentMaintTab = 'tickets';
        let allMaintenanceTasks = [];
        let taskChecklistBuilderItems = [];
        let taskSearchDebounceTimer = null;
        let currentCalendarDate = new Date();
        let currentCalendarView = 'month'; // 'month' | 'week' | 'agenda'

        function switchMaintTab(tab) {
            currentMaintTab = tab;
            const tabTicketsBtn = document.getElementById('tabTicketsBtn');
            const tabTasksBtn = document.getElementById('tabTasksBtn');
            const ticketsView = document.getElementById('ticketsView');
            const tasksView = document.getElementById('tasksView');

            if (tab === 'tickets') {
                tabTicketsBtn.classList.add('active');
                tabTasksBtn.classList.remove('active');
                ticketsView.style.display = 'block';
                tasksView.style.display = 'none';
            } else {
                tabTicketsBtn.classList.remove('active');
                tabTasksBtn.classList.add('active');
                ticketsView.style.display = 'none';
                tasksView.style.display = 'block';
                loadMaintenanceTasks();
                loadMaintenanceTaskStats();
            }
        }

        async function loadMaintenanceTasks() {
            const status = document.getElementById('taskStatusFilter')?.value || '';
            const priority = document.getElementById('taskPriorityFilter')?.value || '';
            const category = document.getElementById('taskCategoryFilter')?.value || '';
            const sede = document.getElementById('taskSedeFilter')?.value || '';
            const technician = document.getElementById('taskTechnicianFilter')?.value || '';
            const isRecurring = document.getElementById('taskRecurrenceFilter')?.value || '';
            const search = document.getElementById('taskSearchInput')?.value || '';

            const params = new URLSearchParams();
            if (status) params.append('status', status);
            if (priority) params.append('priority', priority);
            if (category) params.append('category', category);
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

                if (!response.ok) throw new Error('Error al cargar tareas');
                const tasks = await response.json();
                allMaintenanceTasks = tasks;

                const countBadge = document.getElementById('tasksCountBadge');
                if (countBadge) {
                    const activeCount = tasks.filter(t => t.status !== 'completed').length;
                    countBadge.textContent = activeCount;
                }

                renderCalendar();
            } catch (err) {
                console.error('Error al cargar tareas:', err);
                const container = document.getElementById('calendarDaysMatrix');
                if (container) {
                    container.innerHTML = `
                        <div style="grid-column: 1 / -1; text-align: center; padding: 2rem; color: #EF4444; background: white;">
                            ❌ Error al cargar tareas de mantenimiento: ${escapeHtml(err.message)}
                            <br><button onclick="loadMaintenanceTasks()" style="margin-top: 10px; padding: 6px 14px; background: #008B8B; color: white; border: none; border-radius: 6px; cursor: pointer;">Reintentar</button>
                        </div>
                    `;
                }
            }
        }

        async function loadMaintenanceTaskStats() {
            try {
                const response = await fetch('/api/maintenance/tasks-stats', {
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

        // =======================================================
        // MOTOR DE RENDERIZADO ESTILO GOOGLE CALENDAR
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
            return allMaintenanceTasks.filter(task => {
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

            let startDay = (firstDay.getDay() + 6) % 7; // Lunes = 0, Domingo = 6
            const daysInPrevMonth = new Date(year, month, 0).getDate();
            const daysInMonth = lastDay.getDate();

            const todayStr = formatDateKey(new Date());
            let cellsHtml = '';

            // Días previos del mes anterior
            for (let i = startDay - 1; i >= 0; i--) {
                const dayNum = daysInPrevMonth - i;
                const prevDate = new Date(year, month - 1, dayNum);
                const dateKey = formatDateKey(prevDate);
                const isToday = dateKey === todayStr;
                const dayTasks = getTasksForDay(dateKey);

                cellsHtml += `
                    <div class="calendar-day-cell other-month ${isToday ? 'today' : ''}" onclick="openDayTasksModal('${dateKey}')">
                        <div class="day-cell-top">
                            <span class="day-number">${dayNum}</span>
                            <button type="button" class="day-add-btn" onclick="event.stopPropagation(); openTaskModal(null, '${dateKey}');" title="Nueva tarea para este día" aria-label="Nueva tarea para el día ${dayNum}">
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                            </button>
                        </div>
                        <div class="day-events-list">
                            ${renderEventPills(dayTasks)}
                        </div>
                    </div>
                `;
            }

            // Días del mes actual
            for (let dayNum = 1; dayNum <= daysInMonth; dayNum++) {
                const currDate = new Date(year, month, dayNum);
                const dateKey = formatDateKey(currDate);
                const isToday = dateKey === todayStr;
                const dayTasks = getTasksForDay(dateKey);

                cellsHtml += `
                    <div class="calendar-day-cell ${isToday ? 'today' : ''}" onclick="openDayTasksModal('${dateKey}')">
                        <div class="day-cell-top">
                            <span class="day-number">${dayNum}</span>
                            <button type="button" class="day-add-btn" onclick="event.stopPropagation(); openTaskModal(null, '${dateKey}');" title="Nueva tarea para este día" aria-label="Nueva tarea para el día ${dayNum}">
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                            </button>
                        </div>
                        <div class="day-events-list">
                            ${renderEventPills(dayTasks)}
                        </div>
                    </div>
                `;
            }

            // Días posteriores del mes siguiente para completar la cuadrícula (35 o 42 celdas)
            const totalCells = startDay + daysInMonth;
            const remainingCells = (totalCells > 35 ? 42 : 35) - totalCells;
            for (let dayNum = 1; dayNum <= remainingCells; dayNum++) {
                const nextDate = new Date(year, month + 1, dayNum);
                const dateKey = formatDateKey(nextDate);
                const isToday = dateKey === todayStr;
                const dayTasks = getTasksForDay(dateKey);

                cellsHtml += `
                    <div class="calendar-day-cell other-month ${isToday ? 'today' : ''}" onclick="openDayTasksModal('${dateKey}')">
                        <div class="day-cell-top">
                            <span class="day-number">${dayNum}</span>
                            <button type="button" class="day-add-btn" onclick="event.stopPropagation(); openTaskModal(null, '${dateKey}');" title="Nueva tarea para este día" aria-label="Nueva tarea para el día ${dayNum}">
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                            </button>
                        </div>
                        <div class="day-events-list">
                            ${renderEventPills(dayTasks)}
                        </div>
                    </div>
                `;
            }

            matrixContainer.innerHTML = cellsHtml;
        }

        function renderEventPills(tasks) {
            if (!Array.isArray(tasks) || tasks.length === 0) return '';

            return tasks.map(task => {
                const isCompleted = task.status === 'completed';
                const priorityClass = `priority-${task.priority || 'medium'}`;
                const checklist = Array.isArray(task.checklist) ? task.checklist : [];
                const metrics = task.checklistMetrics || { total: checklist.length, completed: 0 };
                const checkInfo = checklist.length > 0 ? `✓${metrics.completed}/${metrics.total}` : '';

                const rawTitle = task.title || 'Tarea';
                const prefix = isCompleted ? '✅ ' : (task.is_recurring ? '🔁 ' : '');
                // Limitar a 15 caracteres para no desbordar la cuadrícula
                const displayTitle = rawTitle.length > 15 ? rawTitle.substring(0, 15) + '...' : rawTitle;

                return `
                    <div class="calendar-event-pill ${priorityClass} ${isCompleted ? 'status-completed' : ''}" 
                         onclick="event.stopPropagation(); openTaskDetailModal(${task.id});"
                         title="${isCompleted ? '[COMPLETADA] ' : ''}${escapeHtml(rawTitle)} (${escapeHtml(task.category || 'General')}) - Clic para ver detalles">
                        <span class="event-pill-title">${prefix}${escapeHtml(displayTitle)}</span>
                        ${checkInfo ? `<span class="event-pill-badge">${checkInfo}</span>` : ''}
                    </div>
                `;
            }).join('');
        }

        function renderCalendarWeek() {
            const weekContainer = document.getElementById('calendarWeekMatrix');
            if (!weekContainer) return;

            const isWorkWeek = currentCalendarView === 'workweek';
            weekContainer.classList.toggle('workweek-grid', isWorkWeek);

            const monday = getMonday(currentCalendarDate);
            const todayStr = formatDateKey(new Date());
            const dayNames = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
            const daysCount = isWorkWeek ? 5 : 7;
            let colsHtml = '';

            for (let i = 0; i < daysCount; i++) {
                const d = new Date(monday);
                d.setDate(d.getDate() + i);
                const dateKey = formatDateKey(d);
                const isToday = dateKey === todayStr;
                const dayTasks = getTasksForDay(dateKey);

                colsHtml += `
                    <div class="calendar-week-col ${isToday ? 'today' : ''}">
                        <div class="week-col-header" onclick="openDayTasksModal('${dateKey}')" title="Ver tareas del día ${d.getDate()}">
                            <span class="week-col-name">${dayNames[i]}</span>
                            <span class="week-col-num">${d.getDate()}</span>
                        </div>
                        <div class="week-col-events" onclick="openDayTasksModal('${dateKey}')">
                            ${renderEventCards(dayTasks)}
                        </div>
                    </div>
                `;
            }

            weekContainer.innerHTML = colsHtml;
        }

        function renderEventCards(tasks) {
            if (!Array.isArray(tasks) || tasks.length === 0) {
                return `<div class="empty-day-msg">Sin tareas</div>`;
            }

            return tasks.map(task => {
                const isCompleted = task.status === 'completed';
                const priorityClass = `priority-${task.priority || 'medium'}`;
                const checklist = Array.isArray(task.checklist) ? task.checklist : [];
                const metrics = task.checklistMetrics || { total: checklist.length, completed: 0 };
                const checkInfo = checklist.length > 0 ? `✓ ${metrics.completed}/${metrics.total} pasos` : '';

                return `
                    <div class="calendar-week-card ${priorityClass} ${isCompleted ? 'status-completed' : ''}"
                         onclick="event.stopPropagation(); openTaskDetailModal(${task.id});"
                         title="${isCompleted ? '[COMPLETADA] ' : ''}${escapeHtml(task.title)} (${escapeHtml(task.category || 'General')}) - Sede: ${escapeHtml(task.sede || 'Todas')}">
                        <div class="card-top-line">
                            <span class="card-category">${escapeHtml(task.category || 'General')}</span>
                            ${task.is_recurring ? '<span class="card-recurring-icon" title="Rutina Recurrente">🔁</span>' : ''}
                        </div>
                        <div class="card-title">${escapeHtml(task.title)}</div>
                        <div class="card-footer-info">
                            <span class="card-sede">📍 ${escapeHtml(task.sede || 'Todas')}</span>
                            ${checkInfo ? `<span class="card-check-info">${checkInfo}</span>` : ''}
                        </div>
                    </div>
                `;
            }).join('');
        }

        function renderCalendarAgenda() {
            const agendaContainer = document.getElementById('calendarAgendaList');
            if (!agendaContainer) return;

            if (allMaintenanceTasks.length === 0) {
                agendaContainer.innerHTML = `
                    <div class="calendar-agenda-empty">
                        <div style="font-size: 3rem; margin-bottom: 10px;">📋</div>
                        <h3>No hay tareas programadas con los filtros actuales</h3>
                        <p>Haz clic en "➕ Nueva Tarea" para programar una rutina de mantenimiento.</p>
                        <button onclick="openTaskModal()" style="margin-top: 15px; padding: 8px 18px; background: #008B8B; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer;">
                            ➕ Programar Tarea
                        </button>
                    </div>
                `;
                return;
            }

            // Agrupar tareas por fecha
            const grouped = {};
            allMaintenanceTasks.forEach(task => {
                const dateKey = task.due_date ? task.due_date.substring(0, 10) : 'Sin Fecha';
                if (!grouped[dateKey]) grouped[dateKey] = [];
                grouped[dateKey].push(task);
            });

            // Ordenar fechas
            const sortedDates = Object.keys(grouped).sort();
            const todayStr = formatDateKey(new Date());

            let agendaHtml = '';
            sortedDates.forEach(dateKey => {
                const tasks = grouped[dateKey];
                let dateLabel = dateKey;
                if (dateKey !== 'Sin Fecha') {
                    const parts = dateKey.split('-');
                    const d = new Date(parts[0], parseInt(parts[1], 10) - 1, parts[2]);
                    dateLabel = d.toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
                    dateLabel = dateLabel.charAt(0).toUpperCase() + dateLabel.slice(1);
                    if (dateKey === todayStr) {
                        dateLabel = `⭐ Hoy - ${dateLabel}`;
                    }
                } else {
                    dateLabel = '📅 Tareas sin fecha límite';
                }

                agendaHtml += `
                    <div class="agenda-group">
                        <div class="agenda-group-header">
                            <span>📅 ${dateLabel}</span>
                            <span class="agenda-count-badge">${tasks.length} ${tasks.length === 1 ? 'tarea' : 'tareas'}</span>
                        </div>
                        <div class="agenda-group-cards">
                            ${tasks.map(task => {
                                const isCompleted = task.status === 'completed';
                                const priorityClass = `priority-${task.priority || 'medium'}`;
                                const checklist = Array.isArray(task.checklist) ? task.checklist : [];
                                const metrics = task.checklistMetrics || { total: checklist.length, completed: 0, percent: 0 };
                                const percent = metrics.percent || 0;

                                return `
                                    <div class="agenda-task-item ${priorityClass} ${isCompleted ? 'status-completed' : ''}" onclick="openTaskDetailModal(${task.id})">
                                        <div class="agenda-item-left">
                                            <div class="agenda-item-title">
                                                ${task.is_recurring ? '🔁 ' : ''}${escapeHtml(task.title)}
                                            </div>
                                            ${task.description ? `<div class="agenda-item-desc">${escapeHtml(task.description)}</div>` : ''}
                                            <div class="agenda-item-meta">
                                                <span class="agenda-badge-cat">🏢 ${escapeHtml(task.category || 'General')}</span>
                                                <span class="agenda-badge-sede">📍 ${escapeHtml(task.sede || 'Todas')}</span>
                                                ${task.assigned_technician ? `<span class="agenda-badge-tech">👤 ${escapeHtml(task.assigned_technician)}</span>` : ''}
                                                ${checklist.length > 0 ? `<span class="agenda-badge-chk">✓ ${metrics.completed}/${metrics.total} pasos (${percent}%)</span>` : ''}
                                                <span class="agenda-badge-status status-${task.status}">${task.status === 'completed' ? '🟢 Completada' : (task.status === 'in-progress' ? '🔵 En Progreso' : '🟡 Pendiente')}</span>
                                            </div>
                                        </div>
                                        <div class="agenda-item-right" onclick="event.stopPropagation();">
                                            <select class="task-status-select" onchange="changeTaskStatus(${task.id}, this.value)" title="Cambiar estado">
                                                <option value="pending" ${task.status === 'pending' ? 'selected' : ''}>🟡 Pendiente</option>
                                                <option value="in-progress" ${task.status === 'in-progress' ? 'selected' : ''}>🔵 En Progreso</option>
                                                <option value="completed" ${task.status === 'completed' ? 'selected' : ''}>🟢 Completada</option>
                                            </select>
                                            <button class="btn-agenda-view" onclick='openTaskDetailModal(${task.id})' title="Ver detalles y checklist">
                                                Ver Detalle ➔
                                            </button>
                                            <button class="btn-task-icon delete" onclick="confirmDeleteTask(${task.id})" title="Eliminar tarea">🗑️</button>
                                        </div>
                                    </div>
                                `;
                            }).join('')}
                        </div>
                    </div>
                `;
            });

            agendaContainer.innerHTML = agendaHtml;
        }

        function debounceTaskSearch() {
            if (taskSearchDebounceTimer) clearTimeout(taskSearchDebounceTimer);
            taskSearchDebounceTimer = setTimeout(() => {
                loadMaintenanceTasks();
            }, 300);
        }

        async function toggleChecklistItem(taskId, itemId, currentDone) {
            try {
                const response = await fetch(`/api/maintenance/tasks/${taskId}/checklist/${itemId}`, {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    credentials: 'include',
                    body: JSON.stringify({ done: !currentDone })
                });

                if (!response.ok) throw new Error('Error al actualizar ítem');
                const result = await response.json();

                if (result.checklistMetrics && result.checklistMetrics.allDone) {
                    if (typeof window.showToast === 'function') {
                        window.showToast('🎉 ¡Todos los ítems del checklist completados!', 'success');
                    }
                }

                loadMaintenanceTasks();
                loadMaintenanceTaskStats();
            } catch (err) {
                if (typeof window.showToast === 'function') {
                    window.showToast(err.message, 'error');
                } else {
                    alert(err.message);
                }
            }
        }

        const pendingTaskStatusUpdates = new Set();

        async function changeTaskStatus(taskId, newStatus) {
            if (pendingTaskStatusUpdates.has(taskId)) return;
            pendingTaskStatusUpdates.add(taskId);
            try {
                const response = await fetch(`/api/maintenance/tasks/${taskId}/status`, {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    credentials: 'include',
                    body: JSON.stringify({ status: newStatus })
                });

                if (!response.ok) throw new Error('Error al cambiar estado');
                const result = await response.json();

                if (result.isRecurringCycleReset) {
                    if (typeof window.showToast === 'function') {
                        window.showToast('🎉 ¡Ciclo completado! Tarea renovada y programada para el próximo vencimiento.', 'success');
                    }
                } else if (newStatus === 'completed') {
                    if (typeof window.showToast === 'function') {
                        window.showToast('✅ Tarea marcada como completada.', 'success');
                    }
                } else {
                    if (typeof window.showToast === 'function') {
                        window.showToast('↩️ Tarea reabierta.', 'info');
                    }
                }

                loadMaintenanceTasks();
                loadMaintenanceTaskStats();
            } catch (err) {
                if (typeof window.showToast === 'function') {
                    window.showToast(err.message, 'error');
                } else {
                    alert(err.message);
                }
            } finally {
                pendingTaskStatusUpdates.delete(taskId);
            }
        }

        // =======================================================
        // MODAL DE TAREAS DEL DÍA (MANTENIMIENTO)
        // =======================================================

        let currentSelectedDayKey = null;

        function formatDayTitleSpanish(dateKey) {
            if (!dateKey) return '';
            const [y, m, d] = dateKey.split('-').map(Number);
            const dateObj = new Date(y, m - 1, d);
            const dayNames = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
            const monthNames = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
            const dayName = dayNames[dateObj.getDay()];
            const monthName = monthNames[m - 1];
            return `${dayName}, ${d} de ${monthName} de ${y}`;
        }

        function openDayTasksModal(dateKey) {
            currentSelectedDayKey = dateKey;
            const modal = document.getElementById('dayTasksModalDialog');
            const titleEl = document.getElementById('dayTasksModalTitle');
            const badgeEl = document.getElementById('dayTasksModalBadge');
            const bodyEl = document.getElementById('dayTasksListBody');
            if (!modal || !bodyEl) return;

            const formattedTitle = formatDayTitleSpanish(dateKey);
            if (titleEl) {
                titleEl.textContent = `📅 ${formattedTitle}`;
            }

            const dayTasks = getTasksForDay(dateKey);
            const count = dayTasks.length;

            if (badgeEl) {
                badgeEl.textContent = `${count} ${count === 1 ? 'tarea' : 'tareas'}`;
                badgeEl.style.background = count > 0 ? '#E0F2FE' : '#F1F5F9';
                badgeEl.style.color = count > 0 ? '#0369A1' : '#64748B';
            }

            if (count === 0) {
                bodyEl.innerHTML = `
                    <div class="day-tasks-empty-state">
                        <div class="day-tasks-empty-icon">☕</div>
                        <div class="day-tasks-empty-title">Sin tareas para este día</div>
                        <div class="day-tasks-empty-subtitle">No hay tareas o rutinas programadas para el ${formattedTitle}.</div>
                    </div>
                `;
            } else {
                bodyEl.innerHTML = `
                    <div class="day-tasks-list">
                        ${dayTasks.map(task => {
                            const isCompleted = task.status === 'completed';
                            const priorityClass = `priority-${task.priority || 'medium'}`;
                            const checklist = Array.isArray(task.checklist) ? task.checklist : [];
                            const metrics = task.checklistMetrics || { total: checklist.length, completed: checklist.filter(c => c.done).length };
                            const checkInfo = checklist.length > 0 ? `✓ ${metrics.completed}/${metrics.total} pasos` : '';
                            const prefix = isCompleted ? '✅ ' : (task.is_recurring ? '🔁 ' : '');
                            const statusLabel = isCompleted ? 'Completada' : (task.status === 'in-progress' ? 'En Progreso' : 'Pendiente');
                            const statusClass = isCompleted ? 'completed' : (task.status === 'in-progress' ? 'in-progress' : 'pending');

                            return `
                                <div class="day-task-item ${priorityClass} ${isCompleted ? 'status-completed' : ''}"
                                     onclick="openTaskFromDayModal(${task.id})"
                                     title="Clic para ver detalle de la tarea">
                                    <div class="day-task-item-header">
                                        <span class="day-task-item-title">${prefix}${escapeHtml(task.title || 'Sin título')}</span>
                                        <span class="day-task-status-pill ${statusClass}">${statusLabel}</span>
                                    </div>
                                    <div class="day-task-item-details">
                                        <span class="day-task-badge category">🏷️ ${escapeHtml(task.category || 'General')}</span>
                                        <span class="day-task-badge sede">📍 ${escapeHtml(task.sede || 'Todas')}</span>
                                        ${checkInfo ? `<span class="day-task-badge checklist">${checkInfo}</span>` : ''}
                                        ${task.is_recurring ? `<span class="day-task-badge recurring">🔁 Rutina</span>` : ''}
                                        ${task.assigned_technician ? `<span class="day-task-badge tech">👤 ${escapeHtml(task.assigned_technician)}</span>` : ''}
                                    </div>
                                </div>
                            `;
                        }).join('')}
                    </div>
                `;
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

        function openTaskModal(task = null, defaultDateStr = null) {
            const modal = document.getElementById('taskModalDialog');
            if (!modal) return;

            const modalTitle = document.getElementById('taskModalTitle');
            const idInput = document.getElementById('taskIdInput');
            const titleInput = document.getElementById('taskTitleInput');
            const descInput = document.getElementById('taskDescInput');
            const categoryInput = document.getElementById('taskCategoryInput');
            const priorityInput = document.getElementById('taskPriorityInput');
            const sedeInput = document.getElementById('taskSedeInput');
            const assignedToInput = document.getElementById('taskAssignedToInput');
            const dueDateInput = document.getElementById('taskDueDateInput');
            const isRecurringInput = document.getElementById('taskIsRecurringInput');
            const recurrenceIntervalInput = document.getElementById('taskRecurrenceIntervalInput');

            if (task) {
                modalTitle.textContent = '✏️ Tarea de Mantenimiento & Checklist';
                idInput.value = task.id;
                titleInput.value = task.title || '';
                descInput.value = task.description || '';
                categoryInput.value = task.category || 'General';
                priorityInput.value = task.priority || 'medium';
                sedeInput.value = task.sede || 'Todas';
                if (assignedToInput) assignedToInput.value = task.assigned_technician || '';
                dueDateInput.value = task.due_date ? task.due_date.substring(0, 10) : '';
                isRecurringInput.checked = Boolean(task.is_recurring);
                const interval = task.recurrence_interval || 'weekly';
                if (interval === 'workweek') {
                    recurrenceIntervalInput.value = 'workweek';
                    selectedRecurrenceDays = [1, 2, 3, 4, 5];
                    const customDiv = document.getElementById('recurrenceCustomDaysDiv');
                    if (customDiv) customDiv.style.display = 'none';
                    renderRecurrenceDayPills();
                } else if (typeof interval === 'string' && interval.startsWith('custom:')) {
                    const rawDays = interval.replace('custom:', '').split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n));
                    if (rawDays.length === 5 && [1, 2, 3, 4, 5].every(d => rawDays.includes(d))) {
                        recurrenceIntervalInput.value = 'workweek';
                        selectedRecurrenceDays = [1, 2, 3, 4, 5];
                        const customDiv = document.getElementById('recurrenceCustomDaysDiv');
                        if (customDiv) customDiv.style.display = 'none';
                        renderRecurrenceDayPills();
                    } else {
                        recurrenceIntervalInput.value = 'custom_days';
                        selectedRecurrenceDays = rawDays.length > 0 ? rawDays : [2, 5];
                        const customDiv = document.getElementById('recurrenceCustomDaysDiv');
                        if (customDiv) customDiv.style.display = 'block';
                        renderRecurrenceDayPills();
                    }
                } else {
                    recurrenceIntervalInput.value = interval;
                    selectedRecurrenceDays = [];
                    const customDiv = document.getElementById('recurrenceCustomDaysDiv');
                    if (customDiv) customDiv.style.display = 'none';
                    renderRecurrenceDayPills();
                }
                taskChecklistBuilderItems = Array.isArray(task.checklist) ? [...task.checklist] : [];
            } else {
                modalTitle.textContent = '➕ Nueva Tarea de Mantenimiento';
                idInput.value = '';
                titleInput.value = '';
                descInput.value = '';
                categoryInput.value = 'General';
                priorityInput.value = 'medium';
                sedeInput.value = 'Todas';
                if (assignedToInput) assignedToInput.value = '';
                dueDateInput.value = defaultDateStr || '';
                isRecurringInput.checked = false;
                recurrenceIntervalInput.value = 'weekly';
                selectedRecurrenceDays = [];
                const customDiv = document.getElementById('recurrenceCustomDaysDiv');
                if (customDiv) customDiv.style.display = 'none';
                renderRecurrenceDayPills();
                taskChecklistBuilderItems = [];
            }

            toggleRecurrenceOptions(isRecurringInput.checked);
            renderChecklistBuilderList();

            modal.style.display = 'flex';
        }

        function closeTaskModal() {
            const modal = document.getElementById('taskModalDialog');
            if (modal) modal.style.display = 'none';
        }

        let selectedRecurrenceDays = [];

        function formatRecurrenceLabel(interval) {
            if (!interval || interval === 'none') return '📌 Única';
            if (interval === 'daily') return '🔁 Diaria (Cada día)';
            if (interval === 'workweek') return '💼 Semana laboral (Lun a Vie)';
            if (interval === 'weekly') return '🔁 Semanal (Cada 7 días)';
            if (interval === 'biweekly') return '🔁 Quincenal (Cada 14 días)';
            if (interval === 'monthly') return '🔁 Mensual (Cada mes)';
            if (interval === 'quarterly') return '🔁 Trimestral (Cada 3 meses)';
            if (interval === 'yearly') return '🔁 Anual (Cada año)';
            if (typeof interval === 'string' && interval.startsWith('custom:')) {
                const dayNames = {
                    '0': 'Dom',
                    '1': 'Lun',
                    '2': 'Mar',
                    '3': 'Mié',
                    '4': 'Jue',
                    '5': 'Vie',
                    '6': 'Sáb'
                };
                const raw = interval.replace('custom:', '').split(',').map(s => s.trim()).filter(Boolean);
                if (raw.length === 5 && ['1', '2', '3', '4', '5'].every(d => raw.includes(d))) {
                    return '💼 Semana laboral (Lun a Vie)';
                }
                const sorted = raw.sort((a, b) => {
                    const orderA = a === '0' ? 7 : parseInt(a, 10);
                    const orderB = b === '0' ? 7 : parseInt(b, 10);
                    return orderA - orderB;
                });
                const labels = sorted.map(d => dayNames[d] || d);
                return `🔁 Días: ${labels.join(', ')}`;
            }
            return `🔁 ${interval}`;
        }

        function handleRecurrenceIntervalChange(val) {
            const customDiv = document.getElementById('recurrenceCustomDaysDiv');
            if (val === 'custom_days') {
                if (customDiv) customDiv.style.display = 'block';
                if (!selectedRecurrenceDays || selectedRecurrenceDays.length === 0) {
                    const dueDateVal = document.getElementById('taskDueDateInput')?.value;
                    let initialDay = 2; // Martes por defecto
                    if (dueDateVal) {
                        const parts = dueDateVal.split('-');
                        if (parts.length === 3) {
                            const d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
                            initialDay = d.getDay();
                        }
                    }
                    selectedRecurrenceDays = [initialDay];
                }
                renderRecurrenceDayPills();
            } else if (val === 'workweek') {
                if (customDiv) customDiv.style.display = 'none';
                selectedRecurrenceDays = [1, 2, 3, 4, 5];
                renderRecurrenceDayPills();
                const isNewTask = !document.getElementById('taskIdInput')?.value;
                const dueInput = document.getElementById('taskDueDateInput');
                if (isNewTask && dueInput && dueInput.value) {
                    const parts = dueInput.value.split('-');
                    if (parts.length === 3) {
                        const d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10), 12, 0, 0);
                        if (d.getDay() === 6) {
                            d.setDate(d.getDate() + 2);
                            dueInput.value = formatDateKey(d);
                        } else if (d.getDay() === 0) {
                            d.setDate(d.getDate() + 1);
                            dueInput.value = formatDateKey(d);
                        }
                    }
                }
            } else {
                if (customDiv) customDiv.style.display = 'none';
            }
        }

        function setRecurrenceDaysPreset(preset) {
            if (preset === 'workweek') {
                selectedRecurrenceDays = [1, 2, 3, 4, 5];
            } else if (preset === 'all') {
                selectedRecurrenceDays = [1, 2, 3, 4, 5, 6, 0];
            } else if (preset === 'clear') {
                selectedRecurrenceDays = [];
            }
            renderRecurrenceDayPills();
        }

        function toggleRecurrenceDay(dayNumber) {
            dayNumber = parseInt(dayNumber, 10);
            if (selectedRecurrenceDays.includes(dayNumber)) {
                selectedRecurrenceDays = selectedRecurrenceDays.filter(d => d !== dayNumber);
            } else {
                selectedRecurrenceDays.push(dayNumber);
            }
            renderRecurrenceDayPills();
        }

        function getClosestUpcomingDateForDays(daysArr, fromDate = new Date()) {
            if (!daysArr || daysArr.length === 0) return null;
            const start = new Date(fromDate.getFullYear(), fromDate.getMonth(), fromDate.getDate(), 12, 0, 0);
            if (daysArr.includes(start.getDay())) {
                return start;
            }
            for (let offset = 1; offset <= 7; offset++) {
                const test = new Date(start);
                test.setDate(test.getDate() + offset);
                if (daysArr.includes(test.getDay())) {
                    return test;
                }
            }
            return start;
        }

        function renderRecurrenceDayPills() {
            const dayNames = {
                1: 'Lunes',
                2: 'Martes',
                3: 'Miércoles',
                4: 'Jueves',
                5: 'Viernes',
                6: 'Sábado',
                0: 'Domingo'
            };

            document.querySelectorAll('#taskModalDialog .day-pill-btn').forEach(btn => {
                const d = parseInt(btn.getAttribute('data-day'), 10);
                if (selectedRecurrenceDays.includes(d)) {
                    btn.classList.add('active');
                } else {
                    btn.classList.remove('active');
                }
            });

            const summary = document.getElementById('customDaysSelectionSummary');
            if (summary) {
                if (selectedRecurrenceDays.length === 0) {
                    summary.textContent = '⚠️ Selecciona al menos un día (ej. Martes y Viernes)';
                    summary.style.color = '#DC2626';
                } else {
                    const sorted = [...selectedRecurrenceDays].sort((a, b) => {
                        const orderA = a === 0 ? 7 : a;
                        const orderB = b === 0 ? 7 : b;
                        return orderA - orderB;
                    });
                    const names = sorted.map(d => dayNames[d]);
                    summary.textContent = `Se repetirá cada semana los días: ${names.join(', ')}`;
                    summary.style.color = '#7E22CE';
                }
            }

            // Si se están creando o ajustando días para una nueva tarea, alinear la fecha límite inicial al día configurado más cercano
            const isNewTask = !document.getElementById('taskIdInput')?.value;
            const dueInput = document.getElementById('taskDueDateInput');
            if (isNewTask && dueInput && selectedRecurrenceDays.length > 0) {
                const closestDate = getClosestUpcomingDateForDays(selectedRecurrenceDays);
                if (closestDate) {
                    dueInput.value = formatDateKey(closestDate);
                }
            }
        }

        function toggleRecurrenceOptions(isRecurring) {
            const optionsDiv = document.getElementById('recurrenceOptionsDiv');
            if (optionsDiv) {
                optionsDiv.style.display = isRecurring ? 'block' : 'none';
            }
            if (isRecurring) {
                handleRecurrenceIntervalChange(document.getElementById('taskRecurrenceIntervalInput')?.value);
            }
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
            input.focus();
            renderChecklistBuilderList();
        }

        function removeChecklistItemBuilder(index) {
            taskChecklistBuilderItems.splice(index, 1);
            renderChecklistBuilderList();
        }

        function renderChecklistBuilderList() {
            const listContainer = document.getElementById('checklistBuilderList');
            const emptyMsg = document.getElementById('emptyChecklistMsg');
            if (!listContainer) return;

            if (taskChecklistBuilderItems.length === 0) {
                if (emptyMsg) emptyMsg.style.display = 'block';
                listContainer.innerHTML = '';
                return;
            }

            if (emptyMsg) emptyMsg.style.display = 'none';
            listContainer.innerHTML = taskChecklistBuilderItems.map((item, idx) => `
                <div class="checklist-builder-item">
                    <span style="font-weight: 500; color: #374151;">🔹 ${escapeHtml(item.text)}</span>
                    <button type="button" onclick="removeChecklistItemBuilder(${idx})" style="background: none; border: none; color: #EF4444; font-weight: bold; cursor: pointer; padding: 2px 6px;" title="Eliminar ítem">❌</button>
                </div>
            `).join('');
        }

        async function handleSaveTask(e) {
            e.preventDefault();

            const id = document.getElementById('taskIdInput')?.value;
            const title = document.getElementById('taskTitleInput')?.value?.trim();
            const description = document.getElementById('taskDescInput')?.value?.trim();
            const category = document.getElementById('taskCategoryInput')?.value;
            const priority = document.getElementById('taskPriorityInput')?.value;
            const sede = document.getElementById('taskSedeInput')?.value;
            const assigned_technician = document.getElementById('taskAssignedToInput')?.value || null;
            const dueDate = document.getElementById('taskDueDateInput')?.value;
            const isRecurring = document.getElementById('taskIsRecurringInput')?.checked;
            let recurrenceInterval = 'none';
            if (isRecurring) {
                const intervalSelect = document.getElementById('taskRecurrenceIntervalInput')?.value;
                if (intervalSelect === 'custom_days') {
                    if (!selectedRecurrenceDays || selectedRecurrenceDays.length === 0) {
                        alert('Por favor selecciona al menos un día de la semana para la repetición personalizada (ej. Martes y Viernes)');
                        return;
                    }
                    const sortedDays = [...selectedRecurrenceDays].sort((a, b) => {
                        const orderA = a === 0 ? 7 : a;
                        const orderB = b === 0 ? 7 : b;
                        return orderA - orderB;
                    });
                    recurrenceInterval = `custom:${sortedDays.join(',')}`;
                } else {
                    recurrenceInterval = intervalSelect || 'weekly';
                }
            }

            if (!title) {
                alert('El título es requerido');
                return;
            }

            const payload = {
                title,
                description,
                category,
                priority,
                sede,
                assigned_technician,
                due_date: dueDate || null,
                is_recurring: isRecurring,
                recurrence_interval: recurrenceInterval,
                checklist: taskChecklistBuilderItems
            };

            const isEdit = Boolean(id);
            const url = isEdit ? `/api/maintenance/tasks/${id}` : '/api/maintenance/tasks';
            const method = isEdit ? 'PUT' : 'POST';

            try {
                const response = await fetch(url, {
                    method,
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    credentials: 'include',
                    body: JSON.stringify(payload)
                });

                const data = await response.json();
                if (!response.ok) {
                    throw new Error(data.error || 'Error al guardar tarea');
                }

                if (typeof window.showToast === 'function') {
                    window.showToast(isEdit ? 'Tarea actualizada con éxito' : '¡Tarea creada con éxito!', 'success');
                }

                closeTaskModal();
                loadMaintenanceTasks();
                loadMaintenanceTaskStats();
            } catch (err) {
                if (typeof window.showToast === 'function') {
                    window.showToast(err.message, 'error');
                } else {
                    alert(err.message);
                }
            }
        }

        let currentDetailTaskId = null;

        function openTaskDetailModal(taskOrId) {
            let task = null;
            if (typeof taskOrId === 'object' && taskOrId !== null) {
                task = taskOrId;
            } else {
                task = allMaintenanceTasks.find(t => String(t.id) === String(taskOrId));
            }

            if (!task) return;
            currentDetailTaskId = task.id;

            const modal = document.getElementById('taskDetailModalDialog');
            const body = document.getElementById('taskDetailBody');
            if (!modal || !body) return;

            const isCompleted = task.status === 'completed';
            const isInProgress = task.status === 'in-progress';

            const statusBadge = isCompleted 
                ? '<span class="task-badge" style="background:#DCFCE7; color:#15803D; border:1px solid #BBF7D0;">🟢 Completada</span>'
                : (isInProgress 
                    ? '<span class="task-badge" style="background:#E0F2FE; color:#0369A1; border:1px solid #BAE6FD;">🔵 En Progreso</span>'
                    : '<span class="task-badge" style="background:#FEF3C7; color:#B45309; border:1px solid #FDE68A;">🟡 Pendiente</span>');

            const priorityBadge = task.priority === 'urgent'
                ? '<span class="task-badge badge-priority-urgent">🔴 Urgente</span>'
                : (task.priority === 'high'
                    ? '<span class="task-badge badge-priority-high">🟠 Alta</span>'
                    : (task.priority === 'low'
                        ? '<span class="task-badge badge-priority-low">🔵 Baja</span>'
                        : '<span class="task-badge badge-priority-medium">🟡 Media</span>'));

            const recurrenceBadge = task.is_recurring
                ? `<span class="task-badge badge-recurrence">${formatRecurrenceLabel(task.recurrence_interval)}</span>`
                : '<span class="task-badge" style="background:#F3F4F6; color:#6B7280;">📌 Única</span>';

            const formattedDate = task.due_date ? task.due_date.substring(0, 10).split('-').reverse().join('/') : 'Sin fecha límite';
            const formattedCreated = task.created_at ? new Date(task.created_at).toLocaleString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '';

            const checklist = Array.isArray(task.checklist) ? task.checklist : [];
            const metrics = task.checklistMetrics || { total: checklist.length, completed: checklist.filter(i => i.done).length };
            const percent = metrics.total > 0 ? Math.round((metrics.completed / metrics.total) * 100) : 0;

            let checklistHtml = '';
            if (checklist.length > 0) {
                checklistHtml = `
                    <div style="background: #F9FAFB; border: 1px solid #E5E7EB; border-radius: 10px; padding: 14px; margin-bottom: 18px;">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <strong style="font-size: 0.9rem; color: #374151;">📝 Checklist de Pasos (${metrics.completed}/${metrics.total})</strong>
                            <span style="font-size: 0.82rem; font-weight: 700; color: ${percent === 100 ? '#10B981' : '#008B8B'};">${percent}%</span>
                        </div>
                        <div style="width: 100%; height: 7px; background: #E5E7EB; border-radius: 4px; overflow: hidden; margin-bottom: 12px;">
                            <div style="width: ${percent}%; height: 100%; background: ${percent === 100 ? '#10B981' : '#008B8B'}; transition: width 0.3s ease;"></div>
                        </div>
                        <div style="display: flex; flex-direction: column; gap: 8px; max-height: 220px; overflow-y: auto;">
                            ${checklist.map(item => `
                                <label style="display: flex; align-items: center; gap: 10px; padding: 7px 10px; border-radius: 6px; background: white; border: 1px solid #E5E7EB; cursor: pointer; transition: background 0.15s;" onmouseover="this.style.background='#F3F4F6'" onmouseout="this.style.background='white'">
                                    <input type="checkbox" ${item.done ? 'checked' : ''} onchange="toggleChecklistItemInDetail(${task.id}, '${item.id}', ${item.done})" style="width: 18px; height: 18px; accent-color: #008B8B; cursor: pointer;">
                                    <span style="font-size: 0.88rem; color: ${item.done ? '#9CA3AF' : '#1F2937'}; ${item.done ? 'text-decoration: line-through;' : ''}">${escapeHtml(item.text)}</span>
                                </label>
                            `).join('')}
                        </div>
                    </div>
                `;
            }

            body.innerHTML = `
                <div style="margin-bottom: 14px;">
                    <h2 style="font-size: 1.35rem; font-weight: 700; color: #111827; margin: 0 0 8px 0; line-height: 1.3;">
                        ${task.is_recurring ? '🔁 ' : ''}${escapeHtml(task.title)}
                    </h2>
                    <div style="display: flex; flex-wrap: wrap; gap: 6px; align-items: center;">
                        ${statusBadge}
                        ${priorityBadge}
                        <span class="task-badge badge-category">🏢 ${escapeHtml(task.category || 'General')}</span>
                        <span class="task-badge badge-sede">📍 ${escapeHtml(task.sede || 'Todas')}</span>
                        ${recurrenceBadge}
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; padding: 12px 14px; margin-bottom: 16px; font-size: 0.85rem; color: #475569;">
                    <div>
                        <strong>📅 Fecha Programada:</strong> <span style="color: #1E293B; font-weight: 600;">${formattedDate}</span>
                    </div>
                    <div>
                        <strong>👤 Asignado a:</strong> <span style="color: #1E293B; font-weight: 600;">${escapeHtml(task.assigned_technician || 'Sin asignar')}</span>
                    </div>
                    <div>
                        <strong>✍️ Creada por:</strong> <span style="color: #1E293B; font-weight: 600;">${escapeHtml(task.created_by_name || 'Personal de Mantenimiento')}</span>
                    </div>
                    ${formattedCreated ? `
                    <div style="font-size: 0.78rem; color: #64748B;">
                        🕒 Registrada el: ${formattedCreated}
                    </div>` : ''}
                </div>

                ${task.description ? `
                <div style="margin-bottom: 16px;">
                    <strong style="display: block; font-size: 0.86rem; color: #374151; margin-bottom: 4px;">📄 Descripción / Instrucciones:</strong>
                    <div style="background: white; border: 1px solid #E5E7EB; border-radius: 8px; padding: 10px 12px; font-size: 0.88rem; color: #4B5563; line-height: 1.5; white-space: pre-wrap;">${escapeHtml(task.description)}</div>
                </div>` : ''}

                ${checklistHtml}

                <div style="display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 10px; border-top: 1px solid #E5E7EB; padding-top: 16px; margin-top: 14px;">
                    <div style="display: flex; gap: 8px;">
                        <button id="btnToggleStatusDetail-${task.id}" type="button" onclick="handleToggleStatusFromDetail(${task.id}, '${task.status}', this)" style="padding: 9px 14px; border-radius: 6px; font-size: 0.85rem; font-weight: 700; cursor: pointer; border: 1px solid #CBD5E1; background: ${isCompleted ? '#FEF3C7' : '#DCFCE7'}; color: ${isCompleted ? '#B45309' : '#15803D'}; display: inline-flex; align-items: center; gap: 6px; transition: all 0.2s ease;">
                            ${isCompleted ? '↩️ Reabrir Tarea' : '✅ Marcar Completada'}
                        </button>
                    </div>
                    <div style="display: flex; gap: 8px;">
                        <button type="button" onclick="editTaskFromDetail(${task.id})" style="padding: 9px 14px; background: #008B8B; color: white; border: none; border-radius: 6px; font-size: 0.85rem; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 6px;">
                            ✏️ Editar Tarea
                        </button>
                        <button type="button" onclick="confirmDeleteTask(${task.id})" style="padding: 9px 14px; background: #FEE2E2; color: #DC2626; border: 1px solid #FECACA; border-radius: 6px; font-size: 0.85rem; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 6px;">
                            🗑️ Eliminar
                        </button>
                        <button type="button" onclick="closeTaskDetailModal()" style="padding: 9px 14px; background: #F3F4F6; color: #4B5563; border: 1px solid #E5E7EB; border-radius: 6px; font-size: 0.85rem; font-weight: 600; cursor: pointer;">
                            Cerrar
                        </button>
                    </div>
                </div>
            `;

            modal.style.display = 'flex';
        }

        function closeTaskDetailModal() {
            const modal = document.getElementById('taskDetailModalDialog');
            if (modal) modal.style.display = 'none';
            currentDetailTaskId = null;
        }

        async function toggleChecklistItemInDetail(taskId, itemId, currentDone) {
            await toggleChecklistItem(taskId, itemId, currentDone);
            const updated = allMaintenanceTasks.find(t => String(t.id) === String(taskId));
            if (updated) {
                openTaskDetailModal(updated);
            }
        }

        function editTaskFromDetail(taskId) {
            closeTaskDetailModal();
            const task = allMaintenanceTasks.find(t => String(t.id) === String(taskId));
            if (task) {
                openTaskModal(task);
            }
        }

        function confirmDeleteTask(taskId) {
            const task = allMaintenanceTasks.find(t => String(t.id) === String(taskId));
            const title = task ? task.title : 'esta tarea';

            showConfirmDialog({
                icon: '🗑️',
                title: '¿Eliminar Tarea de Mantenimiento?',
                message: `Estás a punto de eliminar <strong>"${escapeHtml(title)}"</strong>.<br>Esta acción es irreversible y eliminará todo el checklist y progreso asociado.`,
                confirmText: '🗑️ Sí, eliminar tarea',
                confirmColor: '#DC2626',
                onConfirm: async () => {
                    closeTaskDetailModal();
                    await executeDeleteTask(taskId);
                }
            });
        }

        function handleToggleStatusFromDetail(taskId, currentStatus, btnElement) {
            const task = allMaintenanceTasks.find(t => String(t.id) === String(taskId));
            const newStatus = currentStatus === 'completed' ? 'pending' : 'completed';

            const btn = btnElement || document.getElementById(`btnToggleStatusDetail-${taskId}`);
            if (btn) {
                btn.disabled = true;
                btn.style.opacity = '0.6';
                btn.style.cursor = 'not-allowed';
                btn.innerHTML = newStatus === 'completed' ? '⏳ Completando...' : '⏳ Reabriendo...';
            }

            if (newStatus === 'completed' && task && task.checklistMetrics && !task.checklistMetrics.allDone && task.checklistMetrics.total > 0) {
                showConfirmDialog({
                    icon: '⚠️',
                    title: '¿Completar con ítems pendientes?',
                    message: `Aún quedan <strong>${task.checklistMetrics.total - task.checklistMetrics.completed}</strong> ítems sin tildar en el checklist.<br>¿Deseas marcar la tarea como completada de todas formas?`,
                    confirmText: '✅ Sí, completar',
                    confirmColor: '#10B981',
                    onConfirm: async () => {
                        closeTaskDetailModal();
                        await changeTaskStatus(taskId, 'completed');
                    },
                    onCancel: () => {
                        if (btn) {
                            btn.disabled = false;
                            btn.style.opacity = '1';
                            btn.style.cursor = 'pointer';
                            btn.innerHTML = currentStatus === 'completed' ? '↩️ Reabrir Tarea' : '✅ Marcar Completada';
                        }
                    }
                });
                return;
            }

            closeTaskDetailModal();
            changeTaskStatus(taskId, newStatus);
        }

        // Modal de Confirmación Genérico Estilizado
        let currentConfirmCallback = null;
        let currentCancelCallback = null;

        function showConfirmDialog({ icon = '⚠️', title = '¿Confirmar Acción?', message = '¿Estás seguro de continuar?', confirmText = 'Confirmar', confirmColor = '#DC2626', onConfirm, onCancel }) {
            const modal = document.getElementById('confirmActionModal');
            const iconEl = document.getElementById('confirmIcon');
            const titleEl = document.getElementById('confirmTitle');
            const msgEl = document.getElementById('confirmMessage');
            const btnEl = document.getElementById('confirmActionButton');

            if (!modal) return;

            if (iconEl) iconEl.textContent = icon;
            if (titleEl) titleEl.innerHTML = title;
            if (msgEl) msgEl.innerHTML = message;
            if (btnEl) {
                btnEl.innerHTML = confirmText;
                btnEl.style.background = confirmColor;
            }

            currentConfirmCallback = onConfirm;
            currentCancelCallback = onCancel;

            btnEl.onclick = async () => {
                const cb = currentConfirmCallback;
                currentConfirmCallback = null;
                currentCancelCallback = null;
                closeConfirmModal();
                if (typeof cb === 'function') {
                    await cb();
                }
            };

            modal.style.display = 'flex';
        }

        function closeConfirmModal() {
            const modal = document.getElementById('confirmActionModal');
            if (modal) modal.style.display = 'none';
            if (typeof currentCancelCallback === 'function') {
                currentCancelCallback();
            }
            currentConfirmCallback = null;
            currentCancelCallback = null;
        }

        async function executeDeleteTask(taskId) {
            try {
                const response = await fetch(`/api/maintenance/tasks/${taskId}`, {
                    method: 'DELETE',
                    credentials: 'include',
                    headers: { 'Accept': 'application/json' }
                });

                const data = await response.json();
                if (!response.ok) throw new Error(data.error || 'Error al eliminar tarea');

                if (typeof window.showToast === 'function') {
                    window.showToast('🗑️ Tarea eliminada con éxito', 'success');
                }

                await loadMaintenanceTasks();
                await loadMaintenanceTaskStats();
            } catch (err) {
                if (typeof window.showToast === 'function') {
                    window.showToast(err.message, 'error');
                } else {
                    alert(err.message);
                }
            }
        }

        // ==============================================
        // EXPORTACIÓN A CSV DEL TABLERO DE TAREAS
        // ==============================================
        function exportTasksToCSV() {
            if (!allMaintenanceTasks || allMaintenanceTasks.length === 0) {
                showNotification('No hay tareas disponibles para exportar', 'warning');
                return;
            }

            const generatedAt = new Date().toLocaleString('es-AR');
            const lines = [
                `"Tablero de Tareas y Rutinas - Mantenimiento"`,
                `"Fecha de Exportación";"${generatedAt}"`,
                `"Total Tareas";"${allMaintenanceTasks.length}"`,
                ``,
                `"LISTADO DE TAREAS"`,
                `"ID";"Título";"Descripción";"Categoría";"Prioridad";"Sede";"Asignado a";"Estado";"Fecha Vencimiento";"Recurrente";"Frecuencia";"Pasos Completados";"Total Pasos";"Progreso %";"Creado Por"`
            ];

            allMaintenanceTasks.forEach(t => {
                const checklist = Array.isArray(t.checklist) ? t.checklist : [];
                const metrics = t.checklistMetrics || { total: checklist.length, completed: checklist.filter(i => i.done).length, percent: 0 };
                const dueDateStr = t.due_date ? t.due_date.substring(0, 10) : 'Sin fecha';
                const statusLabel = t.status === 'completed' ? 'Completada' : (t.status === 'in-progress' ? 'En Progreso' : 'Pendiente');

                const recurrenceLabel = t.is_recurring ? formatRecurrenceLabel(t.recurrence_interval) : 'No';
                lines.push(`"${t.id}";"${(t.title || '').replace(/"/g, '""')}";"${(t.description || '').replace(/"/g, '""')}";"${t.category || 'General'}";"${t.priority || 'medium'}";"${t.sede || 'Todas'}";"${t.assigned_technician || 'Sin asignar'}";"${statusLabel}";"${dueDateStr}";"${t.is_recurring ? 'SÍ' : 'NO'}";"${recurrenceLabel}";"${metrics.completed}";"${metrics.total}";"${metrics.percent}%";"${t.created_by_name || ''}"`);
            });

            const csvContent = '\uFEFF' + lines.join('\r\n');
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            const todayStr = new Date().toISOString().substring(0, 10);
            link.setAttribute('href', url);
            link.setAttribute('download', `tablero_tareas_mantenimiento_${todayStr}.csv`);
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);

            showNotification('📊 Tablero de tareas exportado a CSV exitosamente', 'success');
        }

        // ==============================================
        // ENLACES PÚBLICOS DEL TABLERO DE TAREAS
        // ==============================================
        function setTaskShareDatePreset(preset) {
            const startInput = document.getElementById('shareTaskStartDateInput');
            const endInput = document.getElementById('shareTaskEndDateInput');
            if (!startInput || !endInput) return;

            const today = new Date();
            let startDate = new Date();
            let endDate = new Date();

            if (preset === '7d') {
                startDate.setDate(today.getDate() - 7);
                endDate = today;
            } else if (preset === '14d') {
                startDate.setDate(today.getDate() - 14);
                endDate = today;
            } else if (preset === 'this_month') {
                startDate = new Date(today.getFullYear(), today.getMonth(), 1);
                endDate = today;
            } else if (preset === 'last_month') {
                startDate = new Date(today.getFullYear(), today.getMonth() - 1, 1);
                endDate = new Date(today.getFullYear(), today.getMonth(), 0);
            }

            const toYMD = (d) => {
                const year = d.getFullYear();
                const month = String(d.getMonth() + 1).padStart(2, '0');
                const day = String(d.getDate()).padStart(2, '0');
                return `${year}-${month}-${day}`;
            };

            startInput.value = toYMD(startDate);
            endInput.value = toYMD(endDate);
            updateTaskShareCustomDateSummary();
        }

        function updateTaskShareCustomDateSummary() {
            const startInput = document.getElementById('shareTaskStartDateInput');
            const endInput = document.getElementById('shareTaskEndDateInput');
            const summaryText = document.getElementById('taskShareCustomDateSummaryText');
            const daysBadge = document.getElementById('taskShareCustomDateDaysBadge');
            if (!startInput || !endInput || !summaryText || !daysBadge) return;

            const sVal = startInput.value;
            const eVal = endInput.value;
            if (!sVal || !eVal) {
                summaryText.textContent = '📅 Selecciona las fechas de inicio y fin';
                daysBadge.textContent = '';
                return;
            }

            if (eVal < sVal) {
                summaryText.innerHTML = '<span style="color: #DC2626;">⚠️ La fecha de fin no puede ser anterior a la de inicio</span>';
                daysBadge.textContent = 'Inválido';
                daysBadge.style.background = '#FEE2E2';
                daysBadge.style.color = '#DC2626';
                return;
            }

            const sParts = sVal.split('-');
            const eParts = eVal.split('-');
            const sDate = new Date(sParts[0], sParts[1] - 1, sParts[2]);
            const eDate = new Date(eParts[0], eParts[1] - 1, eParts[2]);
            const diffTime = Math.abs(eDate - sDate);
            const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;

            const sFormatted = `${sParts[2]}/${sParts[1]}/${sParts[0]}`;
            const eFormatted = `${eParts[2]}/${eParts[1]}/${eParts[0]}`;

            summaryText.innerHTML = `<span>📅 Rango activo: <strong>${sFormatted}</strong> al <strong>${eFormatted}</strong></span>`;
            daysBadge.textContent = `${diffDays} día${diffDays > 1 ? 's' : ''}`;
            daysBadge.style.background = '#E6FCF5';
            daysBadge.style.color = '#008B8B';
        }

        function toggleTaskShareCustomDates() {
            const periodSelect = document.getElementById('shareTaskPeriodSelect');
            const customBox = document.getElementById('taskShareCustomDatesContainer');
            const helpText = document.getElementById('shareTaskPeriodHelpText');
            if (!periodSelect || !customBox) return;

            if (periodSelect.value === 'custom') {
                customBox.style.display = 'block';
                if (helpText) {
                    helpText.textContent = '📅 Rango personalizado: Solo se incluirán tareas dentro del rango exacto seleccionado.';
                }
                const startInput = document.getElementById('shareTaskStartDateInput');
                const endInput = document.getElementById('shareTaskEndDateInput');
                const toYMD = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
                if (startInput && !startInput.value) {
                    const d = new Date();
                    d.setDate(d.getDate() - 7);
                    startInput.value = toYMD(d);
                }
                if (endInput && !endInput.value) {
                    endInput.value = toYMD(new Date());
                }
                updateTaskShareCustomDateSummary();
            } else {
                customBox.style.display = 'none';
                if (helpText) {
                    if (periodSelect.value === 'all') {
                        helpText.textContent = '⚠️ Incluye todas las tareas históricas y futuras planificadas.';
                    } else {
                        helpText.textContent = '🔒 Corte de fecha: Solo incluye tareas hasta hoy, evitando computar rutinas futuras como pendientes.';
                    }
                }
            }
        }

        function openShareTasksModal() {
            const modal = document.getElementById('shareTasksModalDialog');
            if (!modal) return;
            const resBox = document.getElementById('newTaskShareResult');
            if (resBox) resBox.style.display = 'none';
            toggleTaskShareCustomDates();
            modal.style.display = 'flex';
            loadSharedTaskLinks();
        }

        function closeShareTasksModal() {
            const modal = document.getElementById('shareTasksModalDialog');
            if (modal) modal.style.display = 'none';
        }

        async function generateSharedTaskBoardLink() {
            const titleInput = document.getElementById('shareTaskTitleInput');
            const periodSelect = document.getElementById('shareTaskPeriodSelect');
            const expirationSelect = document.getElementById('shareTaskExpirationSelect');
            const title = titleInput ? titleInput.value.trim() : '';
            const period = periodSelect ? periodSelect.value : '7d';
            const expireInDays = expirationSelect ? parseInt(expirationSelect.value, 10) : 7;
            let startDate = null;
            let endDate = null;

            if (period === 'custom') {
                const startInput = document.getElementById('shareTaskStartDateInput');
                const endInput = document.getElementById('shareTaskEndDateInput');
                startDate = startInput ? startInput.value : '';
                endDate = endInput ? endInput.value : '';

                if (!startDate || !endDate) {
                    showNotification('⚠️ Debes seleccionar la fecha de inicio y de fin', 'warning');
                    return;
                }
                if (endDate < startDate) {
                    showNotification('⚠️ La fecha de fin no puede ser anterior a la de inicio', 'warning');
                    return;
                }
            }

            try {
                const response = await fetch('/api/maintenance/tasks/share', {
                    method: 'POST',
                    credentials: 'include',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    body: JSON.stringify({ 
                        title, 
                        expireInDays, 
                        period, 
                        startDate, 
                        endDate, 
                        department: 'Mantenimiento' 
                    })
                });

                if (!response.ok) {
                    const err = await response.json();
                    throw new Error(err.error || 'Error al generar enlace público');
                }

                const data = await response.json();
                const resBox = document.getElementById('newTaskShareResult');
                const urlInput = document.getElementById('generatedTaskShareUrl');
                const openBtn = document.getElementById('openTaskShareUrlBtn');

                if (urlInput) urlInput.value = data.url;
                if (openBtn) openBtn.href = data.url;
                if (resBox) resBox.style.display = 'block';

                showNotification('✨ Enlace público generado con éxito', 'success');
                if (titleInput) titleInput.value = '';
                loadSharedTaskLinks();
            } catch (err) {
                showNotification(`❌ Error: ${err.message}`, 'error');
            }
        }

        async function loadSharedTaskLinks() {
            const tbody = document.getElementById('sharedTaskLinksTableBody');
            if (!tbody) return;

            try {
                const response = await fetch('/api/maintenance/tasks/share', {
                    credentials: 'include',
                    headers: { 'Accept': 'application/json' }
                });

                if (!response.ok) throw new Error('Error al cargar enlaces');
                const links = await response.json();

                if (!Array.isArray(links) || links.length === 0) {
                    tbody.innerHTML = `
                        <tr>
                            <td colspan="4" style="text-align: center; padding: 1.5rem; color: #9CA3AF;">
                                No hay enlaces públicos activos creados.
                            </td>
                        </tr>
                    `;
                    return;
                }

                const periodLabels = {
                    '1d': 'Últimas 24hs',
                    '7d': 'Últimos 7 días',
                    '30d': 'Últimos 30 días',
                    'month': 'Mes Actual',
                    'until_today': 'Todo hasta hoy',
                    'all': 'Completo (futuras)'
                };

                tbody.innerHTML = links.map(link => {
                    const expStr = link.expires_at 
                        ? new Date(link.expires_at).toLocaleDateString('es-AR')
                        : 'Permanente';
                    const isExpired = link.isExpired;
                    let periodLabel = periodLabels[link.period] || 'Últimos 7 días';
                    if (link.period === 'custom' && link.start_date && link.end_date) {
                        const s = new Date(link.start_date).toLocaleDateString('es-AR', { timeZone: 'UTC' });
                        const e = new Date(link.end_date).toLocaleDateString('es-AR', { timeZone: 'UTC' });
                        periodLabel = `${s} al ${e}`;
                    }

                    return `
                        <tr style="border-bottom: 1px solid #F1F5F9;">
                            <td style="padding: 8px 10px; font-weight: 600; color: #1E293B;">
                                ${escapeHtml(link.title)}
                            </td>
                            <td style="padding: 8px 10px;">
                                <span style="font-size: 0.75rem; padding: 2px 6px; border-radius: 4px; background: #E6FCF5; color: #008B8B; font-weight: 600; border: 1px solid #C3FAE8;">
                                    📅 ${escapeHtml(periodLabel)}
                                </span>
                            </td>
                            <td style="padding: 8px 10px;">
                                <span style="font-size: 0.75rem; padding: 2px 6px; border-radius: 4px; background: ${isExpired ? '#FEE2E2' : '#E0F2FE'}; color: ${isExpired ? '#DC2626' : '#0369A1'}; font-weight: 600;">
                                    ${isExpired ? '⚠️ Expirado' : `⏳ ${expStr}`}
                                </span>
                            </td>
                            <td style="padding: 8px 10px; text-align: right; white-space: nowrap;">
                                <button type="button" onclick="copySpecificUrl('${link.url}')" style="padding: 4px 8px; font-size: 0.75rem; background: #F1F5F9; border: 1px solid #CBD5E1; border-radius: 4px; cursor: pointer; margin-right: 4px;" title="Copiar enlace">📋</button>
                                <a href="${link.url}" target="_blank" style="padding: 4px 8px; font-size: 0.75rem; background: #E0F2FE; color: #0369A1; border: 1px solid #BAE6FD; border-radius: 4px; text-decoration: none; margin-right: 4px;" title="Abrir">↗️</a>
                                <button type="button" onclick="deleteSharedTaskLink('${link.token}')" style="padding: 4px 8px; font-size: 0.75rem; background: #FEE2E2; color: #DC2626; border: 1px solid #FECACA; border-radius: 4px; cursor: pointer;" title="Eliminar enlace">🗑️</button>
                            </td>
                        </tr>
                    `;
                }).join('');
            } catch (err) {
                tbody.innerHTML = `<tr><td colspan="4" style="color: #EF4444; padding: 1rem; text-align: center;">Error al cargar enlaces</td></tr>`;
            }
        }

        async function deleteSharedTaskLink(token) {
            showConfirmDialog({
                icon: '🗑️',
                title: '¿Eliminar Enlace Público?',
                message: 'El enlace dejará de ser accesible inmediatamente para cualquier persona externa.',
                confirmText: 'Sí, eliminar',
                confirmColor: '#DC2626',
                onConfirm: async () => {
                    try {
                        const response = await fetch(`/api/maintenance/tasks/share/${token}`, {
                            method: 'DELETE',
                            credentials: 'include',
                            headers: { 'Accept': 'application/json' }
                        });
                        if (!response.ok) throw new Error('Error al eliminar enlace');
                        showNotification('🗑️ Enlace eliminado correctamente', 'success');
                        loadSharedTaskLinks();
                    } catch (err) {
                        showNotification(`❌ Error: ${err.message}`, 'error');
                    }
                }
            });
        }

        function copyTaskShareUrlToClipboard() {
            const urlInput = document.getElementById('generatedTaskShareUrl');
            if (urlInput && urlInput.value) {
                copySpecificUrl(urlInput.value);
            }
        }

        function copySpecificUrl(url) {
            if (navigator.clipboard && window.isSecureContext) {
                navigator.clipboard.writeText(url).then(() => {
                    showNotification('📋 ¡Enlace copiado al portapapeles!', 'success');
                }).catch(() => {
                    fallbackCopy(url);
                });
            } else {
                fallbackCopy(url);
            }
        }

        function fallbackCopy(text) {
            const temp = document.createElement('textarea');
            temp.value = text;
            document.body.appendChild(temp);
            temp.select();
            try {
                document.execCommand('copy');
                showNotification('📋 ¡Enlace copiado!', 'success');
            } catch (_) {
                prompt('Copia el enlace manualmente:', text);
            }
            document.body.removeChild(temp);
        }

        // Exponer funciones globales
        window.switchMaintTab = switchMaintTab;
        window.loadMaintenanceTasks = loadMaintenanceTasks;
        window.loadMaintenanceTaskStats = loadMaintenanceTaskStats;
        window.debounceTaskSearch = debounceTaskSearch;
        window.toggleChecklistItem = toggleChecklistItem;
        window.changeTaskStatus = changeTaskStatus;
        window.openTaskModal = openTaskModal;
        window.closeTaskModal = closeTaskModal;
        window.openTaskDetailModal = openTaskDetailModal;
        window.closeTaskDetailModal = closeTaskDetailModal;
        window.toggleChecklistItemInDetail = toggleChecklistItemInDetail;
        window.editTaskFromDetail = editTaskFromDetail;
        window.confirmDeleteTask = confirmDeleteTask;
        window.handleToggleStatusFromDetail = handleToggleStatusFromDetail;
        window.showConfirmDialog = showConfirmDialog;
        window.closeConfirmModal = closeConfirmModal;
        window.toggleRecurrenceOptions = toggleRecurrenceOptions;
        window.addChecklistItemBuilder = addChecklistItemBuilder;
        window.removeChecklistItemBuilder = removeChecklistItemBuilder;
        window.handleSaveTask = handleSaveTask;
        window.deleteTask = confirmDeleteTask;
        window.calendarGoToday = calendarGoToday;
        window.calendarPrev = calendarPrev;
        window.calendarNext = calendarNext;
        window.setCalendarView = setCalendarView;
        window.exportTasksToCSV = exportTasksToCSV;
        window.openShareTasksModal = openShareTasksModal;
        window.closeShareTasksModal = closeShareTasksModal;
        window.toggleTaskShareCustomDates = toggleTaskShareCustomDates;
        window.setTaskShareDatePreset = setTaskShareDatePreset;
        window.updateTaskShareCustomDateSummary = updateTaskShareCustomDateSummary;
        window.generateSharedTaskBoardLink = generateSharedTaskBoardLink;
        window.loadSharedTaskLinks = loadSharedTaskLinks;
        window.deleteSharedTaskLink = deleteSharedTaskLink;
        window.copyTaskShareUrlToClipboard = copyTaskShareUrlToClipboard;
        window.copySpecificUrl = copySpecificUrl;
        window.renderCalendar = renderCalendar;
        window.handleRecurrenceIntervalChange = handleRecurrenceIntervalChange;
        window.toggleRecurrenceDay = toggleRecurrenceDay;
        window.setRecurrenceDaysPreset = setRecurrenceDaysPreset;
        window.formatRecurrenceLabel = formatRecurrenceLabel;
        window.openDayTasksModal = openDayTasksModal;
        window.closeDayTasksModal = closeDayTasksModal;
        window.handleDayTasksAddClick = handleDayTasksAddClick;
        window.openTaskFromDayModal = openTaskFromDayModal;