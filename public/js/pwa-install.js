/**
 * PWA Install Manager
 * ====================
 * Maneja la lógica de instalación de la Progressive Web App
 */

class PWAInstallManager {
    constructor() {
        this.deferredPrompt = null;
        this.installButton = null;
        this.installContainer = null;
        this.init();
    }

    init() {
        // Verificar contexto seguro (HTTPS o localhost)
        if (!window.isSecureContext) {

            return;
        }

        // Escuchar evento de instalación
        window.addEventListener('beforeinstallprompt', (e) => {
            // Prevenir el banner automático de Chrome de versiones muy viejas
            e.preventDefault();
            // Guardar evento para dispararlo después
            this.deferredPrompt = e;

            
            // Mostrar botón de instalar
            this.showInstallButton();
        });

        // Detectar si ya está instalada
        window.addEventListener('appinstalled', () => {

            this.hideInstallButton();
            this.deferredPrompt = null;
        });

        // Configurar UI cuando el DOM esté listo
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setupUI());
        } else {
            this.setupUI();
        }
    }

    setupUI() {
        // Buscar el contenedor donde inyectar el botón si no existe
        // Vamos a buscar un lugar apropiado en el header o crear un botón flotante
        
        // Opción 1: Buscar elemento específico en el header
        const headerActions = document.querySelector('.header .logo');
        
        if (headerActions && !document.getElementById('pwa-install-btn')) {
            const btn = document.createElement('button');
            btn.id = 'pwa-install-btn';
            btn.className = 'btn-install-pwa';
            btn.innerHTML = `
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="7 10 12 15 17 10"></polyline>
                    <line x1="12" y1="15" x2="12" y2="3"></line>
                </svg>
                <span>Instalar App</span>
            `;
            btn.style.display = 'none'; // Oculto por defecto
            
            // Estilos inline para asegurar visibilidad sin CSS externo, aunque lo añadiremos al CSS
            btn.style.marginLeft = '15px';
            btn.style.padding = '8px 16px';
            btn.style.borderRadius = '20px';
            btn.style.border = '2px solid var(--brand-primary)';
            btn.style.background = 'white';
            btn.style.color = 'var(--brand-primary)';
            btn.style.cursor = 'pointer';
            btn.style.fontWeight = '600';
            btn.style.display = 'none'; // Reset display
            btn.style.alignItems = 'center';
            btn.style.gap = '8px';
            btn.style.transition = 'all 0.3s ease';

            btn.addEventListener('click', () => this.installPWA());
            
            // Insertar después del logo
            headerActions.after(btn);
            this.installButton = btn;
        }
    }

    showInstallButton() {
        if (this.installButton) {
            this.installButton.style.display = 'inline-flex';
            // Animación de entrada
            this.installButton.animate([
                { opacity: 0, transform: 'translateY(-10px)' },
                { opacity: 1, transform: 'translateY(0)' }
            ], {
                duration: 300,
                easing: 'ease-out'
            });
        }
    }

    hideInstallButton() {
        if (this.installButton) {
            this.installButton.style.display = 'none';
        }
    }

    async installPWA() {
        if (!this.deferredPrompt) {
            return;
        }
        
        // Mostrar prompt nativo
        this.deferredPrompt.prompt();
        
        // Esperar respuesta del usuario
        const { outcome } = await this.deferredPrompt.userChoice;

        
        // Limpiar
        this.deferredPrompt = null;
        this.hideInstallButton();
    }
}

// Inicializar
window.pwaManager = new PWAInstallManager();
