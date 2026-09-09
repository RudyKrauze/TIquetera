/**
 * REPORTES.JS - VERSIÓN MODERNA
 * Sistema de reportes con gráficos mejorados
 * Incluye: zoom, animaciones fluidas, tooltips mejorados
 */

// ============================================
// ESTADO GLOBAL
// ============================================
let currentPeriod = '30d';
let currentDepartment = 'all';
let statsData = null;
let trendsData = null;
let departmentsData = null;
let kpisData = null;
let trendsChart = null;
let isLoading = false;
let lastUpdate = null;

// Paleta de colores moderna (tema claro)
const COLORS = {
    primary: '#4F46E5',       // Índigo vibrante
    secondary: '#10B981',     // Esmeralda
    warning: '#F59E0B',       // Ámbar
    danger: '#EF4444',        // Rojo
    text: '#1F2937',
    textMuted: '#6B7280',
    background: '#F9FAFB',
    surface: '#FFFFFF',
    border: '#E5E7EB',
    grid: 'rgba(156, 163, 175, 0.2)'
};

// ============================================
// INICIALIZACIÓN
// ============================================
document.addEventListener('DOMContentLoaded', () => {
    initializeSelectors();
    loadAllData();

    // Actualización automática cada 5 minutos
    setInterval(() => {
        if (!isLoading) {
            loadAllData(true);
        }
    }, 5 * 60 * 1000);
});

function initializeSelectors() {
    const periodSelect = document.getElementById('periodSelect');
    const departmentSelect = document.getElementById('departmentSelect');

    if (periodSelect) {
        periodSelect.value = currentPeriod;
        updateDateRangeDisplay();
        periodSelect.addEventListener('change', (e) => {
            currentPeriod = e.target.value;
            updateDateRangeDisplay();
            loadAllData();
        });
    }

    if (departmentSelect) {
        departmentSelect.addEventListener('change', (e) => {
            currentDepartment = e.target.value;
            loadAllData();
        });
        loadDepartmentOptions();
    }
}

function applyMaintenanceRoleReportSettings() {
    currentDepartment = 'Mantenimiento';
    const deptSelect = document.getElementById('departmentSelect');
    if (deptSelect) {
        deptSelect.innerHTML = '<option value="Mantenimiento" selected>🔧 Mantenimiento</option>';
        deptSelect.disabled = true;
    }
    const pageTitle = document.querySelector('.navbar-brand h1');
    if (pageTitle) {
        pageTitle.textContent = '📊 Reportes - Mantenimiento';
    }
}
window.applyMaintenanceRoleReportSettings = applyMaintenanceRoleReportSettings;

function applySupportRoleReportSettings() {
    currentDepartment = 'Sistemas';
    const deptSelect = document.getElementById('departmentSelect');
    if (deptSelect) {
        deptSelect.innerHTML = '<option value="Sistemas" selected>💻 Sistemas & Soporte</option>';
        deptSelect.disabled = true;
    }
    const pageTitle = document.querySelector('.navbar-brand h1');
    if (pageTitle) {
        pageTitle.textContent = '📊 Reportes - Soporte Técnico';
    }
}
window.applySupportRoleReportSettings = applySupportRoleReportSettings;

function applyRrhhRoleReportSettings() {
    currentDepartment = 'RRHH';
    const deptSelect = document.getElementById('departmentSelect');
    if (deptSelect) {
        deptSelect.innerHTML = '<option value="RRHH" selected>👥 Recursos Humanos</option>';
        deptSelect.disabled = true;
    }
    const pageTitle = document.querySelector('.navbar-brand h1');
    if (pageTitle) {
        pageTitle.textContent = '📊 Reportes - Recursos Humanos';
    }
}
window.applyRrhhRoleReportSettings = applyRrhhRoleReportSettings;

function applyComprasRoleReportSettings() {
    currentDepartment = 'Compras';
    const deptSelect = document.getElementById('departmentSelect');
    if (deptSelect) {
        deptSelect.innerHTML = '<option value="Compras" selected>🛒 Compras e Insumos</option>';
        deptSelect.disabled = true;
    }
    const pageTitle = document.querySelector('.navbar-brand h1');
    if (pageTitle) {
        pageTitle.textContent = '📊 Reportes - Compras e Insumos';
    }
}
window.applyComprasRoleReportSettings = applyComprasRoleReportSettings;

async function loadDepartmentOptions() {
    try {
        if (window.currentUser && window.currentUser.role === 'mantenimiento') {
            applyMaintenanceRoleReportSettings();
            return;
        }
        if (window.currentUser && window.currentUser.role === 'support') {
            applySupportRoleReportSettings();
            return;
        }
        if (window.currentUser && window.currentUser.role === 'rrhh') {
            applyRrhhRoleReportSettings();
            return;
        }
        if (window.currentUser && window.currentUser.role === 'compras') {
            applyComprasRoleReportSettings();
            return;
        }

        const response = await fetchWithAuth('/api/reports/departments');
        if (response.ok) {
            const departments = await response.json();
            const select = document.getElementById('departmentSelect');
            if (select) {
                if (window.currentUser && window.currentUser.role === 'mantenimiento') {
                    select.innerHTML = '<option value="Mantenimiento" selected>🔧 Mantenimiento</option>';
                    select.disabled = true;
                    currentDepartment = 'Mantenimiento';
                    return;
                }
                if (window.currentUser && window.currentUser.role === 'support') {
                    select.innerHTML = '<option value="Sistemas" selected>💻 Sistemas & Soporte</option>';
                    select.disabled = true;
                    currentDepartment = 'Sistemas';
                    return;
                }
                if (window.currentUser && window.currentUser.role === 'rrhh') {
                    select.innerHTML = '<option value="RRHH" selected>👥 Recursos Humanos</option>';
                    select.disabled = true;
                    currentDepartment = 'RRHH';
                    return;
                }
                if (window.currentUser && window.currentUser.role === 'compras') {
                    select.innerHTML = '<option value="Compras" selected>🛒 Compras e Insumos</option>';
                    select.disabled = true;
                    currentDepartment = 'Compras';
                    return;
                }

                const allOption = select.querySelector('option[value="all"]');
                select.innerHTML = '';
                if (allOption) select.appendChild(allOption);

                departments.forEach(dept => {
                    const option = document.createElement('option');
                    option.value = dept;
                    option.textContent = dept;
                    select.appendChild(option);
                });
            }
        }
    } catch (error) {

    }
}

// ============================================
// FETCH CON AUTENTICACIÓN
// ============================================
async function fetchWithAuth(url, options = {}) {
    return fetch(url, {
        ...options,
        credentials: 'include',
        headers: {
            'Content-Type': 'application/json',
            ...options.headers
        }
    });
}

// ============================================
// CARGA DE DATOS
// ============================================
async function loadAllData(silent = false) {
    if (isLoading) return;
    isLoading = true;

    if (!silent) {
        showLoadingState();
    }

    try {
        const params = new URLSearchParams({
            period: currentPeriod,
            department: currentDepartment
        });

        const [statsRes, trendsRes, deptRes, kpisRes] = await Promise.all([
            fetchWithAuth(`/api/reports/stats?${params}`),
            fetchWithAuth(`/api/reports/trends?${params}`),
            fetchWithAuth(`/api/reports/by-department?${params}`),
            fetchWithAuth(`/api/reports/kpis?${params}`)
        ]);

        if (statsRes.status === 401 || statsRes.status === 403) {
            window.location.href = '/?error=auth_required';
            return;
        }

        statsData = await statsRes.json();
        trendsData = await trendsRes.json();
        departmentsData = await deptRes.json();
        kpisData = await kpisRes.json();

        renderKPIs();
        renderTrendsChart();
        renderDepartmentsStats();
        renderTable();
        updateLastUpdate();

    } catch (error) {

        showError('Error al cargar los datos. Intenta nuevamente.');
    } finally {
        isLoading = false;
        hideLoadingState();
    }
}

function showLoadingState() {
    document.querySelectorAll('.chart-card, .table-section, .tickets-section').forEach(el => {
        el.style.opacity = '0.6';
        el.style.pointerEvents = 'none';
    });
}

function hideLoadingState() {
    document.querySelectorAll('.chart-card, .table-section, .tickets-section').forEach(el => {
        el.style.opacity = '1';
        el.style.pointerEvents = 'auto';
    });
}

function showError(message) {
    const toast = document.createElement('div');
    toast.className = 'toast toast-error';
    toast.innerHTML = `<span>❌</span> ${message}`;
    toast.style.cssText = 'position: fixed; bottom: 20px; right: 20px; z-index: 9999; padding: 12px 20px; border-radius: 8px; background: #EF4444; color: white; font-weight: 500; box-shadow: 0 4px 12px rgba(0,0,0,0.15); animation: slideIn 0.3s ease;';
    document.body.appendChild(toast);
    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease forwards';
        setTimeout(() => toast.remove(), 300);
    }, 5000);
}

function showSuccess(message) {
    const toast = document.createElement('div');
    toast.className = 'toast toast-success';
    toast.innerHTML = `<span>✅</span> ${message}`;
    toast.style.cssText = 'position: fixed; bottom: 20px; right: 20px; z-index: 9999; padding: 12px 20px; border-radius: 8px; background: #10B981; color: white; font-weight: 500; box-shadow: 0 4px 12px rgba(0,0,0,0.15); animation: slideIn 0.3s ease;';
    document.body.appendChild(toast);
    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease forwards';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

function updateLastUpdate() {
    lastUpdate = new Date();
    const el = document.getElementById('lastUpdate');
    if (el) {
        el.textContent = `Actualizado: ${lastUpdate.toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' })}`;
    }
}

// ============================================
// RENDERIZADO DE KPIs CON ANIMACIONES
// ============================================
function renderKPIs() {
    if (!statsData || !kpisData) return;

    // Total recibidos
    animateValue('kpiTotal', statsData.total);
    updateChangeIndicator('kpiTotalChange', statsData.changePercent);

    // Cerrados
    animateValue('kpiClosed', statsData.closed);
    const closedRateEl = document.getElementById('kpiClosedRate');
    if (closedRateEl) {
        closedRateEl.textContent = `${kpisData.resolutionRate}% tasa`;
        closedRateEl.className = 'kpi-change ' + (kpisData.resolutionRate >= 80 ? 'positive' : kpisData.resolutionRate >= 50 ? 'neutral' : 'negative');
    }

    // Pendientes
    animateValue('kpiPending', statsData.pending);
    const urgentCount = statsData.unassigned || 0;
    const urgentEl = document.getElementById('kpiPendingUrgent');
    if (urgentEl) {
        urgentEl.textContent = `${urgentCount} sin asignar`;
        urgentEl.className = 'kpi-change ' + (urgentCount === 0 ? 'positive' : urgentCount <= 5 ? 'neutral' : 'negative');
    }

    // Tiempo promedio
    const avgHours = parseFloat(kpisData.avgResolutionHours) || 0;
    const timeEl = document.getElementById('kpiTime');
    if (timeEl) {
        if (avgHours < 24) {
            timeEl.textContent = `${avgHours.toFixed(1)}h`;
        } else {
            timeEl.textContent = `${(avgHours / 24).toFixed(1)}d`;
        }
    }
}

function animateValue(elementId, endValue) {
    const el = document.getElementById(elementId);
    if (!el) return;

    const startValue = parseInt(el.textContent) || 0;
    const duration = 800;
    const startTime = performance.now();

    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        // Easing: easeOutExpo for smooth deceleration
        const easeOut = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
        const current = Math.round(startValue + (endValue - startValue) * easeOut);
        el.textContent = current.toLocaleString('es-AR');

        if (progress < 1) {
            requestAnimationFrame(update);
        }
    }

    requestAnimationFrame(update);
}

function updateChangeIndicator(elementId, changePercent) {
    const el = document.getElementById(elementId);
    if (!el) return;

    el.classList.remove('positive', 'negative', 'neutral');

    if (changePercent > 0) {
        el.innerHTML = `<span class="change-arrow">↑</span> ${changePercent}%`;
        el.classList.add('positive');
    } else if (changePercent < 0) {
        el.innerHTML = `<span class="change-arrow">↓</span> ${Math.abs(changePercent)}%`;
        el.classList.add('negative');
    } else {
        el.innerHTML = `<span class="change-arrow">→</span> 0%`;
        el.classList.add('neutral');
    }
}

// ============================================
// GRÁFICO DE TENDENCIAS - DISEÑO MODERNO
// ============================================
function renderTrendsChart() {
    if (!trendsData || trendsData.length === 0) {
        showEmptyChart();
        return;
    }

    const ctx = document.getElementById('trendsChart');
    if (!ctx) return;

    // Usar colores del tema claro
    const colors = COLORS;

    // Preparar datos
    const labels = trendsData.map(d => formatDate(d.date));
    const createdData = trendsData.map(d => d.created);
    const closedData = trendsData.map(d => d.closed);
    const pendingData = trendsData.map(d => d.pending);

    // Destruir gráfico existente
    if (trendsChart) {
        trendsChart.destroy();
    }

    // Crear gradientes
    const context = ctx.getContext('2d');

    const gradientCreated = context.createLinearGradient(0, 0, 0, 300);
    gradientCreated.addColorStop(0, 'rgba(79, 70, 229, 0.3)');
    gradientCreated.addColorStop(1, 'rgba(79, 70, 229, 0.0)');

    const gradientClosed = context.createLinearGradient(0, 0, 0, 300);
    gradientClosed.addColorStop(0, 'rgba(16, 185, 129, 0.3)');
    gradientClosed.addColorStop(1, 'rgba(16, 185, 129, 0.0)');

    const gradientPending = context.createLinearGradient(0, 0, 0, 300);
    gradientPending.addColorStop(0, 'rgba(245, 158, 11, 0.3)');
    gradientPending.addColorStop(1, 'rgba(245, 158, 11, 0.0)');

    // Crear nuevo gráfico con configuración moderna
    trendsChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Creados',
                    data: createdData,
                    borderColor: colors.primary,
                    backgroundColor: gradientCreated,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 8,
                    pointHoverBackgroundColor: colors.primary,
                    pointHoverBorderColor: '#fff',
                    pointHoverBorderWidth: 3,
                    order: 1
                },
                {
                    label: 'Cerrados',
                    data: closedData,
                    borderColor: colors.secondary,
                    backgroundColor: gradientClosed,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 8,
                    pointHoverBackgroundColor: colors.secondary,
                    pointHoverBorderColor: '#fff',
                    pointHoverBorderWidth: 3,
                    order: 2
                },
                {
                    label: 'Pendientes',
                    data: pendingData,
                    borderColor: colors.warning,
                    backgroundColor: gradientPending,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 8,
                    pointHoverBackgroundColor: colors.warning,
                    pointHoverBorderColor: '#fff',
                    pointHoverBorderWidth: 3,
                    order: 3
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                intersect: false,
                mode: 'index'
            },
            animation: {
                duration: 1200,
                easing: 'easeOutQuart'
            },
            plugins: {
                legend: {
                    position: 'top',
                    align: 'end',
                    labels: {
                        usePointStyle: true,
                        pointStyle: 'circle',
                        padding: 20,
                        font: {
                            size: 12,
                            weight: '600',
                            family: "'Montserrat', sans-serif"
                        },
                        color: colors.text
                    }
                },
                tooltip: {
                    enabled: true,
                    backgroundColor: 'rgba(255, 255, 255, 0.98)',
                    titleColor: colors.text,
                    bodyColor: colors.textMuted,
                    borderColor: colors.border,
                    borderWidth: 1,
                    padding: 16,
                    cornerRadius: 12,
                    titleFont: {
                        size: 14,
                        weight: '700',
                        family: "'Montserrat', sans-serif"
                    },
                    bodyFont: {
                        size: 13,
                        family: "'Montserrat', sans-serif"
                    },
                    displayColors: true,
                    boxWidth: 12,
                    boxHeight: 12,
                    boxPadding: 6,
                    usePointStyle: true,
                    callbacks: {
                        title: function (context) {
                            return `📅 ${context[0].label}`;
                        },
                        label: function (context) {
                            const icons = { 'Creados': '📥', 'Cerrados': '✅', 'Pendientes': '⏳' };
                            const icon = icons[context.dataset.label] || '';
                            return ` ${icon} ${context.dataset.label}: ${context.parsed.y} tickets`;
                        },
                        afterBody: function (context) {
                            const total = context.reduce((sum, c) => sum + c.parsed.y, 0);
                            return [`\n📊 Total: ${total} tickets`];
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: colors.grid,
                        drawBorder: false
                    },
                    border: {
                        display: false
                    },
                    ticks: {
                        precision: 0,
                        padding: 10,
                        font: {
                            size: 11,
                            weight: '500',
                            family: "'Montserrat', sans-serif"
                        },
                        color: colors.textMuted
                    }
                },
                x: {
                    grid: {
                        display: false,
                        drawBorder: false
                    },
                    border: {
                        display: false
                    },
                    ticks: {
                        padding: 10,
                        maxRotation: 0,
                        font: {
                            size: 11,
                            weight: '500',
                            family: "'Montserrat', sans-serif"
                        },
                        color: colors.textMuted,
                        maxTicksLimit: 10
                    }
                }
            }
        }
    });
}

function showEmptyChart() {
    const container = document.querySelector('.chart-container');
    if (container) {
        container.innerHTML = `
            <div class="empty-state" style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; color: var(--chart-text-muted, #6B7280);">
                <div style="font-size: 4rem; margin-bottom: 1rem; opacity: 0.5;">📊</div>
                <div style="font-size: 1.1rem; font-weight: 600;">No hay datos disponibles</div>
                <div style="font-size: 0.9rem; margin-top: 0.5rem;">Selecciona otro período o departamento</div>
            </div>
        `;
    }
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleDateString('es-AR', { day: '2-digit', month: 'short' });
}

// ============================================
// EXPORTAR GRÁFICO COMO IMAGEN HD
// ============================================
function exportChartAsImage() {
    if (!trendsChart) {
        showError('No hay gráfico para exportar');
        return;
    }

    // Crear canvas de alta resolución
    const canvas = trendsChart.canvas;
    const scale = 2; // 2x para alta resolución

    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = canvas.width * scale;
    tempCanvas.height = canvas.height * scale;

    const tempCtx = tempCanvas.getContext('2d');
    tempCtx.scale(scale, scale);
    tempCtx.fillStyle = '#FFFFFF';
    tempCtx.fillRect(0, 0, canvas.width, canvas.height);
    tempCtx.drawImage(canvas, 0, 0);

    // Descargar
    const link = document.createElement('a');
    link.download = `grafico_tickets_${currentPeriod}_${new Date().toISOString().split('T')[0]}.png`;
    link.href = tempCanvas.toDataURL('image/png', 1.0);
    link.click();

    showSuccess('Gráfico exportado en alta resolución');
}

// ============================================
// ESTADÍSTICAS POR DEPARTAMENTO
// ============================================
function renderDepartmentsStats() {
    const container = document.getElementById('deptStatsList');
    if (!container || !departmentsData) return;

    if (departmentsData.length === 0) {
        container.innerHTML = `
            <div class="empty-state" style="text-align: center; padding: 2rem; color: var(--chart-text-muted, #6B7280);">
                <div style="font-size: 2rem; margin-bottom: 0.5rem;">🏢</div>
                <div>Sin datos por departamento</div>
            </div>
        `;
        return;
    }

    const colors = COLORS;
    const topDepts = departmentsData.slice(0, 5);
    const maxTotal = Math.max(...topDepts.map(d => d.total));

    container.innerHTML = topDepts.map((dept, i) => {
        const barWidth = (dept.total / maxTotal * 100).toFixed(1);
        const rateColor = dept.resolutionRate >= 80 ? colors.secondary : dept.resolutionRate >= 50 ? colors.warning : colors.danger;

        return `
            <div class="dept-stat-item" style="animation: fadeInUp 0.3s ease ${i * 0.1}s both;">
                <div class="dept-info">
                    <span class="dept-name">${escapeHtml(dept.department)}</span>
                    <div class="dept-bar-container">
                        <div class="dept-bar" style="width: ${barWidth}%; background: linear-gradient(90deg, ${colors.primary}, ${colors.secondary});"></div>
                    </div>
                </div>
                <div class="dept-count">
                    <span class="count">${dept.total}</span>
                    <span class="rate" style="background: ${rateColor}20; color: ${rateColor};">${dept.resolutionRate}%</span>
                </div>
            </div>
        `;
    }).join('');
}

// ============================================
// TABLA DE DATOS
// ============================================
function renderTable() {
    const tbody = document.getElementById('reportsTableBody');
    if (!tbody || !departmentsData) return;

    if (departmentsData.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 2rem; color: var(--chart-text-muted, #6B7280);">
                    No hay datos disponibles
                </td>
            </tr>
        `;
        return;
    }

    const colors = COLORS;

    tbody.innerHTML = departmentsData.map((dept, i) => {
        const rateColor = dept.resolutionRate >= 80 ? colors.secondary : dept.resolutionRate >= 50 ? colors.warning : colors.danger;

        return `
            <tr style="animation: fadeIn 0.2s ease ${i * 0.05}s both;">
                <td><strong>${escapeHtml(dept.department)}</strong></td>
                <td class="text-center">${dept.total}</td>
                <td class="text-center" style="color: ${colors.secondary}; font-weight: 600;">${dept.closed}</td>
                <td class="text-center" style="color: ${colors.warning}; font-weight: 600;">${dept.open + dept.inProgress}</td>
                <td class="text-center">${dept.avgResolutionHours}h</td>
                <td>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <div class="progress-bar" style="flex: 1;">
                            <div class="progress-bar-fill" style="width: ${dept.resolutionRate}%; background: linear-gradient(90deg, ${colors.primary}, ${rateColor});"></div>
                        </div>
                        <span style="min-width: 45px; font-weight: 600; color: ${rateColor};">${dept.resolutionRate}%</span>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

// ============================================
// EXPORTACIÓN PDF Y CSV
// ============================================
function exportToPDF() {
    window.print();
}

function exportReportToCSV() {
    if (!statsData || !kpisData) {
        showError('No hay datos disponibles para exportar');
        return;
    }

    const deptName = currentDepartment === 'all' ? 'Todos los Departamentos' : currentDepartment;
    const periodLabel = getDateRangeString(currentPeriod);
    const generatedAt = new Date().toLocaleString('es-AR');

    const lines = [
        `"Reporte de Métricas - Imagen Diagnóstica"`,
        `"Período";"${currentPeriod} (${periodLabel})"`,
        `"Departamento/Alcance";"${deptName}"`,
        `"Fecha de Generación";"${generatedAt}"`,
        ``,
        `"RESUMEN GENERAL (KPIs)"`,
        `"Métrica";"Valor"`,
        `"Total Tickets Recibidos";"${statsData.total || 0}"`,
        `"Tickets Cerrados";"${statsData.closed || 0}"`,
        `"Tickets Pendientes/En Curso";"${statsData.pending || 0}"`,
        `"Tickets Sin Asignar";"${statsData.unassigned || 0}"`,
        `"Tasa de Resolución";"${kpisData.resolutionRate || 0}%"`,
        `"Tiempo Promedio de Resolución";"${kpisData.avgResolutionHours || 0} horas"`,
        ``,
        `"DESGLOSE POR DEPARTAMENTO"`,
        `"Departamento";"Total Tickets";"Cerrados";"Pendientes";"Tiempo Promedio (h)";"Tasa Resolución"`
    ];

    if (Array.isArray(departmentsData) && departmentsData.length > 0) {
        departmentsData.forEach(d => {
            lines.push(`"${d.department}";"${d.total}";"${d.closed}";"${d.open + d.inProgress}";"${d.avgResolutionHours}";"${d.resolutionRate}%"`);
        });
    } else {
        lines.push(`"${deptName}";"${statsData.total}";"${statsData.closed}";"${statsData.pending}";"${kpisData.avgResolutionHours}";"${kpisData.resolutionRate}%"`);
    }

    lines.push(``);
    lines.push(`"TENDENCIA HISTÓRICA DE TICKETS"`);
    lines.push(`"Fecha";"Tickets Creados";"Tickets Cerrados";"Tickets Pendientes"`);

    if (Array.isArray(trendsData) && trendsData.length > 0) {
        trendsData.forEach(t => {
            lines.push(`"${formatDate(t.date)}";"${t.created || 0}";"${t.closed || 0}";"${t.pending || 0}"`);
        });
    }

    const csvContent = '\uFEFF' + lines.join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    const safeDept = currentDepartment.toLowerCase().replace(/[^a-z0-9]/g, '_');
    link.setAttribute('href', url);
    link.setAttribute('download', `reporte_metricas_${safeDept}_${currentPeriod}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    showSuccess('Reporte de métricas exportado exitosamente');
}

// ============================================
// REFRESCAR DATOS
// ============================================
function refreshData() {
    loadAllData();
}

// ============================================
// UTILIDADES
// ============================================
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================
// ESTILOS DINÁMICOS PARA ANIMACIONES
// ============================================
const styleSheet = document.createElement('style');
styleSheet.textContent = `
    @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
    }
    
    @keyframes fadeInUp {
        from {
            opacity: 0;
            transform: translateY(10px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
    
    @keyframes slideIn {
        from {
            opacity: 0;
            transform: translateX(20px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }
    
    @keyframes slideOut {
        from {
            opacity: 1;
            transform: translateX(0);
        }
        to {
            opacity: 0;
            transform: translateX(20px);
        }
    }
    
    .change-arrow {
        display: inline-block;
        margin-right: 2px;
    }
    
    .dept-info {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 6px;
    }
    
    .dept-bar-container {
        width: 100%;
        height: 4px;
        background: var(--chart-border, #E5E7EB);
        border-radius: 2px;
        overflow: hidden;
    }
    
    .dept-bar {
        height: 100%;
        border-radius: 2px;
        transition: width 0.5s ease;
    }
    
`;
document.head.appendChild(styleSheet);

function getDateRangeString(period) {
    const daysMap = {
        '1d': 1,
        '7d': 7,
        '30d': 30,
        '90d': 90,
        '180d': 180,
        '365d': 365
    };
    const days = daysMap[period] || 30;
    const now = new Date();
    const start = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

    const pad = (n) => String(n).padStart(2, '0');
    return `${pad(start.getDate())}/${pad(start.getMonth() + 1)}/${start.getFullYear()} al ${pad(now.getDate())}/${pad(now.getMonth() + 1)}/${now.getFullYear()}`;
}

function updateDateRangeDisplay() {
    const rangeText = getDateRangeString(currentPeriod);
    let badge = document.getElementById('reportDateRangeBadge');
    if (!badge) {
        const lastUpdateEl = document.getElementById('lastUpdate');
        if (lastUpdateEl && lastUpdateEl.parentNode) {
            badge = document.createElement('span');
            badge.id = 'reportDateRangeBadge';
            badge.style.cssText = 'font-size: 0.85rem; font-weight: 700; color: #008B8B; background: #E6FCF5; border: 1px solid #C3FAE8; padding: 3px 10px; border-radius: 20px; margin-left: 10px;';
            lastUpdateEl.parentNode.appendChild(badge);
        }
    }
    if (badge) {
        badge.textContent = `📅 ${rangeText}`;
    }
}

// ============================================
// MODAL DE ENLACES PÚBLICOS COMPARTIBLES
// ============================================
function openShareModal() {
    const modal = document.getElementById('shareReportModal');
    if (!modal) return;

    const isMaint = window.currentUser && window.currentUser.role === 'mantenimiento';
    const isSupport = window.currentUser && window.currentUser.role === 'support';
    const isRrhh = window.currentUser && window.currentUser.role === 'rrhh';
    const isCompras = window.currentUser && window.currentUser.role === 'compras';

    // Poblar departamentos en el modal
    const mainDeptSelect = document.getElementById('departmentSelect');
    const shareDeptSelect = document.getElementById('shareDepartmentSelect');
    if (shareDeptSelect) {
        if (isMaint) {
            shareDeptSelect.innerHTML = '<option value="Mantenimiento" selected>🔧 Mantenimiento</option>';
            shareDeptSelect.disabled = true;
        } else if (isSupport) {
            shareDeptSelect.innerHTML = '<option value="Sistemas" selected>💻 Sistemas & Soporte</option>';
            shareDeptSelect.disabled = true;
        } else if (isRrhh) {
            shareDeptSelect.innerHTML = '<option value="RRHH" selected>👥 Recursos Humanos</option>';
            shareDeptSelect.disabled = true;
        } else if (isCompras) {
            shareDeptSelect.innerHTML = '<option value="Compras" selected>🛒 Compras e Insumos</option>';
            shareDeptSelect.disabled = true;
        } else if (mainDeptSelect) {
            shareDeptSelect.innerHTML = mainDeptSelect.innerHTML;
            shareDeptSelect.value = mainDeptSelect.value || 'all';
            shareDeptSelect.disabled = false;
        }
    }

    const sharePeriodSelect = document.getElementById('sharePeriodSelect');
    if (sharePeriodSelect) {
        sharePeriodSelect.value = currentPeriod || '7d';
        
        // Vista previa de rango en el modal
        let preview = document.getElementById('sharePeriodRangePreview');
        if (!preview) {
            preview = document.createElement('small');
            preview.id = 'sharePeriodRangePreview';
            preview.style.cssText = 'color: #008B8B; font-weight: 600; display: block; margin-top: 4px; font-size: 0.8rem;';
            sharePeriodSelect.parentNode.appendChild(preview);
        }
        preview.textContent = `📅 Rango: ${getDateRangeString(sharePeriodSelect.value)}`;

        sharePeriodSelect.onchange = () => {
            if (preview) {
                preview.textContent = `📅 Rango: ${getDateRangeString(sharePeriodSelect.value)}`;
            }
        };
    }

    const shareTitleInput = document.getElementById('shareTitleInput');
    if (shareTitleInput && !shareTitleInput.value) {
        if (isMaint) {
            shareTitleInput.placeholder = 'Ej: Reporte Semanal de Mantenimiento';
        } else if (isSupport) {
            shareTitleInput.placeholder = 'Ej: Reporte Semanal de Soporte Técnico';
        } else if (isRrhh) {
            shareTitleInput.placeholder = 'Ej: Reporte Semanal de Recursos Humanos';
        } else if (isCompras) {
            shareTitleInput.placeholder = 'Ej: Reporte Semanal de Compras';
        }
    }

    const resultBox = document.getElementById('newShareResult');
    if (resultBox) resultBox.style.display = 'none';

    modal.style.display = 'flex';
    loadSharedLinksHistory();
}

function closeShareModal() {
    const modal = document.getElementById('shareReportModal');
    if (modal) modal.style.display = 'none';
}

async function generateSharedReportLink() {
    const isMaint = window.currentUser && window.currentUser.role === 'mantenimiento';
    const isSupport = window.currentUser && window.currentUser.role === 'support';
    const isRrhh = window.currentUser && window.currentUser.role === 'rrhh';
    const isCompras = window.currentUser && window.currentUser.role === 'compras';
    const period = document.getElementById('sharePeriodSelect')?.value || '7d';
    
    let department = 'all';
    if (isMaint) {
        department = 'Mantenimiento';
    } else if (isSupport) {
        department = 'Sistemas';
    } else if (isRrhh) {
        department = 'RRHH';
    } else if (isCompras) {
        department = 'Compras';
    } else {
        department = document.getElementById('shareDepartmentSelect')?.value || 'all';
    }

    const title = document.getElementById('shareTitleInput')?.value || '';
    const expireInDays = document.getElementById('shareExpirationSelect')?.value || '7';

    try {
        const response = await fetchWithAuth('/api/reports/share', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                title,
                period,
                department,
                expireInDays: parseInt(expireInDays, 10)
            })
        });

        const data = await response.json();
        if (!response.ok || !data.success) {
            throw new Error(data.error || 'Error al generar enlace');
        }

        const resultBox = document.getElementById('newShareResult');
        const urlInput = document.getElementById('generatedShareUrl');
        const openBtn = document.getElementById('openShareUrlBtn');

        if (resultBox && urlInput && openBtn) {
            urlInput.value = data.url;
            openBtn.href = data.url;
            resultBox.style.display = 'block';
        }

        showSuccess('¡Enlace público generado con éxito!');
        loadSharedLinksHistory();
    } catch (err) {
        showError(err.message || 'Error al generar enlace');
    }
}

function copyShareUrlToClipboard() {
    const urlInput = document.getElementById('generatedShareUrl');
    if (!urlInput || !urlInput.value) return;

    const copyBtn = document.getElementById('btnCopyGeneratedShare');
    const copyFn = typeof window.copyToClipboard === 'function' ? window.copyToClipboard : fallbackDirectCopy;

    copyFn(urlInput.value, '¡Enlace público copiado al portapapeles!')
        .then(() => {
            if (copyBtn) {
                const prev = copyBtn.innerHTML;
                copyBtn.innerHTML = '✅ Copiado';
                setTimeout(() => { copyBtn.innerHTML = prev; }, 2000);
            }
        })
        .catch(() => {
            showError('No se pudo copiar automáticamente. Por favor selecciónalo y cópialo manualmente.');
        });
}

function copySpecificShareUrl(url, btnElement) {
    if (!url) return;
    const copyFn = typeof window.copyToClipboard === 'function' ? window.copyToClipboard : fallbackDirectCopy;

    copyFn(url, '¡Enlace público copiado al portapapeles!')
        .then(() => {
            if (btnElement) {
                const prev = btnElement.innerHTML;
                btnElement.innerHTML = '✅';
                setTimeout(() => { btnElement.innerHTML = prev; }, 2000);
            }
        })
        .catch(() => {
            showError('No se pudo copiar automáticamente.');
        });
}

function fallbackDirectCopy(text, msg) {
    try {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed';
        ta.style.top = '0';
        ta.style.left = '0';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.focus();
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
        showSuccess(msg || 'Copiado al portapapeles');
        return Promise.resolve(true);
    } catch (e) {
        return Promise.reject(e);
    }
}

async function loadSharedLinksHistory() {
    const tbody = document.getElementById('sharedLinksTableBody');
    if (!tbody) return;

    try {
        const response = await fetchWithAuth('/api/reports/share');
        if (!response.ok) {
            let errMsg = 'Error al cargar enlaces';
            try {
                const errData = await response.json();
                if (errData && errData.error) errMsg = errData.error;
            } catch (_) {}
            throw new Error(errMsg);
        }

        const contentType = response.headers.get('content-type') || '';
        if (!contentType.includes('application/json')) {
            throw new Error('El servidor no retornó un formato JSON válido');
        }

        const list = await response.json();
        const activeLinks = Array.isArray(list) ? list.filter(item => item.is_active !== false) : [];

        if (activeLinks.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; padding: 1.25rem; color: #9CA3AF;">No hay enlaces compartidos creados aún.</td></tr>';
            return;
        }

        tbody.innerHTML = activeLinks.map(item => {
            const isExpired = item.isExpired;
            const statusLabel = isExpired ? '<span style="color: #F59E0B; font-weight: 600; font-size: 0.8rem;">(Expirado)</span>' : '<span style="color: #10B981; font-weight: 600; font-size: 0.8rem;">(Activo)</span>';
            const expiresText = item.expires_at ? formatDate(item.expires_at) : 'Permanente';
            const periodLabel = item.period === '7d' ? 'Semanal' : (item.period === '30d' ? 'Mensual' : (item.period === '1d' ? 'Diario' : item.period));

            return `
                <tr id="shared-row-${item.token}" style="border-bottom: 1px solid #E5E7EB;">
                    <td style="padding: 8px 10px;">
                        <strong style="color: #1F2937;">${escapeHtml(item.title)}</strong> ${statusLabel}<br>
                        <span style="font-size: 0.78rem; color: #6B7280;">${periodLabel} | ${item.department === 'all' ? 'Todos' : escapeHtml(item.department)}</span>
                    </td>
                    <td style="padding: 8px 10px; font-size: 0.8rem; color: #4B5563;">${expiresText}</td>
                    <td style="padding: 8px 10px; text-align: center; font-weight: 700;">${item.views_count || 0}</td>
                    <td style="padding: 8px 10px; text-align: right; white-space: nowrap;">
                        <button onclick="copySpecificShareUrl('${item.url}', this)" style="padding: 5px 9px; font-size: 0.8rem; background: #E5E7EB; border: none; border-radius: 5px; cursor: pointer; margin-right: 4px;" title="Copiar enlace">📋</button>
                        <a href="${item.url}" target="_blank" style="padding: 5px 9px; font-size: 0.8rem; background: #E5E7EB; color: #1F2937; text-decoration: none; border-radius: 5px; margin-right: 4px; display: inline-block;" title="Abrir reporte">↗️</a>
                        <button onclick="deleteSharedLink('${item.token}')" style="padding: 5px 9px; font-size: 0.8rem; background: #FEE2E2; color: #DC2626; border: none; border-radius: 5px; cursor: pointer;" title="Eliminar enlace">🗑️</button>
                    </td>
                </tr>
            `;
        }).join('');
    } catch (e) {
        tbody.innerHTML = `<tr><td colspan="4" style="text-align: center; padding: 1rem; color: #EF4444;">${escapeHtml(e.message)}</td></tr>`;
    }
}

async function deleteSharedLink(token) {
    if (!confirm('¿Estás seguro de que deseas eliminar este enlace público?')) {
        return;
    }

    try {
        const response = await fetchWithAuth(`/api/reports/share/${token}`, {
            method: 'DELETE'
        });
        const data = await response.json();
        if (!response.ok || !data.success) {
            throw new Error(data.error || 'Error al eliminar enlace');
        }

        // Remover fila inmediatamente
        const row = document.getElementById(`shared-row-${token}`);
        if (row) row.remove();

        showSuccess('Enlace eliminado con éxito');
        loadSharedLinksHistory();
    } catch (err) {
        showError(err.message || 'Error al eliminar enlace');
    }
}

// Alias para compatibilidad
const revokeSharedLink = deleteSharedLink;

// Exponer funciones globales
window.exportToPDF = exportToPDF;
window.exportReportToCSV = exportReportToCSV;
window.refreshData = refreshData;
window.exportChartAsImage = exportChartAsImage;
window.openShareModal = openShareModal;
window.closeShareModal = closeShareModal;
window.generateSharedReportLink = generateSharedReportLink;
window.copyShareUrlToClipboard = copyShareUrlToClipboard;
window.copySpecificShareUrl = copySpecificShareUrl;
window.revokeSharedLink = deleteSharedLink;
window.deleteSharedLink = deleteSharedLink;
window.showSuccess = showSuccess;
window.showError = showError;

