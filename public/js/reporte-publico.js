/**
 * reporte-publico.js - Lógica para la visualización del reporte público compartido.
 */

let trendsChartInstance = null;
let deptChartInstance = null;

// Obtener token desde la URL (/reportes/publico/:token o ?token=...)
function getTokenFromUrl() {
    const pathParts = window.location.pathname.split('/');
    const publicoIndex = pathParts.indexOf('publico');
    if (publicoIndex !== -1 && pathParts[publicoIndex + 1]) {
        return pathParts[publicoIndex + 1];
    }

    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('token');
}

function escapeHtml(text) {
    if (text === null || text === undefined) return '';
    return String(text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

function formatPeriod(period) {
    const map = {
        '1d': 'Últimas 24 horas',
        '7d': 'Últimos 7 días (Semanal)',
        '30d': 'Últimos 30 días (Mensual)',
        '90d': 'Últimos 90 días (Trimestral)',
        '180d': 'Últimos 6 meses',
        '365d': 'Último año (Anual)'
    };
    return map[period] || period;
}

function getDateRange(period, baseDateInput = null) {
    const daysMap = {
        '1d': 1,
        '7d': 7,
        '30d': 30,
        '90d': 90,
        '180d': 180,
        '365d': 365
    };
    const days = daysMap[period] || 7;
    const endDate = baseDateInput ? new Date(baseDateInput) : new Date();
    const startDate = new Date(endDate.getTime() - days * 24 * 60 * 60 * 1000);

    const formatShortDate = (d) => {
        const day = String(d.getDate()).padStart(2, '0');
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const year = d.getFullYear();
        return `${day}/${month}/${year}`;
    };

    return {
        startDate,
        endDate,
        startStr: formatShortDate(startDate),
        endStr: formatShortDate(endDate),
        label: `${formatShortDate(startDate)} al ${formatShortDate(endDate)}`
    };
}

function formatDate(dateInput) {
    if (!dateInput) return '-';
    try {
        const d = new Date(dateInput);
        if (isNaN(d.getTime())) return String(dateInput);
        const day = String(d.getDate()).padStart(2, '0');
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const year = d.getFullYear();
        const hours = String(d.getHours()).padStart(2, '0');
        const minutes = String(d.getMinutes()).padStart(2, '0');
        return `${day}/${month}/${year} ${hours}:${minutes}`;
    } catch (_) {
        return String(dateInput);
    }
}

async function loadReportData() {
    const token = getTokenFromUrl();
    const loadingState = document.getElementById('loadingState');
    const errorState = document.getElementById('errorState');
    const contentSection = document.getElementById('contentSection');

    if (!token) {
        loadingState.style.display = 'none';
        errorState.style.display = 'block';
        document.getElementById('errorTitle').textContent = 'Token no especificado';
        document.getElementById('errorMessage').textContent = 'No se proporcionó un token de reporte válido en la dirección web.';
        return;
    }

    loadingState.style.display = 'block';
    errorState.style.display = 'none';
    contentSection.style.display = 'none';

    try {
        const response = await fetch(`/api/reports/public/${token}`);
        const result = await response.json();

        if (!response.ok || !result.success) {
            loadingState.style.display = 'none';
            errorState.style.display = 'block';
            document.getElementById('errorTitle').textContent = response.status === 410 ? 'Enlace Expirado o Desactivado' : 'Enlace No Válido';
            document.getElementById('errorMessage').textContent = result.error || 'El reporte solicitado ya no está disponible.';
            return;
        }

        renderReport(result.reportInfo, result.data);
        loadingState.style.display = 'none';
        contentSection.style.display = 'block';
    } catch (err) {
        loadingState.style.display = 'none';
        errorState.style.display = 'block';
        document.getElementById('errorTitle').textContent = 'Error de Conexión';
        document.getElementById('errorMessage').textContent = 'No fue posible conectar con el servidor para cargar el reporte. Intenta recargar la página.';
    }
}

function renderReport(info, data) {
    // 1. Meta / Encabezado
    document.title = `${info.title} - Imagen Diagnóstica`;
    document.getElementById('reportTitle').textContent = info.title;
    document.getElementById('reportPeriodText').textContent = formatPeriod(info.period);
    
    // Rango de fechas visual
    const range = getDateRange(info.period, info.createdAt);
    let badge = document.getElementById('reportDateRangeBadge');
    if (!badge) {
        badge = document.createElement('span');
        badge.id = 'reportDateRangeBadge';
        badge.style.cssText = 'background: #E6FCF5; color: #008B8B; font-weight: 700; font-size: 0.85rem; padding: 2px 8px; border-radius: 6px; border: 1px solid #C3FAE8; margin-left: 6px; display: inline-block;';
        const periodEl = document.getElementById('reportPeriodText');
        if (periodEl && periodEl.parentNode) {
            periodEl.parentNode.appendChild(badge);
        }
    }
    if (badge) {
        badge.textContent = `📅 ${range.label}`;
    }

    document.getElementById('reportDeptText').textContent = info.department === 'all' ? 'Todos los departamentos' : info.department;
    document.getElementById('reportGeneratedDate').textContent = formatDate(info.createdAt);

    // 2. KPIs
    const stats = data.stats || {};
    document.getElementById('kpiTotal').textContent = stats.total || 0;
    document.getElementById('kpiClosed').textContent = stats.closed || 0;
    document.getElementById('kpiPending').textContent = stats.pending || 0;
    document.getElementById('kpiTime').textContent = `${stats.avgResolutionHours || 0}h`;

    // Badges de KPI
    const change = stats.changePercent || 0;
    const changeBadge = document.getElementById('kpiTotalChange');
    if (change > 0) {
        changeBadge.className = 'kpi-badge positive';
        changeBadge.textContent = `+${change}% vs período anterior`;
    } else if (change < 0) {
        changeBadge.className = 'kpi-badge negative';
        changeBadge.textContent = `${change}% vs período anterior`;
    } else {
        changeBadge.className = 'kpi-badge neutral';
        changeBadge.textContent = `= 0% vs período anterior`;
    }

    document.getElementById('kpiClosedRate').textContent = `${stats.resolutionRate || 0}% Tasa de Resolución`;
    document.getElementById('kpiUnassigned').textContent = `${stats.unassigned || 0} sin asignar`;

    // 3. Gráfico de Tendencias (Chart.js)
    renderTrendsChart(data.trends || []);

    // 4. Gráfico de Departamentos (Doughnut Chart.js)
    renderDeptChart(data.byDepartment || []);

    // 5. Tabla de Departamentos
    renderDepartmentTable(data.byDepartment || []);
}

function renderTrendsChart(trends) {
    const ctx = document.getElementById('trendsChart').getContext('2d');

    if (trendsChartInstance) {
        trendsChartInstance.destroy();
    }

    const labels = trends.map(t => {
        if (!t.date) return '';
        const d = new Date(t.date);
        return `${d.getDate()}/${d.getMonth() + 1}`;
    });
    const createdData = trends.map(t => t.created || 0);
    const closedData = trends.map(t => t.closed || 0);

    trendsChartInstance = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Tickets Recibidos',
                    data: createdData,
                    borderColor: '#008B8B',
                    backgroundColor: 'rgba(0, 139, 139, 0.1)',
                    tension: 0.35,
                    fill: true,
                    pointBackgroundColor: '#008B8B',
                    pointRadius: 4
                },
                {
                    label: 'Tickets Resueltos',
                    data: closedData,
                    borderColor: '#2F9E44',
                    backgroundColor: 'rgba(47, 158, 68, 0.1)',
                    tension: 0.35,
                    fill: true,
                    pointBackgroundColor: '#2F9E44',
                    pointRadius: 4
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                    labels: {
                        font: { family: 'Montserrat', size: 12, weight: '600' }
                    }
                },
                tooltip: {
                    mode: 'index',
                    intersect: false,
                    bodyFont: { family: 'Montserrat' }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        precision: 0,
                        font: { family: 'Montserrat' }
                    },
                    grid: { color: '#F1F3F5' }
                },
                x: {
                    ticks: { font: { family: 'Montserrat' } },
                    grid: { display: false }
                }
            }
        }
    });
}

function renderDeptChart(deptList) {
    const ctx = document.getElementById('deptDoughnutChart').getContext('2d');

    if (deptChartInstance) {
        deptChartInstance.destroy();
    }

    if (!deptList || deptList.length === 0) {
        return;
    }

    const labels = deptList.map(d => d.department);
    const totals = deptList.map(d => d.total);
    const colors = [
        '#008B8B',
        '#2F9E44',
        '#F59F00',
        '#4C6FFF',
        '#7048E8',
        '#E03131',
        '#1098AD'
    ];

    deptChartInstance = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: totals,
                backgroundColor: colors.slice(0, labels.length),
                borderWidth: 2,
                borderColor: '#FFFFFF'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        boxWidth: 12,
                        font: { family: 'Montserrat', size: 11, weight: '500' }
                    }
                }
            },
            cutout: '65%'
        }
    });
}

function renderDepartmentTable(deptList) {
    const tbody = document.getElementById('reportTableBody');
    if (!deptList || deptList.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #6B7280; padding: 2rem;">No hay datos registrados en este período.</td></tr>';
        return;
    }

    tbody.innerHTML = deptList.map(d => {
        const rate = parseFloat(d.resolutionRate) || 0;
        return `
            <tr>
                <td><strong>${escapeHtml(d.department)}</strong></td>
                <td style="text-align: center; font-weight: 700;">${d.total}</td>
                <td style="text-align: center; color: #2F9E44; font-weight: 700;">${d.closed}</td>
                <td style="text-align: center; color: #F59F00; font-weight: 700;">${d.pending || (d.open + d.inProgress)}</td>
                <td style="text-align: center;">${d.avgResolutionHours}h</td>
                <td>
                    <div style="display: flex; justify-content: space-between; font-size: 0.82rem; font-weight: 600; margin-bottom: 2px;">
                        <span>${rate}%</span>
                        <span style="color: #6B7280;">${d.closed}/${d.total} resueltos</span>
                    </div>
                    <div class="progress-bar-container">
                        <div class="progress-bar" style="width: ${Math.min(100, rate)}%; background-color: ${rate >= 70 ? '#2F9E44' : rate >= 40 ? '#F59F00' : '#E03131'};"></div>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

function copyPublicReportUrl(btnElement) {
    const url = window.location.href;
    const fallbackCopy = () => {
        try {
            const ta = document.createElement('textarea');
            ta.value = url;
            ta.style.position = 'fixed';
            ta.style.top = '0';
            ta.style.left = '0';
            ta.style.opacity = '0';
            document.body.appendChild(ta);
            ta.focus();
            ta.select();
            document.execCommand('copy');
            document.body.removeChild(ta);
            if (btnElement) {
                const prev = btnElement.innerHTML;
                btnElement.innerHTML = '✅ ¡Copiado!';
                setTimeout(() => { btnElement.innerHTML = prev; }, 2000);
            }
        } catch (_) {
            prompt('Copia este enlace:', url);
        }
    };

    if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(url)
            .then(() => {
                if (btnElement) {
                    const prev = btnElement.innerHTML;
                    btnElement.innerHTML = '✅ ¡Copiado!';
                    setTimeout(() => { btnElement.innerHTML = prev; }, 2000);
                }
            })
            .catch(() => fallbackCopy());
    } else {
        fallbackCopy();
    }
}

window.copyPublicReportUrl = copyPublicReportUrl;

window.addEventListener('DOMContentLoaded', () => {
    const yearEl = document.getElementById('currentYear');
    if (yearEl) yearEl.textContent = new Date().getFullYear();
    loadReportData();
});
