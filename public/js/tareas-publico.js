/**
 * tareas-publico.js - Controlador para la vista pública compartida del tablero de tareas
 */

(function () {
    let boardMetadata = null;
    let allPublicTasks = [];
    let filteredTasks = [];
    let currentCalendarDate = new Date();
    let currentCalendarView = 'month';

    function getShareTokenFromUrl() {
        const pathParts = window.location.pathname.split('/');
        const lastPart = pathParts[pathParts.length - 1];
        if (lastPart && lastPart !== 'tareas-publico.html' && lastPart !== 'publico') {
            return lastPart;
        }
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get('token') || '';
    }

    async function loadPublicBoardData() {
        const token = getShareTokenFromUrl();
        if (!token) {
            showFatalError('Token de enlace público no proporcionado');
            return;
        }

        try {
            const response = await fetch(`/api/maintenance/tasks/public/${token}`, {
                headers: { 'Accept': 'application/json' }
            });

            if (!response.ok) {
                const err = await response.json();
                throw new Error(err.error || 'Error al cargar el tablero público');
            }

            const data = await response.json();
            boardMetadata = data.board;
            allPublicTasks = data.tasks || [];

            renderBoardHeader(data.board);
            renderKPIs(data.stats);
            applyFilters();
        } catch (err) {
            showFatalError(err.message);
        }
    }

    function renderBoardHeader(board) {
        if (!board) return;
        const pageTitle = document.getElementById('pageTitle');
        const navTitle = document.getElementById('navBoardTitle');
        const headerTitle = document.getElementById('boardHeaderTitle');
        const deptBadge = document.getElementById('boardDeptBadge');
        const createdInfo = document.getElementById('boardCreatedInfo');

        const titleText = board.title || 'Tablero de Tareas';
        if (pageTitle) pageTitle.textContent = `${titleText} - Imagen Diagnóstica`;
        if (navTitle) navTitle.textContent = titleText;
        if (headerTitle) headerTitle.textContent = titleText;
        if (deptBadge) deptBadge.textContent = `🏢 ${board.department || 'General'}`;

        if (createdInfo && board.created_at) {
            const d = new Date(board.created_at).toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric' });
            createdInfo.textContent = `📅 Generado el: ${d}${board.created_by_name ? ` por ${board.created_by_name}` : ''}`;
        }
    }

    function renderKPIs(stats) {
        if (!stats) return;
        document.getElementById('kpiTotal').textContent = stats.total || 0;
        document.getElementById('kpiPending').textContent = stats.pending || 0;
        document.getElementById('kpiInProgress').textContent = stats.in_progress || 0;
        document.getElementById('kpiCompleted').textContent = stats.completed || 0;
        document.getElementById('kpiRecurring').textContent = stats.recurring_count || 0;
    }

    function applyFilters() {
        const search = (document.getElementById('taskSearchInput')?.value || '').toLowerCase().trim();
        const status = document.getElementById('taskStatusFilter')?.value || '';
        const priority = document.getElementById('taskPriorityFilter')?.value || '';
        const category = document.getElementById('taskCategoryFilter')?.value || 'all';
        const sede = document.getElementById('taskSedeFilter')?.value || 'all';

        filteredTasks = allPublicTasks.filter(task => {
            if (search) {
                const titleMatch = (task.title || '').toLowerCase().includes(search);
                const descMatch = (task.description || '').toLowerCase().includes(search);
                const catMatch = (task.category || '').toLowerCase().includes(search);
                const techMatch = (task.assigned_technician || '').toLowerCase().includes(search);
                if (!titleMatch && !descMatch && !catMatch && !techMatch) return false;
            }

            if (status && task.status !== status) return false;
            if (priority && task.priority !== priority) return false;
            if (category !== 'all' && task.category !== category) return false;
            if (sede !== 'all' && task.sede !== sede && task.sede !== 'Todas') return false;

            return true;
        });

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

        const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
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
        return filteredTasks.filter(task => {
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

        // Días previos
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
                    </div>
                    <div class="day-events-list">
                        ${renderEventPills(dayTasks)}
                    </div>
                </div>
            `;
        }

        // Días del mes
        for (let dayNum = 1; dayNum <= daysInMonth; dayNum++) {
            const currDate = new Date(year, month, dayNum);
            const dateKey = formatDateKey(currDate);
            const isToday = dateKey === todayStr;
            const dayTasks = getTasksForDay(dateKey);

            cellsHtml += `
                <div class="calendar-day-cell ${isToday ? 'today' : ''}" onclick="openDayTasksModal('${dateKey}')">
                    <div class="day-cell-top">
                        <span class="day-number">${dayNum}</span>
                    </div>
                    <div class="day-events-list">
                        ${renderEventPills(dayTasks)}
                    </div>
                </div>
            `;
        }

        // Días siguientes
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

        if (filteredTasks.length === 0) {
            agendaContainer.innerHTML = `
                <div class="calendar-agenda-empty">
                    <div style="font-size: 3rem; margin-bottom: 10px;">📋</div>
                    <h3>No hay tareas con los filtros aplicados</h3>
                    <p>Modifica los filtros de búsqueda o consulta más adelante.</p>
                </div>
            `;
            return;
        }

        const grouped = {};
        filteredTasks.forEach(task => {
            const dateKey = task.due_date ? task.due_date.substring(0, 10) : 'Sin Fecha';
            if (!grouped[dateKey]) grouped[dateKey] = [];
            grouped[dateKey].push(task);
        });

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
                                        <button class="btn-agenda-view" onclick='openTaskDetailModal(${task.id})' title="Ver detalles y checklist">
                                            Ver Detalle ➔
                                        </button>
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

    // =======================================================
    // MODAL DE TAREAS DEL DÍA (PÚBLICO)
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

    function openTaskFromDayModal(taskId) {
        closeDayTasksModal();
        openTaskDetailModal(taskId);
    }

    function openTaskDetailModal(taskId) {
        const task = allPublicTasks.find(t => String(t.id) === String(taskId));
        if (!task) return;

        const modal = document.getElementById('taskDetailModalDialog');
        const headerTitle = document.getElementById('taskDetailModalHeaderTitle');
        const body = document.getElementById('taskDetailBody');

        if (!modal || !body) return;

        if (headerTitle) {
            headerTitle.textContent = '📋 Detalle de la Tarea';
        }

        const isCompleted = task.status === 'completed';
        const priorityBadge = task.priority === 'urgent' ? '🔴 Urgente' : (task.priority === 'high' ? '🟠 Alta' : (task.priority === 'low' ? '🔵 Baja' : '🟡 Media'));
        const statusBadge = isCompleted ? '🟢 Completada' : (task.status === 'in-progress' ? '🔵 En Progreso' : '🟡 Pendiente');
        const formattedDate = task.due_date ? task.due_date.substring(0, 10).split('-').reverse().join('/') : 'Sin fecha límite';

        const checklist = Array.isArray(task.checklist) ? task.checklist : [];
        const metrics = task.checklistMetrics || { total: checklist.length, completed: checklist.filter(i => i.done).length, percent: 0 };
        const percent = metrics.total > 0 ? Math.round((metrics.completed / metrics.total) * 100) : (isCompleted ? 100 : 0);

        let checklistHtml = '';
        if (checklist.length > 0) {
            checklistHtml = `
                <div style="background: #F9FAFB; border: 1px solid #E5E7EB; border-radius: 10px; padding: 14px; margin-bottom: 18px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                        <strong style="font-size: 0.9rem; color: #374151;">📝 Checklist de Verificación (${metrics.completed}/${metrics.total})</strong>
                        <span style="font-size: 0.82rem; font-weight: 700; color: ${percent === 100 ? '#10B981' : '#008B8B'};">${percent}%</span>
                    </div>
                    <div style="width: 100%; height: 7px; background: #E5E7EB; border-radius: 4px; overflow: hidden; margin-bottom: 12px;">
                        <div style="width: ${percent}%; height: 100%; background: ${percent === 100 ? '#10B981' : '#008B8B'};"></div>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 8px; max-height: 220px; overflow-y: auto;">
                        ${checklist.map(item => `
                            <div style="display: flex; align-items: center; gap: 10px; padding: 7px 10px; border-radius: 6px; background: white; border: 1px solid #E5E7EB;">
                                <span>${item.done ? '✅' : '⬜'}</span>
                                <span style="font-size: 0.88rem; color: ${item.done ? '#9CA3AF' : '#1F2937'}; ${item.done ? 'text-decoration: line-through;' : ''}">${escapeHtml(item.text)}</span>
                            </div>
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
                    <span class="task-badge" style="background:${isCompleted ? '#DCFCE7' : (task.status === 'in-progress' ? '#E0F2FE' : '#FEF3C7')}; color:${isCompleted ? '#15803D' : (task.status === 'in-progress' ? '#0369A1' : '#B45309')}; font-weight:700;">${statusBadge}</span>
                    <span class="task-badge badge-priority-${task.priority || 'medium'}">${priorityBadge}</span>
                    <span class="task-badge badge-category">🏢 ${escapeHtml(task.category || 'General')}</span>
                    <span class="task-badge badge-sede">📍 ${escapeHtml(task.sede || 'Todas')}</span>
                    ${task.is_recurring ? '<span class="task-badge badge-recurrence">🔁 Recurrente</span>' : '<span class="task-badge" style="background:#F3F4F6; color:#6B7280;">📌 Única</span>'}
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; padding: 12px 14px; margin-bottom: 16px; font-size: 0.85rem; color: #475569;">
                <div><strong>📅 Fecha Programada:</strong> <span style="color: #1E293B; font-weight: 600;">${formattedDate}</span></div>
                <div><strong>👤 Asignado a:</strong> <span style="color: #1E293B; font-weight: 600;">${escapeHtml(task.assigned_technician || 'Sin asignar')}</span></div>
                <div><strong>✍️ Creada por:</strong> <span style="color: #1E293B; font-weight: 600;">${escapeHtml(task.created_by_name || 'Personal')}</span></div>
            </div>

            ${task.description ? `
                <div style="margin-bottom: 16px;">
                    <strong style="display: block; font-size: 0.86rem; color: #374151; margin-bottom: 4px;">📄 Descripción / Instrucciones:</strong>
                    <div style="background: white; border: 1px solid #E5E7EB; border-radius: 8px; padding: 10px 12px; font-size: 0.88rem; color: #4B5563; line-height: 1.5; white-space: pre-wrap;">${escapeHtml(task.description)}</div>
                </div>
            ` : ''}

            ${checklistHtml}

            <div style="display: flex; justify-content: flex-end; border-top: 1px solid #E5E7EB; padding-top: 14px;">
                <button type="button" onclick="closeTaskDetailModal()" style="padding: 8px 18px; background: #008B8B; color: white; border: none; border-radius: 6px; font-weight: 700; cursor: pointer;">
                    Cerrar
                </button>
            </div>
        `;

        modal.style.display = 'flex';
    }

    function closeTaskDetailModal() {
        const modal = document.getElementById('taskDetailModalDialog');
        if (modal) modal.style.display = 'none';
    }

    function exportTasksToCSV() {
        if (!allPublicTasks || allPublicTasks.length === 0) {
            alert('No hay tareas disponibles para exportar');
            return;
        }

        const deptTitle = boardMetadata ? boardMetadata.department : 'General';
        const generatedAt = new Date().toLocaleString('es-AR');

        const lines = [
            `"Tablero de Tareas y Mantenimiento - Imagen Diagnóstica"`,
            `"Departamento";"${deptTitle}"`,
            `"Fecha de Exportación";"${generatedAt}"`,
            `"Total Tareas";"${filteredTasks.length}"`,
            ``,
            `"LISTADO DE TAREAS"`,
            `"ID";"Título";"Descripción";"Categoría";"Prioridad";"Sede";"Asignado a";"Estado";"Fecha Vencimiento";"Recurrente";"Frecuencia";"Pasos Completados";"Total Pasos";"Progreso %";"Creado Por"`
        ];

        function formatRecurrenceLabel(interval) {
            if (!interval || interval === 'none') return '📌 Única';
            if (interval === 'daily') return 'Diaria (Cada día)';
            if (interval === 'workweek') return 'Semana laboral (Lun a Vie)';
            if (interval === 'weekly') return 'Semanal (Cada 7 días)';
            if (interval === 'biweekly') return 'Quincenal (Cada 14 días)';
            if (interval === 'monthly') return 'Mensual (Cada mes)';
            if (interval === 'quarterly') return 'Trimestral (Cada 3 meses)';
            if (interval === 'yearly') return 'Anual (Cada año)';
            if (typeof interval === 'string' && interval.startsWith('custom:')) {
                const dayNames = { '0': 'Dom', '1': 'Lun', '2': 'Mar', '3': 'Mié', '4': 'Jue', '5': 'Vie', '6': 'Sáb' };
                const raw = interval.replace('custom:', '').split(',').map(s => s.trim()).filter(Boolean);
                if (raw.length === 5 && ['1', '2', '3', '4', '5'].every(d => raw.includes(d))) {
                    return 'Semana laboral (Lun a Vie)';
                }
                const sorted = raw.sort((a, b) => (a === '0' ? 7 : parseInt(a, 10)) - (b === '0' ? 7 : parseInt(b, 10)));
                return `Días: ${sorted.map(d => dayNames[d] || d).join(', ')}`;
            }
            return interval;
        }

        filteredTasks.forEach(t => {
            const checklist = Array.isArray(t.checklist) ? t.checklist : [];
            const metrics = t.checklistMetrics || { total: checklist.length, completed: checklist.filter(i => i.done).length, percent: 0 };
            const dueDateStr = t.due_date ? t.due_date.substring(0, 10) : 'Sin fecha';
            const statusLabel = t.status === 'completed' ? 'Completada' : (t.status === 'in-progress' ? 'En Progreso' : 'Pendiente');
            const recLabel = t.is_recurring ? formatRecurrenceLabel(t.recurrence_interval) : 'No';

            lines.push(`"${t.id}";"${(t.title || '').replace(/"/g, '""')}";"${(t.description || '').replace(/"/g, '""')}";"${t.category || 'General'}";"${t.priority || 'medium'}";"${t.sede || 'Todas'}";"${t.assigned_technician || 'Sin asignar'}";"${statusLabel}";"${dueDateStr}";"${t.is_recurring ? 'SÍ' : 'NO'}";"${recLabel}";"${metrics.completed}";"${metrics.total}";"${metrics.percent}%";"${t.created_by_name || ''}"`);
        });

        const csvContent = '\uFEFF' + lines.join('\r\n');
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        const safeName = (deptTitle || 'tareas').toLowerCase().replace(/[^a-z0-9]/g, '_');
        link.setAttribute('href', url);
        link.setAttribute('download', `tablero_tareas_${safeName}_${formatDateKey(new Date())}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
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

    function showFatalError(msg) {
        const container = document.querySelector('.public-container');
        if (container) {
            container.innerHTML = `
                <div style="background: white; border-radius: 12px; padding: 3rem; text-align: center; border: 1px solid #E5E7EB; max-width: 600px; margin: 3rem auto; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
                    <div style="font-size: 3rem; margin-bottom: 1rem;">🔒</div>
                    <h2 style="font-size: 1.5rem; color: #1F2937; margin-bottom: 0.5rem;">Enlace No Disponible</h2>
                    <p style="color: #6B7280; font-size: 0.95rem; margin-bottom: 1.5rem;">${escapeHtml(msg)}</p>
                    <p style="color: #9CA3AF; font-size: 0.85rem;">Si crees que esto es un error, solicita un nuevo enlace público al administrador del sistema.</p>
                </div>
            `;
        }
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    // Exponer funciones globales
    window.loadPublicBoardData = loadPublicBoardData;
    window.applyFilters = applyFilters;
    window.setCalendarView = setCalendarView;
    window.calendarGoToday = calendarGoToday;
    window.calendarPrev = calendarPrev;
    window.calendarNext = calendarNext;
    window.openTaskDetailModal = openTaskDetailModal;
    window.closeTaskDetailModal = closeTaskDetailModal;
    window.openDayTasksModal = openDayTasksModal;
    window.closeDayTasksModal = closeDayTasksModal;
    window.openTaskFromDayModal = openTaskFromDayModal;
    window.exportTasksToCSV = exportTasksToCSV;

    document.addEventListener('DOMContentLoaded', () => {
        const yr = document.getElementById('currentYear');
        if (yr) yr.textContent = new Date().getFullYear();
        loadPublicBoardData();
    });
})();
