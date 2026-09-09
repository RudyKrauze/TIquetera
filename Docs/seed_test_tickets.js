/**
 * Script para insertar tickets de prueba
 * Ejecutar con: node Docs/seed_test_tickets.js
 */

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'tiquetera_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD
});

async function seedTestTickets() {
    const client = await pool.connect();

    try {
        console.log('🔌 Conectando a la base de datos...');

        // Obtener IDs de usuarios
        const usersResult = await client.query(`
      SELECT id, role FROM users WHERE active = true
    `);

        const users = {};
        usersResult.rows.forEach(u => {
            users[u.role] = u.id;
        });

        const userAdmin = users.administrador || 1;
        const userSupport = users.support || userAdmin;
        const userRrhh = users.rrhh || userAdmin;
        const userMant = users.mantenimiento || userAdmin;
        const userCompras = users.compras || userAdmin;

        console.log('👥 Usuarios encontrados:', Object.keys(users).length);

        // Datos de prueba
        const tickets = [
            // ============ OPEN (40 tickets) ============
            // Sistemas  - Open
            { title: 'Computadora no enciende', desc: 'Mi computadora de escritorio no enciende desde esta mañana. Ya verifiqué que está conectada.', status: 'open', priority: 'high', dept: 'Sistemas', name: 'María García', email: 'maria.garcia@empresa.com', assigned: userSupport, daysAgo: 3 },
            { title: 'Problemas con la impresora de red', desc: 'La impresora HP del piso 3 no imprime. Aparece como offline.', status: 'open', priority: 'medium', dept: 'Sistemas', name: 'Carlos Pérez', email: 'carlos.perez@empresa.com', assigned: userSupport, daysAgo: 15 },
            { title: 'Pantalla azul frecuente', desc: 'Mi notebook presenta pantalla azul de error varias veces al día.', status: 'open', priority: 'high', dept: 'Sistemas', name: 'Ana López', email: 'ana.lopez@empresa.com', assigned: userSupport, daysAgo: 45 },
            { title: 'Solicitud de monitor adicional', desc: 'Necesito un segundo monitor para trabajar con hojas de cálculo.', status: 'open', priority: 'low', dept: 'Sistemas', name: 'Roberto Sánchez', email: 'roberto.sanchez@empresa.com', assigned: null, daysAgo: 60 },
            { title: 'VPN no conecta desde casa', desc: 'No puedo conectarme a la VPN corporativa. El error dice timeout.', status: 'open', priority: 'medium', dept: 'Sistemas', name: 'Laura Martínez', email: 'laura.martinez@empresa.com', assigned: userSupport, daysAgo: 90 },
            { title: 'Teclado defectuoso', desc: 'Varias teclas del teclado no responden correctamente.', status: 'open', priority: 'low', dept: 'Sistemas', name: 'Diego Torres', email: 'diego.torres@empresa.com', assigned: null, daysAgo: 120 },
            { title: 'Actualización de software requerida', desc: 'Necesito actualizar el paquete de Office a la última versión.', status: 'open', priority: 'low', dept: 'Sistemas', name: 'Patricia Ruiz', email: 'patricia.ruiz@empresa.com', assigned: userSupport, daysAgo: 150 },
            { title: 'Lentitud en el sistema', desc: 'La computadora tarda mucho en abrir programas y archivos.', status: 'open', priority: 'medium', dept: 'Sistemas', name: 'Fernando Díaz', email: 'fernando.diaz@empresa.com', assigned: userSupport, daysAgo: 180 },

            // Recursos Humanos - Open
            { title: 'Consulta sobre vacaciones pendientes', desc: 'Quisiera saber cuántos días de vacaciones me quedan disponibles.', status: 'open', priority: 'low', dept: 'Recursos Humanos', name: 'Gabriela Fernández', email: 'gabriela.fernandez@empresa.com', assigned: userRrhh, daysAgo: 5 },
            { title: 'Solicitud de certificado laboral', desc: 'Necesito un certificado laboral para trámite bancario.', status: 'open', priority: 'medium', dept: 'Recursos Humanos', name: 'Martín Morales', email: 'martin.morales@empresa.com', assigned: userRrhh, daysAgo: 20 },
            { title: 'Error en recibo de sueldo', desc: 'El recibo de sueldo tiene un error en las horas extra.', status: 'open', priority: 'high', dept: 'Recursos Humanos', name: 'Sofía Castro', email: 'sofia.castro@empresa.com', assigned: userRrhh, daysAgo: 35 },
            { title: 'Cambio de cuenta bancaria', desc: 'Necesito actualizar mi cuenta para el depósito de sueldo.', status: 'open', priority: 'medium', dept: 'Recursos Humanos', name: 'Andrés Vega', email: 'andres.vega@empresa.com', assigned: userRrhh, daysAgo: 75 },
            { title: 'Solicitud de licencia por estudio', desc: 'Solicito licencia para rendir exámenes universitarios.', status: 'open', priority: 'low', dept: 'Recursos Humanos', name: 'Valentina Ríos', email: 'valentina.rios@empresa.com', assigned: userRrhh, daysAgo: 100 },
            { title: 'Consulta sobre beneficios corporativos', desc: 'Necesito información sobre los beneficios de gimnasio.', status: 'open', priority: 'low', dept: 'Recursos Humanos', name: 'Nicolás Herrera', email: 'nicolas.herrera@empresa.com', assigned: null, daysAgo: 130 },
            { title: 'Actualización de datos personales', desc: 'Me mudé y necesito actualizar mi dirección.', status: 'open', priority: 'low', dept: 'Recursos Humanos', name: 'Camila Ortiz', email: 'camila.ortiz@empresa.com', assigned: userRrhh, daysAgo: 200 },
            { title: 'Consulta sobre antigüedad', desc: 'Quisiera confirmar mi fecha de ingreso a la empresa.', status: 'open', priority: 'low', dept: 'Recursos Humanos', name: 'Luciano Paz', email: 'luciano.paz@empresa.com', assigned: userRrhh, daysAgo: 250 },

            // Mantenimiento - Open
            { title: 'Aire acondicionado no funciona', desc: 'El aire de la sala de reuniones del piso 2 no enfría.', status: 'open', priority: 'high', dept: 'Mantenimiento', name: 'Juliana Méndez', email: 'juliana.mendez@empresa.com', assigned: userMant, daysAgo: 2 },
            { title: 'Luz del baño quemada', desc: 'La luz del baño de hombres del piso 1 está quemada.', status: 'open', priority: 'low', dept: 'Mantenimiento', name: 'Ricardo Luna', email: 'ricardo.luna@empresa.com', assigned: userMant, daysAgo: 10 },
            { title: 'Fuga de agua en cocina', desc: 'Hay una pequeña fuga en la canilla de la cocina.', status: 'open', priority: 'medium', dept: 'Mantenimiento', name: 'Florencia Silva', email: 'florencia.silva@empresa.com', assigned: userMant, daysAgo: 50 },
            { title: 'Puerta trabada', desc: 'La puerta del depósito no cierra correctamente.', status: 'open', priority: 'medium', dept: 'Mantenimiento', name: 'Sebastián Acosta', email: 'sebastian.acosta@empresa.com', assigned: userMant, daysAgo: 80 },
            { title: 'Pintura descascarada', desc: 'La pared de la recepción tiene pintura descascarada.', status: 'open', priority: 'low', dept: 'Mantenimiento', name: 'Carolina Molina', email: 'carolina.molina@empresa.com', assigned: null, daysAgo: 140 },
            { title: 'Escalera con peldaño suelto', desc: 'Un peldaño de la escalera de emergencia está suelto.', status: 'open', priority: 'high', dept: 'Mantenimiento', name: 'Tomás Aguirre', email: 'tomas.aguirre@empresa.com', assigned: userMant, daysAgo: 170 },
            { title: 'Ventana no abre', desc: 'La ventana de mi oficina está trabada.', status: 'open', priority: 'low', dept: 'Mantenimiento', name: 'Agustina Pereyra', email: 'agustina.pereyra@empresa.com', assigned: userMant, daysAgo: 220 },
            { title: 'Humedad en techo', desc: 'Apareció una mancha de humedad en el techo de oficina 305.', status: 'open', priority: 'medium', dept: 'Mantenimiento', name: 'Emilio Vargas', email: 'emilio.vargas@empresa.com', assigned: userMant, daysAgo: 280 },

            // Compras e Insumos - Open
            { title: 'Solicitud de resmas de papel', desc: 'Necesitamos 50 resmas de papel A4 para contabilidad.', status: 'open', priority: 'medium', dept: 'Compras e Insumos', name: 'Paula Giménez', email: 'paula.gimenez@empresa.com', assigned: userCompras, daysAgo: 4 },
            { title: 'Cartuchos de toner agotados', desc: 'Se agotaron los cartuchos de toner para impresora Samsung.', status: 'open', priority: 'high', dept: 'Compras e Insumos', name: 'Marcos Romero', email: 'marcos.romero@empresa.com', assigned: userCompras, daysAgo: 25 },
            { title: 'Solicitud de útiles de oficina', desc: 'Necesitamos biromes, marcadores y carpetas.', status: 'open', priority: 'low', dept: 'Compras e Insumos', name: 'Daniela Suárez', email: 'daniela.suarez@empresa.com', assigned: userCompras, daysAgo: 55 },
            { title: 'Compra de sillas ergonómicas', desc: 'Solicito cotización para 10 sillas ergonómicas.', status: 'open', priority: 'medium', dept: 'Compras e Insumos', name: 'Ignacio Flores', email: 'ignacio.flores@empresa.com', assigned: userCompras, daysAgo: 95 },
            { title: 'Reposición de café y azúcar', desc: 'Se terminó el café y azúcar de la cocina.', status: 'open', priority: 'low', dept: 'Compras e Insumos', name: 'Rocío Medina', email: 'rocio.medina@empresa.com', assigned: null, daysAgo: 160 },
            { title: 'Solicitud de dispensador de agua', desc: 'Necesitamos dispensador para sala de espera.', status: 'open', priority: 'low', dept: 'Compras e Insumos', name: 'Facundo Campos', email: 'facundo.campos@empresa.com', assigned: userCompras, daysAgo: 210 },

            // Administrador - Open
            { title: 'Acceso a carpeta compartida', desc: 'Necesito permisos para la carpeta de proyectos 2024.', status: 'open', priority: 'medium', dept: 'Administrador', name: 'Lorena Gutiérrez', email: 'lorena.gutierrez@empresa.com', assigned: userAdmin, daysAgo: 7 },
            { title: 'Crear cuenta de correo nuevo empleado', desc: 'Email para nuevo empleado: Juan Pérez.', status: 'open', priority: 'high', dept: 'Administrador', name: 'Gerente RRHH', email: 'rrhh.gerente@empresa.com', assigned: userAdmin, daysAgo: 30 },
            { title: 'Reseteo de contraseña', desc: 'Olvidé mi contraseña del sistema.', status: 'open', priority: 'medium', dept: 'Administrador', name: 'Matías Benítez', email: 'matias.benitez@empresa.com', assigned: userAdmin, daysAgo: 70 },
            { title: 'Backup de archivos importantes', desc: 'Solicito backup de mi carpeta personal.', status: 'open', priority: 'low', dept: 'Administrador', name: 'Verónica Ledesma', email: 'veronica.ledesma@empresa.com', assigned: userAdmin, daysAgo: 110 },
            { title: 'Consulta sobre licencias de software', desc: 'Cuántas licencias de AutoCAD tenemos?', status: 'open', priority: 'low', dept: 'Administrador', name: 'Gonzalo Navarro', email: 'gonzalo.navarro@empresa.com', assigned: null, daysAgo: 190 },
            { title: 'Problema con email corporativo', desc: 'No recibo emails desde ayer.', status: 'open', priority: 'high', dept: 'Administrador', name: 'Milagros Quiroga', email: 'milagros.quiroga@empresa.com', assigned: userAdmin, daysAgo: 240 },
            { title: 'Solicitud de acceso VPN', desc: 'Necesito acceso VPN para trabajar desde casa.', status: 'open', priority: 'medium', dept: 'Administrador', name: 'Ramiro Ojeda', email: 'ramiro.ojeda@empresa.com', assigned: userAdmin, daysAgo: 300 },
            { title: 'Cambio de extensión telefónica', desc: 'Reasignar mi interno tras mudanza de oficina.', status: 'open', priority: 'low', dept: 'Administrador', name: 'Celeste Ponce', email: 'celeste.ponce@empresa.com', assigned: userAdmin, daysAgo: 330 },
            { title: 'Alta de usuario en sistema contable', desc: 'Usuario en el sistema TANGO.', status: 'open', priority: 'medium', dept: 'Administrador', name: 'Hugo Espinosa', email: 'hugo.espinosa@empresa.com', assigned: userAdmin, daysAgo: 350 },
            { title: 'Configurar firma de email', desc: 'Ayuda para configurar firma corporativa en Outlook.', status: 'open', priority: 'low', dept: 'Administrador', name: 'Belén Coronel', email: 'belen.coronel@empresa.com', assigned: null, daysAgo: 360 },

            // ============ IN-PROGRESS (40 tickets) ============
            { title: 'Instalación de software especializado', desc: 'Instalando Adobe Creative Suite.', status: 'in-progress', priority: 'medium', dept: 'Sistemas', name: 'Alejandro Romero', email: 'alejandro.romero@empresa.com', assigned: userSupport, daysAgo: 8, updatedDaysAgo: 2 },
            { title: 'Migración de datos a nuevo equipo', desc: 'Migrando datos de PC vieja a nueva laptop.', status: 'in-progress', priority: 'high', dept: 'Sistemas', name: 'Natalia Córdoba', email: 'natalia.cordoba@empresa.com', assigned: userSupport, daysAgo: 12, updatedDaysAgo: 1 },
            { title: 'Configuración de scanner', desc: 'El scanner nuevo necesita configuración.', status: 'in-progress', priority: 'low', dept: 'Sistemas', name: 'Cristian Rojas', email: 'cristian.rojas@empresa.com', assigned: userSupport, daysAgo: 40, updatedDaysAgo: 5 },
            { title: 'Problema con proyector', desc: 'El proyector se ve amarillento.', status: 'in-progress', priority: 'medium', dept: 'Sistemas', name: 'Andrea Figueroa', email: 'andrea.figueroa@empresa.com', assigned: userSupport, daysAgo: 65, updatedDaysAgo: 10 },
            { title: 'Actualización de antivirus corporativo', desc: 'Actualizando antivirus en todos los equipos.', status: 'in-progress', priority: 'high', dept: 'Sistemas', name: 'IT Manager', email: 'it.manager@empresa.com', assigned: userSupport, daysAgo: 85, updatedDaysAgo: 3 },
            { title: 'Reparación de disco duro', desc: 'Disco con sectores defectuosos.', status: 'in-progress', priority: 'high', dept: 'Sistemas', name: 'Mariana Ortega', email: 'mariana.ortega@empresa.com', assigned: userSupport, daysAgo: 115, updatedDaysAgo: 8 },
            { title: 'Instalación de sistema operativo', desc: 'Formateando e instalando Windows 11.', status: 'in-progress', priority: 'medium', dept: 'Sistemas', name: 'Leandro Sosa', email: 'leandro.sosa@empresa.com', assigned: userSupport, daysAgo: 145, updatedDaysAgo: 2 },
            { title: 'Configuración de backup automático', desc: 'Configurando respaldo a servidor NAS.', status: 'in-progress', priority: 'medium', dept: 'Sistemas', name: 'Claudia Méndez', email: 'claudia.mendez@empresa.com', assigned: userSupport, daysAgo: 185, updatedDaysAgo: 15 },

            { title: 'Proceso de liquidación final', desc: 'Procesando liquidación del empleado que renunció.', status: 'in-progress', priority: 'high', dept: 'Recursos Humanos', name: 'Contaduría', email: 'contaduria@empresa.com', assigned: userRrhh, daysAgo: 6, updatedDaysAgo: 1 },
            { title: 'Trámite de obra social', desc: 'Gestionando cambio de plan de obra social.', status: 'in-progress', priority: 'medium', dept: 'Recursos Humanos', name: 'Roberto Valdez', email: 'roberto.valdez@empresa.com', assigned: userRrhh, daysAgo: 18, updatedDaysAgo: 3 },
            { title: 'Solicitud de préstamo', desc: 'Evaluando solicitud de préstamo personal.', status: 'in-progress', priority: 'medium', dept: 'Recursos Humanos', name: 'Silvia Paredes', email: 'silvia.paredes@empresa.com', assigned: userRrhh, daysAgo: 42, updatedDaysAgo: 7 },
            { title: 'Actualización de legajo', desc: 'Actualizando documentación en legajo.', status: 'in-progress', priority: 'low', dept: 'Recursos Humanos', name: 'Juan Carlos Arias', email: 'jc.arias@empresa.com', assigned: userRrhh, daysAgo: 88, updatedDaysAgo: 12 },
            { title: 'Proceso de ascenso', desc: 'Evaluación para promoción de puesto.', status: 'in-progress', priority: 'high', dept: 'Recursos Humanos', name: 'Teresa Godoy', email: 'teresa.godoy@empresa.com', assigned: userRrhh, daysAgo: 125, updatedDaysAgo: 20 },
            { title: 'Trámite de jubilación', desc: 'Preparando documentación para jubilación.', status: 'in-progress', priority: 'high', dept: 'Recursos Humanos', name: 'Alberto Mansilla', email: 'alberto.mansilla@empresa.com', assigned: userRrhh, daysAgo: 165, updatedDaysAgo: 5 },
            { title: 'Revisión de convenio colectivo', desc: 'Analizando aplicación de nuevo convenio.', status: 'in-progress', priority: 'medium', dept: 'Recursos Humanos', name: 'Sindicato', email: 'delegado@sindicato.org', assigned: userRrhh, daysAgo: 225, updatedDaysAgo: 30 },
            { title: 'Capacitación obligatoria pendiente', desc: 'Coordinando capacitación de seguridad.', status: 'in-progress', priority: 'medium', dept: 'Recursos Humanos', name: 'Seguridad e Higiene', email: 'seguridad@empresa.com', assigned: userRrhh, daysAgo: 285, updatedDaysAgo: 45 },

            { title: 'Instalación de cámaras de seguridad', desc: 'Instalando cámaras en el estacionamiento.', status: 'in-progress', priority: 'high', dept: 'Mantenimiento', name: 'Seguridad', email: 'seguridad@empresa.com', assigned: userMant, daysAgo: 9, updatedDaysAgo: 2 },
            { title: 'Reparación de ascensor', desc: 'Técnico trabajando en el ascensor.', status: 'in-progress', priority: 'high', dept: 'Mantenimiento', name: 'Recepción', email: 'recepcion@empresa.com', assigned: userMant, daysAgo: 14, updatedDaysAgo: 1 },
            { title: 'Mantenimiento preventivo HVAC', desc: 'Servicio de aire acondicionado central.', status: 'in-progress', priority: 'medium', dept: 'Mantenimiento', name: 'Facilities', email: 'facilities@empresa.com', assigned: userMant, daysAgo: 48, updatedDaysAgo: 4 },
            { title: 'Reparación de portón eléctrico', desc: 'El portón del estacionamiento no cierra.', status: 'in-progress', priority: 'medium', dept: 'Mantenimiento', name: 'Vigilancia', email: 'vigilancia@empresa.com', assigned: userMant, daysAgo: 78, updatedDaysAgo: 6 },
            { title: 'Cambio de luminarias a LED', desc: 'Proyecto de iluminación en piso 2.', status: 'in-progress', priority: 'low', dept: 'Mantenimiento', name: 'Sustentabilidad', email: 'sustentabilidad@empresa.com', assigned: userMant, daysAgo: 135, updatedDaysAgo: 25 },
            { title: 'Impermeabilización de terraza', desc: 'Trabajos en terraza accesible.', status: 'in-progress', priority: 'medium', dept: 'Mantenimiento', name: 'Admin Edificio', email: 'admin.edificio@empresa.com', assigned: userMant, daysAgo: 175, updatedDaysAgo: 10 },
            { title: 'Reparación de grupo electrógeno', desc: 'Mantenimiento del generador.', status: 'in-progress', priority: 'high', dept: 'Mantenimiento', name: 'Gerencia General', email: 'gerencia@empresa.com', assigned: userMant, daysAgo: 235, updatedDaysAgo: 18 },
            { title: 'Ampliación de oficinas', desc: 'Obra de ampliación del área de desarrollo.', status: 'in-progress', priority: 'medium', dept: 'Mantenimiento', name: 'Dir. Proyectos', email: 'proyectos@empresa.com', assigned: userMant, daysAgo: 295, updatedDaysAgo: 40 },

            { title: 'Licitación de mobiliario', desc: 'Evaluando cotizaciones de mobiliario.', status: 'in-progress', priority: 'medium', dept: 'Compras e Insumos', name: 'Gerencia Admin', email: 'admin@empresa.com', assigned: userCompras, daysAgo: 11, updatedDaysAgo: 3 },
            { title: 'Compra de equipos de informática', desc: 'Proceso de compra de 15 notebooks.', status: 'in-progress', priority: 'high', dept: 'Compras e Insumos', name: 'IT Director', email: 'it.director@empresa.com', assigned: userCompras, daysAgo: 22, updatedDaysAgo: 2 },
            { title: 'Contrato de servicio de limpieza', desc: 'Renovando contrato con empresa de limpieza.', status: 'in-progress', priority: 'medium', dept: 'Compras e Insumos', name: 'Facilities', email: 'facilities@empresa.com', assigned: userCompras, daysAgo: 58, updatedDaysAgo: 8 },
            { title: 'Proveedor de insumos de cafetería', desc: 'Negociando nuevo contrato de provisión.', status: 'in-progress', priority: 'low', dept: 'Compras e Insumos', name: 'RRHH', email: 'rrhh@empresa.com', assigned: userCompras, daysAgo: 105, updatedDaysAgo: 15 },
            { title: 'Compra de EPP', desc: 'Adquiriendo elementos de protección personal.', status: 'in-progress', priority: 'high', dept: 'Compras e Insumos', name: 'Seguridad e Higiene', email: 'seguridad@empresa.com', assigned: userCompras, daysAgo: 155, updatedDaysAgo: 7 },
            { title: 'Renovación flota vehicular', desc: 'Cotizando vehículos para renovación.', status: 'in-progress', priority: 'medium', dept: 'Compras e Insumos', name: 'Logística', email: 'logistica@empresa.com', assigned: userCompras, daysAgo: 205, updatedDaysAgo: 35 },

            { title: 'Migración de servidor de email', desc: 'Migrando servidor de correo.', status: 'in-progress', priority: 'high', dept: 'Administrador', name: 'IT Team', email: 'it.team@empresa.com', assigned: userAdmin, daysAgo: 13, updatedDaysAgo: 1 },
            { title: 'Implementación nuevo ERP', desc: 'Proyecto de implementación de ERP.', status: 'in-progress', priority: 'high', dept: 'Administrador', name: 'Dirección', email: 'direccion@empresa.com', assigned: userAdmin, daysAgo: 28, updatedDaysAgo: 2 },
            { title: 'Auditoría de seguridad informática', desc: 'Realizando auditoría de seguridad.', status: 'in-progress', priority: 'high', dept: 'Administrador', name: 'Auditoría', email: 'auditoria@empresa.com', assigned: userAdmin, daysAgo: 62, updatedDaysAgo: 5 },
            { title: 'Configuración de firewall', desc: 'Actualizando reglas de firewall.', status: 'in-progress', priority: 'high', dept: 'Administrador', name: 'Seguridad IT', email: 'security.it@empresa.com', assigned: userAdmin, daysAgo: 92, updatedDaysAgo: 3 },
            { title: 'Expansión de red WiFi', desc: 'Instalando nuevos access points.', status: 'in-progress', priority: 'medium', dept: 'Administrador', name: 'Infraestructura', email: 'infra@empresa.com', assigned: userAdmin, daysAgo: 148, updatedDaysAgo: 12 },
            { title: 'Actualización de servidores', desc: 'Upgrade de hardware en servidores.', status: 'in-progress', priority: 'high', dept: 'Administrador', name: 'Datacenter', email: 'datacenter@empresa.com', assigned: userAdmin, daysAgo: 195, updatedDaysAgo: 8 },
            { title: 'Implementación autenticación 2FA', desc: 'Desplegando doble factor.', status: 'in-progress', priority: 'high', dept: 'Administrador', name: 'CISO', email: 'ciso@empresa.com', assigned: userAdmin, daysAgo: 255, updatedDaysAgo: 20 },
            { title: 'Migración a Office 365', desc: 'Proyecto de migración a suite cloud.', status: 'in-progress', priority: 'medium', dept: 'Administrador', name: 'IT Manager', email: 'it.manager@empresa.com', assigned: userAdmin, daysAgo: 315, updatedDaysAgo: 50 },
            { title: 'Desarrollo de intranet', desc: 'Proyecto de nueva intranet.', status: 'in-progress', priority: 'medium', dept: 'Administrador', name: 'Comunicación', email: 'comunicacion@empresa.com', assigned: userAdmin, daysAgo: 340, updatedDaysAgo: 30 },
            { title: 'Sistema de control de acceso', desc: 'Implementando tarjetas RFID.', status: 'in-progress', priority: 'medium', dept: 'Administrador', name: 'Seguridad Física', email: 'seguridad.fisica@empresa.com', assigned: userAdmin, daysAgo: 355, updatedDaysAgo: 25 },

            // ============ CLOSED (20 tickets) ============
            { title: 'Mouse inalámbrico no funciona', desc: 'El mouse dejó de funcionar.', status: 'closed', priority: 'low', dept: 'Sistemas', name: 'Esteban Luna', email: 'esteban.luna@empresa.com', assigned: userSupport, daysAgo: 180, updatedDaysAgo: 175 },
            { title: 'Solicitud de auriculares', desc: 'Necesito auriculares para videollamadas.', status: 'closed', priority: 'low', dept: 'Sistemas', name: 'Melisa Paz', email: 'melisa.paz@empresa.com', assigned: userSupport, daysAgo: 200, updatedDaysAgo: 195 },
            { title: 'Error en facturación electrónica', desc: 'Error de conexión AFIP resuelto.', status: 'closed', priority: 'high', dept: 'Sistemas', name: 'Facturación', email: 'facturacion@empresa.com', assigned: userSupport, daysAgo: 150, updatedDaysAgo: 148 },
            { title: 'Reinstalación de Office', desc: 'Office reinstalado correctamente.', status: 'closed', priority: 'medium', dept: 'Sistemas', name: 'Germán Acuña', email: 'german.acuna@empresa.com', assigned: userSupport, daysAgo: 260, updatedDaysAgo: 257 },

            { title: 'Constancia de trabajo urgente', desc: 'Constancia entregada.', status: 'closed', priority: 'high', dept: 'Recursos Humanos', name: 'María del Carmen', email: 'mdc@empresa.com', assigned: userRrhh, daysAgo: 120, updatedDaysAgo: 119 },
            { title: 'Corrección de recibo de sueldo', desc: 'Recibo corregido y reenviado.', status: 'closed', priority: 'high', dept: 'Recursos Humanos', name: 'Pablo Giménez', email: 'pablo.gimenez@empresa.com', assigned: userRrhh, daysAgo: 90, updatedDaysAgo: 87 },
            { title: 'Licencia por mudanza', desc: 'Licencia otorgada según convenio.', status: 'closed', priority: 'low', dept: 'Recursos Humanos', name: 'Lucía Bravo', email: 'lucia.bravo@empresa.com', assigned: userRrhh, daysAgo: 270, updatedDaysAgo: 268 },
            { title: 'Alta en sistema de asistencia', desc: 'Usuario dado de alta.', status: 'closed', priority: 'medium', dept: 'Recursos Humanos', name: 'RRHH Admin', email: 'rrhh.admin@empresa.com', assigned: userRrhh, daysAgo: 310, updatedDaysAgo: 309 },

            { title: 'Caño roto en baño', desc: 'Pérdida reparada.', status: 'closed', priority: 'high', dept: 'Mantenimiento', name: 'Limpieza', email: 'limpieza@empresa.com', assigned: userMant, daysAgo: 100, updatedDaysAgo: 99 },
            { title: 'Cerradura de oficina', desc: 'Cerradura cambiada.', status: 'closed', priority: 'medium', dept: 'Mantenimiento', name: 'Mario Sánchez', email: 'mario.sanchez@empresa.com', assigned: userMant, daysAgo: 180, updatedDaysAgo: 178 },
            { title: 'Instalación de aire split', desc: 'Split instalado en oficina nueva.', status: 'closed', priority: 'medium', dept: 'Mantenimiento', name: 'Gerencia Comercial', email: 'comercial@empresa.com', assigned: userMant, daysAgo: 230, updatedDaysAgo: 215 },
            { title: 'Reparación de persiana', desc: 'Persiana reparada.', status: 'closed', priority: 'low', dept: 'Mantenimiento', name: 'Secretaría', email: 'secretaria@empresa.com', assigned: userMant, daysAgo: 290, updatedDaysAgo: 288 },

            { title: 'Pedido urgente de toner', desc: 'Toner entregado.', status: 'closed', priority: 'high', dept: 'Compras e Insumos', name: 'Administración', email: 'administracion@empresa.com', assigned: userCompras, daysAgo: 75, updatedDaysAgo: 74 },
            { title: 'Compra de botiquín', desc: 'Botiquín comprado.', status: 'closed', priority: 'medium', dept: 'Compras e Insumos', name: 'Seguridad e Higiene', email: 'seguridad@empresa.com', assigned: userCompras, daysAgo: 140, updatedDaysAgo: 135 },
            { title: 'Renovación papelería', desc: 'Stock de papelería completo.', status: 'closed', priority: 'low', dept: 'Compras e Insumos', name: 'Compras Admin', email: 'compras.admin@empresa.com', assigned: userCompras, daysAgo: 320, updatedDaysAgo: 310 },
            { title: 'Contrato servicio de catering', desc: 'Contrato firmado.', status: 'closed', priority: 'medium', dept: 'Compras e Insumos', name: 'Eventos', email: 'eventos@empresa.com', assigned: userCompras, daysAgo: 345, updatedDaysAgo: 340 },

            { title: 'Creación de VPN para teletrabajo', desc: 'VPN habilitada para equipo.', status: 'closed', priority: 'high', dept: 'Administrador', name: 'CTO', email: 'cto@empresa.com', assigned: userAdmin, daysAgo: 130, updatedDaysAgo: 125 },
            { title: 'Backup y recovery de base de datos', desc: 'BD recuperada correctamente.', status: 'closed', priority: 'high', dept: 'Administrador', name: 'DBA', email: 'dba@empresa.com', assigned: userAdmin, daysAgo: 220, updatedDaysAgo: 218 },
            { title: 'Instalación de certificado SSL', desc: 'Certificado renovado.', status: 'closed', priority: 'high', dept: 'Administrador', name: 'Webmaster', email: 'webmaster@empresa.com', assigned: userAdmin, daysAgo: 280, updatedDaysAgo: 279 },
            { title: 'Configuración de dominio interno', desc: 'Dominio AD configurado.', status: 'closed', priority: 'medium', dept: 'Administrador', name: 'IT Sucursal', email: 'it.sucursal@empresa.com', assigned: userAdmin, daysAgo: 335, updatedDaysAgo: 330 },
        ];

        console.log('📝 Insertando tickets de prueba...');

        let inserted = 0;
        for (const t of tickets) {
            const trackingId = `TKT-TEST-${String(inserted + 1).padStart(4, '0')}`;
            const createdAt = new Date(Date.now() - t.daysAgo * 24 * 60 * 60 * 1000);
            const updatedDays = t.updatedDaysAgo || t.daysAgo - 1;
            const updatedAt = new Date(Date.now() - updatedDays * 24 * 60 * 60 * 1000);

            await client.query(`
        INSERT INTO tickets (tracking_id, title, description, status, priority, department, created_by_name, created_by_email, assigned_to, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      `, [trackingId, t.title, t.desc, t.status, t.priority, t.dept, t.name, t.email, t.assigned, createdAt, updatedAt]);

            inserted++;
        }

        console.log(`✅ Se insertaron ${inserted} tickets de prueba`);

        // Mostrar resumen
        const summary = await client.query(`
      SELECT status, COUNT(*) as count
      FROM tickets WHERE tracking_id LIKE 'TKT-TEST-%'
      GROUP BY status ORDER BY count DESC
    `);

        console.log('\n📊 Resumen de tickets insertados:');
        summary.rows.forEach(r => {
            console.log(`   ${r.status}: ${r.count} tickets`);
        });

    } catch (error) {
        console.error('❌ Error:', error.message);
        throw error;
    } finally {
        client.release();
        await pool.end();
    }
}

seedTestTickets().then(() => {
    console.log('\n🎉 Proceso completado');
    process.exit(0);
}).catch(err => {
    console.error('Error fatal:', err);
    process.exit(1);
});
