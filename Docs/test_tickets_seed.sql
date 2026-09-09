-- ============================================
-- SCRIPT DE DATOS DE PRUEBA - TICKETS
-- 100 tickets distribuidos en 1 año
-- 40% open, 40% in-progress, 20% closed
-- ============================================

-- Función para generar tracking ID único
CREATE OR REPLACE FUNCTION generate_tracking_id() RETURNS TEXT AS $$
BEGIN
    RETURN 'TKT-' || UPPER(TO_CHAR(NOW(), 'MMDD')) || '-' || UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 4));
END;
$$ LANGUAGE plpgsql;

-- Obtener IDs de usuarios para asignación
DO $$
DECLARE
    user_admin INTEGER;
    user_support INTEGER;
    user_rrhh INTEGER;
    user_mant INTEGER;
    user_compras INTEGER;
BEGIN
    SELECT id INTO user_admin FROM users WHERE role = 'administrador' LIMIT 1;
    SELECT id INTO user_support FROM users WHERE role = 'support' LIMIT 1;
    SELECT id INTO user_rrhh FROM users WHERE role = 'rrhh' LIMIT 1;
    SELECT id INTO user_mant FROM users WHERE role = 'mantenimiento' LIMIT 1;
    SELECT id INTO user_compras FROM users WHERE role = 'compras' LIMIT 1;

    -- Si no existen, usar NULL
    user_admin := COALESCE(user_admin, 1);
    user_support := COALESCE(user_support, user_admin);
    user_rrhh := COALESCE(user_rrhh, user_admin);
    user_mant := COALESCE(user_mant, user_admin);
    user_compras := COALESCE(user_compras, user_admin);

    -- ============================================
    -- TICKETS ABIERTOS (OPEN) - 40 tickets
    -- ============================================
    
    -- Sistemas  - Open
    INSERT INTO tickets (tracking_id, title, description, status, priority, department, created_by_name, created_by_email, assigned_to, created_at, updated_at) VALUES
    ('TKT-TEST-0001', 'Computadora no enciende', 'Mi computadora de escritorio no enciende desde esta mañana. Ya verifiqué que está conectada a la corriente.', 'open', 'high', 'Sistemas', 'María García', 'maria.garcia@empresa.com', user_support, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
    ('TKT-TEST-0002', 'Problemas con la impresora de red', 'La impresora HP del piso 3 no imprime. Aparece como offline en todos los equipos.', 'open', 'medium', 'Sistemas', 'Carlos Pérez', 'carlos.perez@empresa.com', user_support, NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days'),
    ('TKT-TEST-0003', 'Pantalla azul frecuente', 'Mi notebook presenta pantalla azul de error varias veces al día. Adjunto foto del código de error.', 'open', 'high', 'Sistemas', 'Ana López', 'ana.lopez@empresa.com', user_support, NOW() - INTERVAL '45 days', NOW() - INTERVAL '44 days'),
    ('TKT-TEST-0004', 'Solicitud de monitor adicional', 'Necesito un segundo monitor para trabajar con hojas de cálculo grandes.', 'open', 'low', 'Sistemas', 'Roberto Sánchez', 'roberto.sanchez@empresa.com', NULL, NOW() - INTERVAL '60 days', NOW() - INTERVAL '60 days'),
    ('TKT-TEST-0005', 'VPN no conecta desde casa', 'No puedo conectarme a la VPN corporativa desde mi casa. El error dice timeout.', 'open', 'medium', 'Sistemas', 'Laura Martínez', 'laura.martinez@empresa.com', user_support, NOW() - INTERVAL '90 days', NOW() - INTERVAL '89 days'),
    ('TKT-TEST-0006', 'Teclado defectuoso', 'Varias teclas del teclado no responden correctamente.', 'open', 'low', 'Sistemas', 'Diego Torres', 'diego.torres@empresa.com', NULL, NOW() - INTERVAL '120 days', NOW() - INTERVAL '120 days'),
    ('TKT-TEST-0007', 'Actualización de software requerida', 'Necesito actualizar el paquete de Office a la última versión.', 'open', 'low', 'Sistemas', 'Patricia Ruiz', 'patricia.ruiz@empresa.com', user_support, NOW() - INTERVAL '150 days', NOW() - INTERVAL '149 days'),
    ('TKT-TEST-0008', 'Lentitud en el sistema', 'La computadora tarda mucho en abrir programas y archivos.', 'open', 'medium', 'Sistemas', 'Fernando Díaz', 'fernando.diaz@empresa.com', user_support, NOW() - INTERVAL '180 days', NOW() - INTERVAL '178 days'),
    
    -- Recursos Humanos - Open
    ('TKT-TEST-0009', 'Consulta sobre vacaciones pendientes', 'Quisiera saber cuántos días de vacaciones me quedan disponibles este año.', 'open', 'low', 'Recursos Humanos', 'Gabriela Fernández', 'gabriela.fernandez@empresa.com', user_rrhh, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
    ('TKT-TEST-0010', 'Solicitud de certificado laboral', 'Necesito un certificado laboral para trámite bancario.', 'open', 'medium', 'Recursos Humanos', 'Martín Morales', 'martin.morales@empresa.com', user_rrhh, NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days'),
    ('TKT-TEST-0011', 'Error en recibo de sueldo', 'El recibo de sueldo de este mes tiene un error en las horas extra.', 'open', 'high', 'Recursos Humanos', 'Sofía Castro', 'sofia.castro@empresa.com', user_rrhh, NOW() - INTERVAL '35 days', NOW() - INTERVAL '34 days'),
    ('TKT-TEST-0012', 'Cambio de cuenta bancaria', 'Necesito actualizar mi cuenta bancaria para el depósito de sueldo.', 'open', 'medium', 'Recursos Humanos', 'Andrés Vega', 'andres.vega@empresa.com', user_rrhh, NOW() - INTERVAL '75 days', NOW() - INTERVAL '74 days'),
    ('TKT-TEST-0013', 'Solicitud de licencia por estudio', 'Quisiera solicitar licencia para rendir exámenes universitarios.', 'open', 'low', 'Recursos Humanos', 'Valentina Ríos', 'valentina.rios@empresa.com', user_rrhh, NOW() - INTERVAL '100 days', NOW() - INTERVAL '99 days'),
    ('TKT-TEST-0014', 'Consulta sobre beneficios corporativos', 'Necesito información sobre los beneficios de gimnasio.', 'open', 'low', 'Recursos Humanos', 'Nicolás Herrera', 'nicolas.herrera@empresa.com', NULL, NOW() - INTERVAL '130 days', NOW() - INTERVAL '130 days'),
    ('TKT-TEST-0015', 'Actualización de datos personales', 'Me mudé y necesito actualizar mi dirección en el sistema.', 'open', 'low', 'Recursos Humanos', 'Camila Ortiz', 'camila.ortiz@empresa.com', user_rrhh, NOW() - INTERVAL '200 days', NOW() - INTERVAL '199 days'),
    ('TKT-TEST-0016', 'Consulta sobre antigüedad', 'Quisiera confirmar mi fecha de ingreso a la empresa.', 'open', 'low', 'Recursos Humanos', 'Luciano Paz', 'luciano.paz@empresa.com', user_rrhh, NOW() - INTERVAL '250 days', NOW() - INTERVAL '249 days'),
    
    -- Mantenimiento - Open
    ('TKT-TEST-0017', 'Aire acondicionado no funciona', 'El aire acondicionado de la sala de reuniones del piso 2 no enfría.', 'open', 'high', 'Mantenimiento', 'Juliana Méndez', 'juliana.mendez@empresa.com', user_mant, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
    ('TKT-TEST-0018', 'Luz del baño quemada', 'La luz del baño de hombres del piso 1 está quemada.', 'open', 'low', 'Mantenimiento', 'Ricardo Luna', 'ricardo.luna@empresa.com', user_mant, NOW() - INTERVAL '10 days', NOW() - INTERVAL '9 days'),
    ('TKT-TEST-0019', 'Fuga de agua en cocina', 'Hay una pequeña fuga en la canilla de la cocina del piso 4.', 'open', 'medium', 'Mantenimiento', 'Florencia Silva', 'florencia.silva@empresa.com', user_mant, NOW() - INTERVAL '50 days', NOW() - INTERVAL '49 days'),
    ('TKT-TEST-0020', 'Puerta trabada', 'La puerta del depósito no cierra correctamente.', 'open', 'medium', 'Mantenimiento', 'Sebastián Acosta', 'sebastian.acosta@empresa.com', user_mant, NOW() - INTERVAL '80 days', NOW() - INTERVAL '79 days'),
    ('TKT-TEST-0021', 'Pintura descascarada', 'La pared de la recepción tiene pintura descascarada.', 'open', 'low', 'Mantenimiento', 'Carolina Molina', 'carolina.molina@empresa.com', NULL, NOW() - INTERVAL '140 days', NOW() - INTERVAL '140 days'),
    ('TKT-TEST-0022', 'Escalera con peldaño suelto', 'Un peldaño de la escalera de emergencia está suelto.', 'open', 'high', 'Mantenimiento', 'Tomás Aguirre', 'tomas.aguirre@empresa.com', user_mant, NOW() - INTERVAL '170 days', NOW() - INTERVAL '168 days'),
    ('TKT-TEST-0023', 'Ventana no abre', 'La ventana de mi oficina está trabada y no puedo abrirla.', 'open', 'low', 'Mantenimiento', 'Agustina Pereyra', 'agustina.pereyra@empresa.com', user_mant, NOW() - INTERVAL '220 days', NOW() - INTERVAL '219 days'),
    ('TKT-TEST-0024', 'Humedad en techo', 'Apareció una mancha de humedad en el techo de la oficina 305.', 'open', 'medium', 'Mantenimiento', 'Emilio Vargas', 'emilio.vargas@empresa.com', user_mant, NOW() - INTERVAL '280 days', NOW() - INTERVAL '278 days'),
    
    -- Compras e Insumos - Open
    ('TKT-TEST-0025', 'Solicitud de resmas de papel', 'Necesitamos 50 resmas de papel A4 para el área de contabilidad.', 'open', 'medium', 'Compras e Insumos', 'Paula Giménez', 'paula.gimenez@empresa.com', user_compras, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
    ('TKT-TEST-0026', 'Cartuchos de toner agotados', 'Se agotaron los cartuchos de toner para la impresora Samsung.', 'open', 'high', 'Compras e Insumos', 'Marcos Romero', 'marcos.romero@empresa.com', user_compras, NOW() - INTERVAL '25 days', NOW() - INTERVAL '24 days'),
    ('TKT-TEST-0027', 'Solicitud de útiles de oficina', 'Necesitamos biromes, marcadores y carpetas para el departamento.', 'open', 'low', 'Compras e Insumos', 'Daniela Suárez', 'daniela.suarez@empresa.com', user_compras, NOW() - INTERVAL '55 days', NOW() - INTERVAL '54 days'),
    ('TKT-TEST-0028', 'Compra de sillas ergonómicas', 'Solicito cotización para 10 sillas ergonómicas nuevas.', 'open', 'medium', 'Compras e Insumos', 'Ignacio Flores', 'ignacio.flores@empresa.com', user_compras, NOW() - INTERVAL '95 days', NOW() - INTERVAL '94 days'),
    ('TKT-TEST-0029', 'Reposición de café y azúcar', 'Se terminó el café y azúcar de la cocina del piso 3.', 'open', 'low', 'Compras e Insumos', 'Rocío Medina', 'rocio.medina@empresa.com', NULL, NOW() - INTERVAL '160 days', NOW() - INTERVAL '160 days'),
    ('TKT-TEST-0030', 'Solicitud de dispensador de agua', 'Necesitamos un dispensador de agua para la sala de espera.', 'open', 'low', 'Compras e Insumos', 'Facundo Campos', 'facundo.campos@empresa.com', user_compras, NOW() - INTERVAL '210 days', NOW() - INTERVAL '209 days'),
    
    -- Administrador - Open
    ('TKT-TEST-0031', 'Acceso a carpeta compartida', 'Necesito permisos para acceder a la carpeta de proyectos 2024.', 'open', 'medium', 'Administrador', 'Lorena Gutiérrez', 'lorena.gutierrez@empresa.com', user_admin, NOW() - INTERVAL '7 days', NOW() - INTERVAL '6 days'),
    ('TKT-TEST-0032', 'Crear cuenta de correo nuevo empleado', 'Necesito crear email para nuevo empleado: Juan Pérez.', 'open', 'high', 'Administrador', 'Gerente de RRHH', 'rrhh.gerente@empresa.com', user_admin, NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days'),
    ('TKT-TEST-0033', 'Reseteo de contraseña', 'Olvidé mi contraseña del sistema y necesito reset.', 'open', 'medium', 'Administrador', 'Matías Benítez', 'matias.benitez@empresa.com', user_admin, NOW() - INTERVAL '70 days', NOW() - INTERVAL '69 days'),
    ('TKT-TEST-0034', 'Backup de archivos importantes', 'Solicito backup de los archivos de mi carpeta personal.', 'open', 'low', 'Administrador', 'Verónica Ledesma', 'veronica.ledesma@empresa.com', user_admin, NOW() - INTERVAL '110 days', NOW() - INTERVAL '109 days'),
    ('TKT-TEST-0035', 'Consulta sobre licencias de software', 'Necesito saber cuántas licencias de AutoCAD tenemos disponibles.', 'open', 'low', 'Administrador', 'Gonzalo Navarro', 'gonzalo.navarro@empresa.com', NULL, NOW() - INTERVAL '190 days', NOW() - INTERVAL '190 days'),
    ('TKT-TEST-0036', 'Problema con email corporativo', 'No recibo emails desde ayer. Los envío pero no me llegan.', 'open', 'high', 'Administrador', 'Milagros Quiroga', 'milagros.quiroga@empresa.com', user_admin, NOW() - INTERVAL '240 days', NOW() - INTERVAL '238 days'),
    ('TKT-TEST-0037', 'Solicitud de acceso VPN', 'Necesito acceso VPN para trabajar desde casa.', 'open', 'medium', 'Administrador', 'Ramiro Ojeda', 'ramiro.ojeda@empresa.com', user_admin, NOW() - INTERVAL '300 days', NOW() - INTERVAL '299 days'),
    ('TKT-TEST-0038', 'Cambio de extensión telefónica', 'Me mudé de oficina y necesito reasignar mi interno.', 'open', 'low', 'Administrador', 'Celeste Ponce', 'celeste.ponce@empresa.com', user_admin, NOW() - INTERVAL '330 days', NOW() - INTERVAL '329 days'),
    ('TKT-TEST-0039', 'Alta de usuario en sistema contable', 'Necesito usuario en el sistema de contabilidad TANGO.', 'open', 'medium', 'Administrador', 'Hugo Espinosa', 'hugo.espinosa@empresa.com', user_admin, NOW() - INTERVAL '350 days', NOW() - INTERVAL '349 days'),
    ('TKT-TEST-0040', 'Configurar firma de email', 'Necesito ayuda para configurar la firma corporativa en Outlook.', 'open', 'low', 'Administrador', 'Belén Coronel', 'belen.coronel@empresa.com', NULL, NOW() - INTERVAL '360 days', NOW() - INTERVAL '360 days');

    -- ============================================
    -- TICKETS EN PROGRESO (IN-PROGRESS) - 40 tickets
    -- ============================================
    
    -- Sistemas  - In Progress
    INSERT INTO tickets (tracking_id, title, description, status, priority, department, created_by_name, created_by_email, assigned_to, created_at, updated_at) VALUES
    ('TKT-TEST-0041', 'Instalación de software especializado', 'Necesito instalar el software de diseño Adobe Creative Suite.', 'in-progress', 'medium', 'Sistemas', 'Alejandro Romero', 'alejandro.romero@empresa.com', user_support, NOW() - INTERVAL '8 days', NOW() - INTERVAL '2 days'),
    ('TKT-TEST-0042', 'Migración de datos a nuevo equipo', 'Estoy migrando todos los datos de la PC vieja a la nueva laptop.', 'in-progress', 'high', 'Sistemas', 'Natalia Córdoba', 'natalia.cordoba@empresa.com', user_support, NOW() - INTERVAL '12 days', NOW() - INTERVAL '1 day'),
    ('TKT-TEST-0043', 'Configuración de scanner', 'El scanner nuevo necesita configuración para funcionar en red.', 'in-progress', 'low', 'Sistemas', 'Cristian Rojas', 'cristian.rojas@empresa.com', user_support, NOW() - INTERVAL '40 days', NOW() - INTERVAL '5 days'),
    ('TKT-TEST-0044', 'Problema con proyector', 'El proyector de la sala de reuniones se ve amarillento.', 'in-progress', 'medium', 'Sistemas', 'Andrea Figueroa', 'andrea.figueroa@empresa.com', user_support, NOW() - INTERVAL '65 days', NOW() - INTERVAL '10 days'),
    ('TKT-TEST-0045', 'Actualización de antivirus corporativo', 'Actualizando antivirus en todos los equipos del departamento.', 'in-progress', 'high', 'Sistemas', 'IT Manager', 'it.manager@empresa.com', user_support, NOW() - INTERVAL '85 days', NOW() - INTERVAL '3 days'),
    ('TKT-TEST-0046', 'Reparación de disco duro', 'Disco duro con sectores defectuosos, intentando recuperar datos.', 'in-progress', 'high', 'Sistemas', 'Mariana Ortega', 'mariana.ortega@empresa.com', user_support, NOW() - INTERVAL '115 days', NOW() - INTERVAL '8 days'),
    ('TKT-TEST-0047', 'Instalación de sistema operativo', 'Formateando e instalando Windows 11 en equipo nuevo.', 'in-progress', 'medium', 'Sistemas', 'Leandro Sosa', 'leandro.sosa@empresa.com', user_support, NOW() - INTERVAL '145 days', NOW() - INTERVAL '2 days'),
    ('TKT-TEST-0048', 'Configuración de backup automático', 'Configurando respaldo automático a servidor NAS.', 'in-progress', 'medium', 'Sistemas', 'Claudia Méndez', 'claudia.mendez@empresa.com', user_support, NOW() - INTERVAL '185 days', NOW() - INTERVAL '15 days'),
    
    -- Recursos Humanos - In Progress
    ('TKT-TEST-0049', 'Proceso de liquidación final', 'Procesando la liquidación final del empleado que renunció.', 'in-progress', 'high', 'Recursos Humanos', 'Contaduría', 'contaduria@empresa.com', user_rrhh, NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'),
    ('TKT-TEST-0050', 'Trámite de obra social', 'Gestionando cambio de plan de obra social familiar.', 'in-progress', 'medium', 'Recursos Humanos', 'Roberto Valdez', 'roberto.valdez@empresa.com', user_rrhh, NOW() - INTERVAL '18 days', NOW() - INTERVAL '3 days'),
    ('TKT-TEST-0051', 'Solicitud de préstamo', 'Evaluando solicitud de préstamo personal al empleado.', 'in-progress', 'medium', 'Recursos Humanos', 'Silvia Paredes', 'silvia.paredes@empresa.com', user_rrhh, NOW() - INTERVAL '42 days', NOW() - INTERVAL '7 days'),
    ('TKT-TEST-0052', 'Actualización de legajo', 'Actualizando documentación en legajo del empleado.', 'in-progress', 'low', 'Recursos Humanos', 'Juan Carlos Arias', 'jc.arias@empresa.com', user_rrhh, NOW() - INTERVAL '88 days', NOW() - INTERVAL '12 days'),
    ('TKT-TEST-0053', 'Proceso de ascenso', 'Evaluación para promoción de puesto en curso.', 'in-progress', 'high', 'Recursos Humanos', 'Teresa Godoy', 'teresa.godoy@empresa.com', user_rrhh, NOW() - INTERVAL '125 days', NOW() - INTERVAL '20 days'),
    ('TKT-TEST-0054', 'Trámite de jubilación', 'Preparando documentación para jubilación del empleado.', 'in-progress', 'high', 'Recursos Humanos', 'Alberto Mansilla', 'alberto.mansilla@empresa.com', user_rrhh, NOW() - INTERVAL '165 days', NOW() - INTERVAL '5 days'),
    ('TKT-TEST-0055', 'Revisión de convenio colectivo', 'Analizando aplicación de nuevo convenio salarial.', 'in-progress', 'medium', 'Recursos Humanos', 'Sindicato', 'delegado@sindicato.org', user_rrhh, NOW() - INTERVAL '225 days', NOW() - INTERVAL '30 days'),
    ('TKT-TEST-0056', 'Capacitación obligatoria pendiente', 'Coordinando fechas para capacitación de seguridad.', 'in-progress', 'medium', 'Recursos Humanos', 'Seguridad e Higiene', 'seguridad@empresa.com', user_rrhh, NOW() - INTERVAL '285 days', NOW() - INTERVAL '45 days'),
    
    -- Mantenimiento - In Progress
    ('TKT-TEST-0057', 'Instalación de cámaras de seguridad', 'Instalando nuevas cámaras en el estacionamiento.', 'in-progress', 'high', 'Mantenimiento', 'Seguridad', 'seguridad@empresa.com', user_mant, NOW() - INTERVAL '9 days', NOW() - INTERVAL '2 days'),
    ('TKT-TEST-0058', 'Reparación de ascensor', 'Técnico trabajando en el ascensor que se detuvo.', 'in-progress', 'high', 'Mantenimiento', 'Recepción', 'recepcion@empresa.com', user_mant, NOW() - INTERVAL '14 days', NOW() - INTERVAL '1 day'),
    ('TKT-TEST-0059', 'Mantenimiento preventivo HVAC', 'Realizando servicio de aire acondicionado central.', 'in-progress', 'medium', 'Mantenimiento', 'Facilities', 'facilities@empresa.com', user_mant, NOW() - INTERVAL '48 days', NOW() - INTERVAL '4 days'),
    ('TKT-TEST-0060', 'Reparación de portón eléctrico', 'El portón del estacionamiento no cierra bien.', 'in-progress', 'medium', 'Mantenimiento', 'Vigilancia', 'vigilancia@empresa.com', user_mant, NOW() - INTERVAL '78 days', NOW() - INTERVAL '6 days'),
    ('TKT-TEST-0061', 'Cambio de luminarias a LED', 'Proyecto de cambio de iluminación en piso 2.', 'in-progress', 'low', 'Mantenimiento', 'Sustentabilidad', 'sustentabilidad@empresa.com', user_mant, NOW() - INTERVAL '135 days', NOW() - INTERVAL '25 days'),
    ('TKT-TEST-0062', 'Impermeabilización de terraza', 'Trabajos de impermeabilización en terraza accesible.', 'in-progress', 'medium', 'Mantenimiento', 'Administración Edificio', 'admin.edificio@empresa.com', user_mant, NOW() - INTERVAL '175 days', NOW() - INTERVAL '10 days'),
    ('TKT-TEST-0063', 'Reparación de grupo electrógeno', 'Mantenimiento correctivo del generador de emergencia.', 'in-progress', 'high', 'Mantenimiento', 'Gerencia General', 'gerencia@empresa.com', user_mant, NOW() - INTERVAL '235 days', NOW() - INTERVAL '18 days'),
    ('TKT-TEST-0064', 'Ampliación de oficinas', 'Obra de ampliación del área de desarrollo.', 'in-progress', 'medium', 'Mantenimiento', 'Dirección de Proyectos', 'proyectos@empresa.com', user_mant, NOW() - INTERVAL '295 days', NOW() - INTERVAL '40 days'),
    
    -- Compras e Insumos - In Progress
    ('TKT-TEST-0065', 'Licitación de mobiliario', 'Evaluando cotizaciones para mobiliario nuevo.', 'in-progress', 'medium', 'Compras e Insumos', 'Gerencia Administrativa', 'admin@empresa.com', user_compras, NOW() - INTERVAL '11 days', NOW() - INTERVAL '3 days'),
    ('TKT-TEST-0066', 'Compra de equipos de informática', 'Proceso de compra de 15 notebooks nuevas.', 'in-progress', 'high', 'Compras e Insumos', 'IT Director', 'it.director@empresa.com', user_compras, NOW() - INTERVAL '22 days', NOW() - INTERVAL '2 days'),
    ('TKT-TEST-0067', 'Contrato de servicio de limpieza', 'Renovando contrato con empresa de limpieza.', 'in-progress', 'medium', 'Compras e Insumos', 'Facilities', 'facilities@empresa.com', user_compras, NOW() - INTERVAL '58 days', NOW() - INTERVAL '8 days'),
    ('TKT-TEST-0068', 'Proveedor de insumos de cafetería', 'Negociando nuevo contrato de provisión.', 'in-progress', 'low', 'Compras e Insumos', 'RRHH', 'rrhh@empresa.com', user_compras, NOW() - INTERVAL '105 days', NOW() - INTERVAL '15 days'),
    ('TKT-TEST-0069', 'Compra de EPP', 'Adquiriendo elementos de protección personal.', 'in-progress', 'high', 'Compras e Insumos', 'Seguridad e Higiene', 'seguridad@empresa.com', user_compras, NOW() - INTERVAL '155 days', NOW() - INTERVAL '7 days'),
    ('TKT-TEST-0070', 'Renovación flota vehicular', 'Cotizando vehículos para renovación de flota.', 'in-progress', 'medium', 'Compras e Insumos', 'Logística', 'logistica@empresa.com', user_compras, NOW() - INTERVAL '205 days', NOW() - INTERVAL '35 days'),
    
    -- Administrador - In Progress
    ('TKT-TEST-0071', 'Migración de servidor de email', 'Migrando servidor de correo a nueva infraestructura.', 'in-progress', 'high', 'Administrador', 'IT Team', 'it.team@empresa.com', user_admin, NOW() - INTERVAL '13 days', NOW() - INTERVAL '1 day'),
    ('TKT-TEST-0072', 'Implementación nuevo ERP', 'Proyecto de implementación de sistema ERP.', 'in-progress', 'high', 'Administrador', 'Dirección', 'direccion@empresa.com', user_admin, NOW() - INTERVAL '28 days', NOW() - INTERVAL '2 days'),
    ('TKT-TEST-0073', 'Auditoría de seguridad informática', 'Realizando auditoría de seguridad de sistemas.', 'in-progress', 'high', 'Administrador', 'Auditoría', 'auditoria@empresa.com', user_admin, NOW() - INTERVAL '62 days', NOW() - INTERVAL '5 days'),
    ('TKT-TEST-0074', 'Configuración de firewall', 'Actualizando reglas de firewall corporativo.', 'in-progress', 'high', 'Administrador', 'Seguridad IT', 'security.it@empresa.com', user_admin, NOW() - INTERVAL '92 days', NOW() - INTERVAL '3 days'),
    ('TKT-TEST-0075', 'Expansión de red WiFi', 'Instalando nuevos access points en el edificio.', 'in-progress', 'medium', 'Administrador', 'Infraestructura', 'infra@empresa.com', user_admin, NOW() - INTERVAL '148 days', NOW() - INTERVAL '12 days'),
    ('TKT-TEST-0076', 'Actualización de servidores', 'Upgrade de hardware en servidores principales.', 'in-progress', 'high', 'Administrador', 'Datacenter', 'datacenter@empresa.com', user_admin, NOW() - INTERVAL '195 days', NOW() - INTERVAL '8 days'),
    ('TKT-TEST-0077', 'Implementación autenticación 2FA', 'Desplegando doble factor de autenticación.', 'in-progress', 'high', 'Administrador', 'CISO', 'ciso@empresa.com', user_admin, NOW() - INTERVAL '255 days', NOW() - INTERVAL '20 days'),
    ('TKT-TEST-0078', 'Migración a Office 365', 'Proyecto de migración a suite cloud Microsoft.', 'in-progress', 'medium', 'Administrador', 'IT Manager', 'it.manager@empresa.com', user_admin, NOW() - INTERVAL '315 days', NOW() - INTERVAL '50 days'),
    ('TKT-TEST-0079', 'Desarrollo de intranet', 'Proyecto de nueva intranet corporativa.', 'in-progress', 'medium', 'Administrador', 'Comunicación Interna', 'comunicacion@empresa.com', user_admin, NOW() - INTERVAL '340 days', NOW() - INTERVAL '30 days'),
    ('TKT-TEST-0080', 'Sistema de control de acceso', 'Implementando tarjetas RFID para acceso.', 'in-progress', 'medium', 'Administrador', 'Seguridad Física', 'seguridad.fisica@empresa.com', user_admin, NOW() - INTERVAL '355 days', NOW() - INTERVAL '25 days');

    -- ============================================
    -- TICKETS CERRADOS (CLOSED) - 20 tickets
    -- ============================================
    
    INSERT INTO tickets (tracking_id, title, description, status, priority, department, created_by_name, created_by_email, assigned_to, created_at, updated_at) VALUES
    ('TKT-TEST-0081', 'Mouse inalámbrico no funciona', 'El mouse dejó de funcionar, se cambiaron las pilas y sigue igual.', 'closed', 'low', 'Sistemas', 'Esteban Luna', 'esteban.luna@empresa.com', user_support, NOW() - INTERVAL '180 days', NOW() - INTERVAL '175 days'),
    ('TKT-TEST-0082', 'Solicitud de auriculares', 'Necesito auriculares para videollamadas.', 'closed', 'low', 'Sistemas', 'Melisa Paz', 'melisa.paz@empresa.com', user_support, NOW() - INTERVAL '200 days', NOW() - INTERVAL '195 days'),
    ('TKT-TEST-0083', 'Error en facturación electrónica', 'El sistema de facturación daba error de conexión AFIP.', 'closed', 'high', 'Sistemas', 'Facturación', 'facturacion@empresa.com', user_support, NOW() - INTERVAL '150 days', NOW() - INTERVAL '148 days'),
    ('TKT-TEST-0084', 'Reinstalación de Office', 'Office dejó de funcionar después de actualización.', 'closed', 'medium', 'Sistemas', 'Germán Acuña', 'german.acuna@empresa.com', user_support, NOW() - INTERVAL '260 days', NOW() - INTERVAL '257 days'),
    
    ('TKT-TEST-0085', 'Constancia de trabajo urgente', 'Necesitaba constancia para trámite inmobiliario.', 'closed', 'high', 'Recursos Humanos', 'María del Carmen', 'mdc@empresa.com', user_rrhh, NOW() - INTERVAL '120 days', NOW() - INTERVAL '119 days'),
    ('TKT-TEST-0086', 'Corrección de recibo de sueldo', 'El concepto de horas extra estaba mal calculado.', 'closed', 'high', 'Recursos Humanos', 'Pablo Giménez', 'pablo.gimenez@empresa.com', user_rrhh, NOW() - INTERVAL '90 days', NOW() - INTERVAL '87 days'),
    ('TKT-TEST-0087', 'Licencia por mudanza', 'Solicité días por mudanza según convenio.', 'closed', 'low', 'Recursos Humanos', 'Lucía Bravo', 'lucia.bravo@empresa.com', user_rrhh, NOW() - INTERVAL '270 days', NOW() - INTERVAL '268 days'),
    ('TKT-TEST-0088', 'Alta en sistema de asistencia', 'Nuevo empleado no podía fichar.', 'closed', 'medium', 'Recursos Humanos', 'RRHH Admin', 'rrhh.admin@empresa.com', user_rrhh, NOW() - INTERVAL '310 days', NOW() - INTERVAL '309 days'),
    
    ('TKT-TEST-0089', 'Caño roto en baño', 'Había una pérdida importante en el baño de mujeres.', 'closed', 'high', 'Mantenimiento', 'Limpieza', 'limpieza@empresa.com', user_mant, NOW() - INTERVAL '100 days', NOW() - INTERVAL '99 days'),
    ('TKT-TEST-0090', 'Cerradura de oficina', 'La llave no giraba en la cerradura.', 'closed', 'medium', 'Mantenimiento', 'Mario Sánchez', 'mario.sanchez@empresa.com', user_mant, NOW() - INTERVAL '180 days', NOW() - INTERVAL '178 days'),
    ('TKT-TEST-0091', 'Instalación de aire split', 'Se instaló aire acondicionado en oficina nueva.', 'closed', 'medium', 'Mantenimiento', 'Gerencia Comercial', 'comercial@empresa.com', user_mant, NOW() - INTERVAL '230 days', NOW() - INTERVAL '215 days'),
    ('TKT-TEST-0092', 'Reparación de persiana', 'La persiana del salón estaba trabada.', 'closed', 'low', 'Mantenimiento', 'Secretaría', 'secretaria@empresa.com', user_mant, NOW() - INTERVAL '290 days', NOW() - INTERVAL '288 days'),
    
    ('TKT-TEST-0093', 'Pedido urgente de toner', 'Se agotó el toner un viernes antes de cierre.', 'closed', 'high', 'Compras e Insumos', 'Administración', 'administracion@empresa.com', user_compras, NOW() - INTERVAL '75 days', NOW() - INTERVAL '74 days'),
    ('TKT-TEST-0094', 'Compra de botiquín', 'Se compró botiquín nuevo para primeros auxilios.', 'closed', 'medium', 'Compras e Insumos', 'Seguridad e Higiene', 'seguridad@empresa.com', user_compras, NOW() - INTERVAL '140 days', NOW() - INTERVAL '135 days'),
    ('TKT-TEST-0095', 'Renovación papelería', 'Stock de papelería para todo el año.', 'closed', 'low', 'Compras e Insumos', 'Compras Admin', 'compras.admin@empresa.com', user_compras, NOW() - INTERVAL '320 days', NOW() - INTERVAL '310 days'),
    ('TKT-TEST-0096', 'Contrato servicio de catering', 'Se cerró contrato para eventos corporativos.', 'closed', 'medium', 'Compras e Insumos', 'Eventos', 'eventos@empresa.com', user_compras, NOW() - INTERVAL '345 days', NOW() - INTERVAL '340 days'),
    
    ('TKT-TEST-0097', 'Creación de VPN para teletrabajo', 'Se habilitó VPN para todo el equipo de desarrollo.', 'closed', 'high', 'Administrador', 'CTO', 'cto@empresa.com', user_admin, NOW() - INTERVAL '130 days', NOW() - INTERVAL '125 days'),
    ('TKT-TEST-0098', 'Backup y recovery de base de datos', 'Se recuperó BD después de falla de disco.', 'closed', 'high', 'Administrador', 'DBA', 'dba@empresa.com', user_admin, NOW() - INTERVAL '220 days', NOW() - INTERVAL '218 days'),
    ('TKT-TEST-0099', 'Instalación de certificado SSL', 'Se renovó certificado SSL del sitio web.', 'closed', 'high', 'Administrador', 'Webmaster', 'webmaster@empresa.com', user_admin, NOW() - INTERVAL '280 days', NOW() - INTERVAL '279 days'),
    ('TKT-TEST-0100', 'Configuración de dominio interno', 'Se configuró nuevo dominio AD para sucursal.', 'closed', 'medium', 'Administrador', 'IT Sucursal', 'it.sucursal@empresa.com', user_admin, NOW() - INTERVAL '335 days', NOW() - INTERVAL '330 days');

    RAISE NOTICE '✅ Se insertaron 100 tickets de prueba correctamente';
    RAISE NOTICE '   - 40 tickets abiertos (open)';
    RAISE NOTICE '   - 40 tickets en progreso (in-progress)';  
    RAISE NOTICE '   - 20 tickets cerrados (closed)';
    
END $$;

-- Limpiar función temporal
DROP FUNCTION IF EXISTS generate_tracking_id();

-- Verificar resultados
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM tickets WHERE tracking_id LIKE 'TKT-TEST-%'), 1) as percentage
FROM tickets 
WHERE tracking_id LIKE 'TKT-TEST-%'
GROUP BY status
ORDER BY count DESC;
