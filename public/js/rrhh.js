        // Check authentication on load
        window.addEventListener('load', function () {
            window.verifySession(['rrhh', 'gerencia', 'administrador'], function (user) {
                loadMyTickets();
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
                        if (data.user.role !== 'rrhh' && data.user.role !== 'gerencia' && data.user.role !== 'administrador') {
                            errorDiv.textContent = 'Acceso denegado. Solo personal de RRHH, gerencia o administración puede acceder.';
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

        function showTicketDetails(ticketId) {
            currentTicketId = ticketId;
            const ticket = allTickets.find(t => t.id === ticketId);

            if (!ticket) return;

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
                    if (!response.ok) {
                        throw new Error('Error al cargar comentarios');
                    }
                    return response.json();
                })
                .then(comments => {
                    const commentsList = document.getElementById('commentsList');

                    if (comments.length === 0) {
                        commentsList.innerHTML = '<p style="color: #6c757d; font-style: italic;">No hay comentarios aún</p>';
                        return;
                    }

                    commentsList.innerHTML = comments.map(comment => {
                        const isReopened = comment.content && comment.content.includes('🔓');
                        const isClosed = comment.content && comment.content.includes('🔒');
                        let badge = '';
                        if (isReopened) {
                            badge = '<span style="font-size:0.75em; background:#DCFCE7; color:#15803D; padding:2px 8px; border-radius:10px; font-weight:700; margin-left:6px;">🔓 Reabierto</span>';
                        } else if (isClosed) {
                            badge = '<span style="font-size:0.75em; background:#FEE2E2; color:#DC2626; padding:2px 8px; border-radius:10px; font-weight:700; margin-left:6px;">🔒 Cerrado</span>';
                        } else if (comment.update_type === 'status_change') {
                            badge = '<span style="font-size:0.75em; background:#fff3cd; color:#856404; padding:2px 8px; border-radius:10px; font-weight:600; margin-left:6px;">🔄 Estado</span>';
                        } else if (comment.update_type === 'priority_change') {
                            badge = '<span style="font-size:0.75em; background:#E0F2FE; color:#0369A1; padding:2px 8px; border-radius:10px; font-weight:600; margin-left:6px;">⚠️ Prioridad</span>';
                        }
                        return `
                        <div class="comment-item" style="padding:10px 14px; margin-bottom:12px; background:#f9fafb; border-radius:8px; border-left:4px solid ${isReopened ? '#10B981' : (isClosed ? '#EF4444' : '#3B82F6')}">
                            <div class="comment-meta" style="font-size:0.85em; color:#6b7280; margin-bottom:4px;">
                                <strong>${escapeHtml(comment.user_name || 'Sistema')}</strong> - ${new Date(comment.created_at).toLocaleString('es-ES')}
                                ${badge}
                            </div>
                            <div style="color:#1f2937;">${escapeHtml(comment.content).replace(/\n/g, '<br>')}</div>
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
                const priorityLabel = document.getElementById(`ticketPriorityLabel-${ticketId}`);
                const priorityCard = document.getElementById(`ticketPriorityCard-${ticketId}`);
                const prioritySelect = document.getElementById(`ticketPrioritySelect-${ticketId}`);
                const priorityHelp = document.getElementById(`ticketPriorityHelp-${ticketId}`);

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

        // Lightbox universal provisto por core-panel.js (window.openLightbox / window.closeLightbox)