require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const pg = require('pg');
const { Pool } = pg;

// FIX: Interpretar TIMESTAMP sin zona horaria como UTC-3 (Argentina)
// Esto corrige el desfase de 3 horas en los comentarios
pg.types.setTypeParser(1114, function(stringValue) {
  return new Date(stringValue + "-0300");
});
const path = require('path');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cookieParser = require('cookie-parser');
const webpush = require('web-push');
const { initializeDatabase } = require('./db_init');
const emailService = require('./services/emailService');
const multer = require('multer');
const fs = require('fs');
const helmet = require('helmet');
const xss = require('xss-clean');
const rateLimit = require('express-rate-limit');
const crypto = require('crypto');
let createClient = null;
try {
  createClient = require('@supabase/supabase-js').createClient;
} catch (e) {
  createClient = null;
}

// Configuración de Supabase (PostgreSQL y Storage)
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY;
const supabase = (supabaseUrl && supabaseKey && createClient) ? createClient(supabaseUrl, supabaseKey) : null;
const useSupabaseStorage = !!supabase;

// Helper para resolver rutas a vistas HTML de manera compatible con local y Vercel
function resolveView(folder, filename) {
  const cwdPath = path.join(process.cwd(), folder, filename);
  if (fs.existsSync(cwdPath)) return cwdPath;
  return path.join(__dirname, folder, filename);
}

// Configuración de Multer para subida de archivos (Memoria para Supabase Storage, Disco para local)
const storage = useSupabaseStorage 
  ? multer.memoryStorage()
  : multer.diskStorage({
      destination: function (req, file, cb) {
        const uploadDir = path.join(process.cwd(), 'public/uploads/tickets');
        if (!fs.existsSync(uploadDir)) {
          fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
      },
      filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'ticket-' + uniqueSuffix + path.extname(file.originalname));
      }
    });

// Filtro de archivos (solo imágenes)
const fileFilter = (req, file, cb) => {
  // Aceptar si es tipo imagen
  if (file.mimetype.startsWith('image/')) {
    return cb(null, true);
  }
  
  // Fallback: Verificar extensiones conocidas para formatos móviles (HEIC/HEIF)
  // que a veces no reportan mimetype 'image/*' consistentemente
  const ext = path.extname(file.originalname).toLowerCase();
  const allowedExtensions = ['.heic', '.heif', '.webp', '.avif'];
  
  if (allowedExtensions.includes(ext)) {
    return cb(null, true);
  }

  cb(new Error('Solo se permiten imágenes (JPG, PNG, WebP, HEIC/HEIF)'), false);
};

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 20 * 1024 * 1024, // 20MB en total (se valida por archivo, pero controlaremos el total en el handler)
    files: 3 // Máximo 3 archivos
  },
  fileFilter: fileFilter
});

// --- MANEJO DE ERRORES GLOBALES ---
// Capturar errores no manejados para evitar cierres silenciosos
process.on('uncaughtException', (error) => {
  console.error('❌ EXCEPCIÓN NO CAPTURADA (Uncaught Exception):');
  console.error(error.stack || error);
  // En un entorno de producción, aquí podrías enviar el error a un servicio de monitoreo
  // No salimos inmediatamente para dar oportunidad a registrar el error, pero el proceso suele estar corrupto
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ PROMESA NO MANEJADA (Unhandled Rejection):');
  console.error('Motivo:', reason);
  // No salimos forzosamente, pero es recomendable investigar por qué ocurrió
});
// ----------------------------------

// Configurar Web Push con claves VAPID
if (process.env.VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY) {
  webpush.setVapidDetails(
    process.env.VAPID_SUBJECT || 'mailto:admin@tiquetera.com',
    process.env.VAPID_PUBLIC_KEY,
    process.env.VAPID_PRIVATE_KEY
  );

} else {
  console.warn('⚠️ Claves VAPID no configuradas. Las notificaciones push no funcionarán.');
}

const app = express();
// Confiar en el proxy (Docker / Nginx / reverse proxy) para resolver la IP real del cliente
app.set('trust proxy', 1);
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3005'],
    credentials: true
  }
});

// Almacenar conexiones de usuarios por departamento
const departmentConnections = new Map();
const PORT = process.env.PORT || 3005;

// Validar que JWT_SECRET esté definido
if (!process.env.JWT_SECRET) {
  console.error('❌ ERROR CRÍTICO: La variable de entorno JWT_SECRET no está definida.');
  console.error('   Agrega JWT_SECRET a tu archivo .env o variables de entorno del sistema.');
  console.error('   Ejemplo: JWT_SECRET=tu_clave_secreta_muy_segura_aqui');
  process.exit(1);
}
const JWT_SECRET = process.env.JWT_SECRET;

// Middleware
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3005'],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Security Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https://cdn.socket.io", "https://cdn.jsdelivr.net"],
      scriptSrcAttr: ["'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com", "data:"],
      imgSrc: ["'self'", "data:", "blob:", "https:"],
      connectSrc: ["'self'", "ws:", "wss:", "https://cdn.socket.io"],
      upgradeInsecureRequests: null
    }
  },

  strictTransportSecurity: false,
  crossOriginOpenerPolicy: false // Deshabilitar COOP para evitar bloqueos en red local HTTP
}));

// Data Sanitization against XSS
app.use(xss());

// Rate Limiting general para la API
// Permite navegación normal, polling de tickets y notificaciones en tiempo real sin falsos positivos
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 3000, // 3000 peticiones cada 15 min por IP (~200 req/min)
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Demasiadas peticiones desde esta IP. Por favor intente nuevamente en unos minutos.'
  }
});
app.use('/api', apiLimiter);

// Rate Limiting específico para intentos de Login (protección contra ataques de fuerza bruta)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: parseInt(process.env.LOGIN_RATE_LIMIT_MAX, 10) || 20, // 20 intentos de login cada 15 min
  skipSuccessfulRequests: true, // Logins exitosos no consumen la cuota de reintentos
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: 'Demasiados intentos fallidos de inicio de sesión desde esta IP. Por seguridad, intente de nuevo en 15 minutos.'
  }
});

// Middleware de autenticación JWT (acepta token de header o cookie)
function authenticateToken(req, res, next) {
  // Intentar obtener token de header primero (para compatibilidad)
  const authHeader = req.headers['authorization'];
  let token = authHeader && authHeader.split(' ')[1];

  // Normalizar valores inválidos
  if (token === 'null' || token === 'undefined' || token === '') {
    token = undefined;
  }

  // Si no hay en header, buscar en cookie
  if (!token) {
    token = req.cookies.token;
  }
  
  console.log(`[AUTH DEBUG] URL: ${req.url} | Cookie: ${req.headers.cookie ? 'YES' : 'NO'} | Token found: ${!!token}`);
  if (req.headers.cookie) console.log(`[AUTH DEBUG] Cookies: ${req.headers.cookie}`);

  if (!token) {
    return res.status(401).json({ error: 'Token no proporcionado' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Token inválido o expirado' });
    }
    req.user = user;
    next();
  });
}

// Middleware para proteger rutas HTML (redirige a login)
// Bloqueamos acceso antes de que los archivos privados se carguen (previene Skeletal View Exposure)
function requireAuthPage(req, res, next) {
  const token = req.cookies.token;

  if (!token) {
    console.log('❌ No token cookie in requireAuthPage, redirecting to login');
    return res.redirect('/?error=auth_required');
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      console.log('❌ Token validation failed in requireAuthPage:', err.message);
      res.clearCookie('token');
      return res.redirect('/?error=invalid_token');
    }
    req.user = user;
    next();
  });
}

// Middleware para verificar rol gerencia en páginas
// Si no es gerencia, redirige al panel correspondiente del usuario
function requireGerenciaPage(req, res, next) {
  if (!req.user) {
    return res.redirect('/?error=auth_required');
  }
  if (req.user.role !== 'gerencia') {
    const roleToRoute = {
      administrador: '/administrador',
      support: '/support',
      rrhh: '/rrhh',
      mantenimiento: '/mantenimiento',
      compras: '/compras'
    };
    const targetRoute = roleToRoute[req.user.role] || '/?error=access_denied';
    return res.redirect(targetRoute);
  }
  next();
}

// Middleware para verificar rol administrador en páginas (Estricto)
// Si no es administrador, redirige al panel correspondiente del usuario
function requireAdminPage(req, res, next) {
  if (!req.user) {
    return res.redirect('/?error=auth_required');
  }
  
  if (req.user.role !== 'administrador' && req.user.role !== 'gerencia') {
    // Redirigir al panel correcto según el rol del usuario
    const roleToRoute = {
      gerencia: '/gerencia',
      support: '/support',
      rrhh: '/rrhh',
      mantenimiento: '/mantenimiento',
      compras: '/compras'
    };
    const targetRoute = roleToRoute[req.user.role] || '/?error=access_denied';
    return res.redirect(targetRoute);
  }
  next();
}

// Middleware para verificar rol support o gerencia en páginas
function requireSupportPage(req, res, next) {
  if (!req.user) return res.redirect('/?error=auth_required');
  if (req.user.role !== 'support' && req.user.role !== 'gerencia') {
    return res.redirect('/?error=access_denied');
  }
  next();
}

// Middleware para verificar rol support, administrador o roles departamentales en páginas
function requireTicketManagementPage(req, res, next) {
  if (!req.user) return res.redirect('/?error=auth_required');
  if (!['support', 'administrador', 'rrhh', 'mantenimiento', 'compras'].includes(req.user.role)) {
    return res.redirect('/?error=access_denied');
  }
  next();
}

// Factory para requerir uno de varios roles en páginas
// Si el usuario no tiene el rol permitido, lo redirige a su panel correspondiente
function requireRolePage(allowedRoles = []) {
  return (req, res, next) => {
    if (!req.user) return res.redirect('/?error=auth_required');
    if (!allowedRoles.includes(req.user.role)) {
      const roleToRoute = {
        administrador: '/administrador',
        gerencia: '/gerencia',
        support: '/support',
        rrhh: '/rrhh',
        mantenimiento: '/mantenimiento',
        compras: '/compras'
      };
      const targetRoute = roleToRoute[req.user.role] || '/?error=access_denied';
      return res.redirect(targetRoute);
    }
    next();
  };
}

// Middleware para verificar rol de administrador en API
function isAdmin(req, res, next) {
  if (req.user.role !== 'administrador') {
    return res.status(403).json({ error: 'Acceso denegado. Se requiere rol de administrador' });
  }
  next();
}

// Middleware para verificar rol de administrador o gerencia en API
function isAdminOrGerencia(req, res, next) {
  if (req.user.role !== 'administrador' && req.user.role !== 'gerencia') {
    return res.status(403).json({ error: 'Acceso denegado. Se requiere rol de administrador o gerencia' });
  }
  next();
}

// Middleware para verificar rol de gerencia en API (solo gerencia, NO admin)
function isGerencia(req, res, next) {
  if (req.user.role !== 'gerencia' && req.user.role !== 'administrador') {
    return res.status(403).json({ error: 'Acceso denegado. Se requiere rol de gerencia o administrador' });
  }
  next();
}

// Middleware para verificar rol de soporte o gerencia en API
function isSupportOrGerencia(req, res, next) {
  if (req.user.role !== 'support' && req.user.role !== 'gerencia') {
    return res.status(403).json({ error: 'Acceso denegado' });
  }
  next();
}

// Middleware para verificar acceso a reportes (administrador, gerencia, mantenimiento, soporte, rrhh o compras)
function isAuthorizedForReports(req, res, next) {
  if (!['administrador', 'gerencia', 'mantenimiento', 'support', 'rrhh', 'compras'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Acceso denegado. Se requiere rol autorizado para reportes' });
  }

  // Aislamiento automático según rol departamental
  if (req.user.role === 'mantenimiento') {
    req.query.department = 'Mantenimiento';
    if (req.body) req.body.department = 'Mantenimiento';
  } else if (req.user.role === 'support') {
    req.query.department = 'Sistemas';
    if (req.body) req.body.department = 'Sistemas';
  } else if (req.user.role === 'rrhh') {
    req.query.department = 'RRHH';
    if (req.body) req.body.department = 'RRHH';
  } else if (req.user.role === 'compras') {
    req.query.department = 'Compras';
    if (req.body) req.body.department = 'Compras';
  }

  next();
}

// Middleware para verificar rol de soporte, gerencia o roles departamentales en API
function canManageTickets(req, res, next) {
  if (!['support', 'administrador', 'gerencia', 'rrhh', 'mantenimiento', 'compras'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Acceso denegado' });
  }
  next();
}

// PostgreSQL Database setup (compatible con Supabase, Transaction Pooler en puerto 6543 y PostgreSQL local)
const isServerless = !!process.env.VERCEL;
const dbUrl = process.env.DATABASE_URL || process.env.POSTGRES_URL || process.env.SUPABASE_DB_URL;

const poolConfig = dbUrl ? {
  connectionString: dbUrl,
  ssl: process.env.DB_SSL === 'false' ? false : { rejectUnauthorized: false },
  max: parseInt(process.env.DB_POOL_MAX || (isServerless ? '5' : '20'), 10),
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
} : {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  database: process.env.DB_NAME || 'tiquetera_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'false' ? false : (process.env.DB_SSL === 'true' || (!isServerless && process.env.NODE_ENV === 'production')) ? { rejectUnauthorized: false } : false,
  max: parseInt(process.env.DB_POOL_MAX || (isServerless ? '5' : '20'), 10),
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
};

const pool = new Pool(poolConfig);

// --- MANEJO DE ERRORES DEL POOL ---
pool.on('error', (err) => {
  console.error('❌ ERROR INESPERADO en el pool de PostgreSQL:', err.message);
});
// ----------------------------------

// Forzar zona horaria a UTC-3 en todas las conexiones del pool
pool.on('connect', (client) => {
  client.query("SET TIME ZONE 'America/Argentina/Buenos_Aires'").catch(() => {});
});

// Inicialización de la base de datos controlada y segura para Serverless
let dbInitPromise = null;
function ensureDatabaseInitialized() {
  if (!dbInitPromise) {
    dbInitPromise = initializeDatabase(pool)
      .then(() => {
        console.log('✅ Base de datos inicializada correctamente.');
      })
      .catch((error) => {
        console.error('⚠️ Advertencia en inicialización de base de datos:', error.message);
        if (!isServerless) {
          process.exit(1);
        }
      });
  }
  return dbInitPromise;
}

// En entornos de servidor dedicado/local, verificar e inicializar al arrancar
if (!isServerless) {
  pool.connect()
    .then(async (client) => {
      try {
        client.release();
        await ensureDatabaseInitialized();
      } catch (error) {
        console.error('❌ Falló la inicialización de la base de datos:', error.message);
        process.exit(1);
      }
    })
    .catch((err) => {
      console.error('❌ ERROR AL CONECTAR con PostgreSQL:', err.message);
      console.error('   Verifica que PostgreSQL esté corriendo y las credenciales sean correctas.');
      process.exit(1);
    });
} else {
  // En Vercel Serverless, inicializar en segundo plano sin interrumpir arranque de lambdas
  ensureDatabaseInitialized().catch(() => {});
}


// Routes

// Verificar sesión actual
app.get('/api/auth/verify', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, email, role, department, active FROM users WHERE id = $1",
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const user = result.rows[0];
    if (user.active === false) {
      return res.status(403).json({ error: 'Tu usuario está desactivado. Por favor contacta con la administración.' });
    }

    res.json({ user });
  } catch (error) {
    console.error('Error en verificación de auth:', error.message);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Change Password Endpoint - REQUIRE AUTH
app.put('/api/auth/change-password', authenticateToken, async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.user.id; // From token

  // Validaciones básicas
  if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Debes ingresar la contraseña actual y la nueva' });
  }

  // Validación de seguridad para contraseña
  // Mínimo 8 caracteres, al menos una mayúscula y un número o símbolo
  // Regex: min 8, 1 uppercase, 1 special char/number handled loosely for UX, strictly for admin
  /* 
     Para evitar bloqueos innecesarios, usaremos una validación razonable:
     - Min 6 caracteres
  */
  if (newPassword.length < 6) {
      return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres' });
  }

  try {
      // 1. Obtener hash actual
      const userResult = await pool.query("SELECT password FROM users WHERE id = $1", [userId]);
      if (userResult.rows.length === 0) {
          return res.status(404).json({ error: 'Usuario no encontrado' });
      }
      
      const storedHash = userResult.rows[0].password;

      // 2. Verificar contraseña actual
      const valid = await bcrypt.compare(currentPassword, storedHash);
      if (!valid) {
           return res.status(401).json({ error: 'La contraseña actual es incorrecta' });
      }

      // 3. Hashear nueva
      const salt = await bcrypt.genSalt(10);
      const newHash = await bcrypt.hash(newPassword, salt);

      // 4. Actualizar
      await pool.query("UPDATE users SET password = $1 WHERE id = $2", [newHash, userId]);

      res.json({ message: 'Contraseña actualizada correctamente' });

  } catch (err) {
      console.error('Error changing password:', err);
      res.status(500).json({ error: 'Error al cambiar la contraseña' });
  }
});

// Áreas válidas del sistema
const VALID_DEPARTMENTS = [
  'Recursos Humanos',
  'Sistemas',
  'Mantenimiento',
  'Compras e Insumos',
  'Administrador'
];

// Ahora TODAS las áreas tienen asignación automática a su único usuario responsable
const AUTO_ASSIGN_DEPARTMENTS = VALID_DEPARTMENTS;

// Áreas restringidas: el administrador NO puede ver estos tickets
// Solo los usuarios asignados de cada departamento tienen acceso
const RESTRICTED_DEPARTMENTS = ['Recursos Humanos', 'Compras e Insumos'];

// Mapeo de área a rol de usuario
const DEPARTMENT_TO_ROLE = {
  'Recursos Humanos': 'rrhh',
  'Sistemas': 'support',
  'Mantenimiento': 'mantenimiento',
  'Compras e Insumos': 'compras',
  'Administrador': 'administrador'
};

// Función auxiliar para validar email
function isValidEmail(email) {
  if (!email) return true; // Email es opcional en algunos casos
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// Función auxiliar para construir consultas SQL parametrizadas con filtros y paginación
function buildTicketsQuery({ baseConditions = [], baseParams = [], query = {}, userRole = null }) {
  const conditions = [...baseConditions];
  const params = [...baseParams];

  // 1. Filtro por estado
  if (query.status && ['open', 'in-progress', 'closed'].includes(query.status)) {
    params.push(query.status);
    conditions.push(`t.status = $${params.length}`);
  }

  // 2. Filtro por prioridad
  if (query.priority && ['low', 'medium', 'high', 'urgent'].includes(query.priority)) {
    params.push(query.priority);
    conditions.push(`t.priority = $${params.length}`);
  }

  // 3. Filtro por sede
  if (query.sede && ['Ciudad', 'Maipú', 'San Martín'].includes(query.sede)) {
    params.push(query.sede);
    conditions.push(`t.sede = $${params.length}`);
  }

  // 4. Filtro por departamento
  if (query.department && VALID_DEPARTMENTS.includes(query.department)) {
    params.push(query.department);
    conditions.push(`t.department = $${params.length}`);
  }

  // 5. Filtro por rango de fechas
  if (query.startDate) {
    params.push(query.startDate);
    conditions.push(`t.created_at >= $${params.length}::timestamp`);
  }
  if (query.endDate) {
    params.push(query.endDate + ' 23:59:59.999');
    conditions.push(`t.created_at <= $${params.length}::timestamp`);
  }

  // 6. Búsqueda por texto (tracking_id, título, descripción, creador, email)
  if (query.search && typeof query.search === 'string' && query.search.trim()) {
    params.push(`%${query.search.trim().toLowerCase()}%`);
    const pIdx = params.length;
    conditions.push(`(
      LOWER(t.tracking_id) LIKE $${pIdx} OR
      LOWER(t.title) LIKE $${pIdx} OR
      LOWER(t.description) LIKE $${pIdx} OR
      LOWER(t.created_by_name) LIKE $${pIdx} OR
      LOWER(COALESCE(t.created_by_email, '')) LIKE $${pIdx}
    )`);
  }

  // 7. Si es administrador, excluir departamentos confidenciales
  if (userRole === 'administrador') {
    params.push(RESTRICTED_DEPARTMENTS[0]);
    params.push(RESTRICTED_DEPARTMENTS[1]);
    conditions.push(`t.department NOT IN ($${params.length - 1}, $${params.length})`);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  // 8. Ordenamiento
  const allowedSortCols = {
    'created_at': 't.created_at',
    'updated_at': 't.updated_at',
    'priority': 't.priority',
    'status': 't.status',
    'sede': 't.sede'
  };
  const sortCol = allowedSortCols[query.sortBy] || 't.created_at';
  const sortOrder = (query.sortOrder && query.sortOrder.toUpperCase() === 'ASC') ? 'ASC' : 'DESC';
  const orderClause = `ORDER BY ${sortCol} ${sortOrder}`;

  // 9. Paginación opcional
  let paginationClause = '';
  let isPaginated = false;
  let limit = null;
  let page = 1;

  if (query.limit) {
    limit = parseInt(query.limit, 10);
    if (!isNaN(limit) && limit > 0) {
      isPaginated = true;
      page = parseInt(query.page, 10) || 1;
      const offset = (page - 1) * limit;
      params.push(limit);
      const limitIdx = params.length;
      params.push(offset);
      const offsetIdx = params.length;
      paginationClause = `LIMIT $${limitIdx} OFFSET $${offsetIdx}`;
    }
  }

  const selectSql = `
    SELECT t.*, u.name as assigned_to_name
    FROM tickets t
    LEFT JOIN users u ON t.assigned_to = u.id
    ${whereClause}
    ${orderClause}
    ${paginationClause}
  `;

  const countSql = `
    SELECT COUNT(*) as total
    FROM tickets t
    ${whereClause}
  `;

  return { selectSql, countSql, params, isPaginated, limit, page };
}

// Get all tickets (gerencia view) - REQUIERE AUTENTICACIÓN
// El administrador NO puede ver tickets de departamentos restringidos (RRHH, Compras)
app.get('/api/tickets', authenticateToken, isGerencia, async (req, res) => {
  try {
    const { selectSql, countSql, params, isPaginated, limit, page } = buildTicketsQuery({
      query: req.query,
      userRole: req.user.role
    });

    const result = await pool.query(selectSql, params);

    if (isPaginated || req.query.paginated === 'true') {
      const countParams = params.slice(0, isPaginated ? params.length - 2 : params.length);
      const countResult = await pool.query(countSql, countParams);
      const total = parseInt(countResult.rows[0].total, 10);
      return res.json({
        tickets: result.rows,
        total,
        page,
        limit: limit || result.rows.length,
        totalPages: limit ? Math.ceil(total / limit) : 1
      });
    }

    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener tickets:', error.message);
    res.status(500).json({ error: 'Error al obtener tickets' });
  }
});

// Get tickets assigned to a specific user - REQUIERE AUTENTICACIÓN y rol que pueda gestionar tickets
app.get('/api/tickets/assigned/:userId', authenticateToken, canManageTickets, async (req, res) => {
  try {
    const { userId } = req.params;

    // Obtener información del usuario para saber su departamento/rol
    const userResult = await pool.query('SELECT role, department FROM users WHERE id = $1', [userId]);
    const targetUser = userResult.rows[0];

    let baseConditions = ['t.assigned_to = $1'];
    let baseParams = [userId];

    if (targetUser) {
      const roleToDept = {
        'support': 'Sistemas',
        'mantenimiento': 'Mantenimiento',
        'compras': 'Compras e Insumos',
        'rrhh': 'Recursos Humanos'
      };
      const deptName = targetUser.department || roleToDept[targetUser.role];
      if (deptName) {
        baseConditions = ['(t.assigned_to = $1 OR t.department = $2)'];
        baseParams = [userId, deptName];
      }
    }

    const { selectSql, countSql, params, isPaginated, limit, page } = buildTicketsQuery({
      baseConditions,
      baseParams,
      query: req.query
    });

    const result = await pool.query(selectSql, params);

    if (isPaginated || req.query.paginated === 'true') {
      const countParams = params.slice(0, isPaginated ? params.length - 2 : params.length);
      const countResult = await pool.query(countSql, countParams);
      const total = parseInt(countResult.rows[0].total, 10);
      return res.json({
        tickets: result.rows,
        total,
        page,
        limit: limit || result.rows.length,
        totalPages: limit ? Math.ceil(total / limit) : 1
      });
    }

    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener tickets asignados:', error.message);
    res.status(500).json({ error: 'Error al obtener tickets asignados' });
  }
});

app.post('/api/tickets', (req, res, next) => {
  // Envolver middleware de multer para manejar errores específicamente
  upload.array('attachments', 3)(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      // Error de Multer (ej. límite de archivos)
      return res.status(400).json({ error: `Error de subida: ${err.message}` });
    } else if (err) {
      // Otro error desconocido
      return res.status(500).json({ error: `Error interno de subida: ${err.message}` });
    }
    // Si no hay error, continuar con el controlador
    next();
  });
}, async (req, res) => {
  try {
    const { title, description, department, name, email, priority, sede } = req.body;
    const files = req.files || [];

    // Validaciones básicas
    if (!title || !description || !name || !email) {
      return res.status(400).json({ error: 'Nombre, email, título y descripción son requeridos' });
    }

    // Validar que no estén vacíos después de trim
    if (!title.trim() || !description.trim() || !name.trim()) {
      return res.status(400).json({ error: 'Los campos no pueden contener solo espacios' });
    }

    // Validar área obligatoria
    if (!department) {
      return res.status(400).json({ error: 'El área de asignación es requerida' });
    }

    // Validar que el área sea válida
    if (!VALID_DEPARTMENTS.includes(department)) {
      return res.status(400).json({ error: 'Área de asignación inválida' });
    }

    // Validar sede obligatoria
    const VALID_SEDES = ['Ciudad', 'Maipú', 'San Martín'];
    if (!sede) {
      return res.status(400).json({ error: 'La sede es requerida' });
    }
    if (!VALID_SEDES.includes(sede)) {
      return res.status(400).json({ error: 'Sede inválida. Debe ser: Ciudad, Maipú o San Martín' });
    }

    // Validar formato de email si se proporciona
    if (email && !isValidEmail(email)) {
      return res.status(400).json({ error: 'Formato de email inválido' });
    }

    // Validar longitudes
    if (title.length > 200) {
      return res.status(400).json({ error: 'El título no puede exceder 200 caracteres' });
    }

    if (description.length > 2000) {
      return res.status(400).json({ error: 'La descripción no puede exceder 2000 caracteres' });
    }

    // Validar prioridad si se proporciona
    if (priority && !['low', 'medium', 'high'].includes(priority)) {
      return res.status(400).json({ error: 'Prioridad inválida' });
    }

    // Procesar archivos adjuntos (Supabase Storage o almacenamiento local)
    let attachments = [];
    if (useSupabaseStorage && files.length > 0) {
      for (const file of files) {
        try {
          const ext = path.extname(file.originalname).toLowerCase();
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
          const filePath = `tickets/${uniqueSuffix}${ext}`;

          const { error: uploadError } = await supabase.storage
            .from('ticket-attachments')
            .upload(filePath, file.buffer, {
              contentType: file.mimetype || 'image/jpeg',
              upsert: true
            });

          if (uploadError) {
            console.error('⚠️ Error al subir adjunto a Supabase Storage:', uploadError.message);
          } else {
            const { data: urlData } = supabase.storage
              .from('ticket-attachments')
              .getPublicUrl(filePath);
            if (urlData && urlData.publicUrl) {
              attachments.push(urlData.publicUrl);
            }
          }
        } catch (storageErr) {
          console.error('⚠️ Excepción al procesar adjunto en Supabase Storage:', storageErr.message);
        }
      }
    } else if (files.length > 0) {
      attachments = files.map(file => `/uploads/tickets/${file.filename}`);
    }

    // Generar tracking ID único
    const generateTrackingId = () => {
      const timestamp = Date.now().toString(36).toUpperCase();
      const random = Math.random().toString(36).substring(2, 6).toUpperCase();
      return `TKT-${timestamp}-${random}`;
    };

    const trackingId = generateTrackingId();

    // Determinar si se debe asignar automáticamente
    let assignedTo = null;

    if (AUTO_ASSIGN_DEPARTMENTS.includes(department)) {
      // Buscar el usuario activo del área correspondiente
      const role = DEPARTMENT_TO_ROLE[department];
      const userResult = await pool.query(
        `SELECT id FROM users 
         WHERE (department = $1 OR role = $2) AND active = TRUE 
         ORDER BY 
           CASE WHEN department = $1 THEN 0 ELSE 1 END,
           CASE WHEN email IN ('soporte@tiquetera.com', 'mantenimiento@tiquetera.com', 'compras@tiquetera.com', 'rrhh@tiquetera.com') THEN 0 ELSE 1 END,
           id ASC 
         LIMIT 1`,
        [department, role]
      );

      if (userResult.rows.length > 0) {
        assignedTo = userResult.rows[0].id;
      }
    }

    // Query actualizada para incluir attachments y sede
    const query = `
      INSERT INTO tickets (tracking_id, title, description, department, created_by_name, created_by_email, priority, assigned_to, attachments, affected_area, sede)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *
    `;

    const result = await pool.query(query, [
      trackingId,
      title,
      description,
      department,
      name,
      email,
      priority || 'medium',
      assignedTo,
      JSON.stringify(attachments),
      req.body.affected_area || null,
      sede
    ]);

    // Debugging Priority Issue
    console.log(`[CREATE TICKET DEBUG] TrackingID: ${trackingId} | Raw Priority: "${priority}" | Inserted Priority: "${priority || 'medium'}"`);

    const createdTicket = result.rows[0];

    // Crear notificación para el departamento correspondiente
    const notificationTitle = `Nuevo ticket: ${title.substring(0, 50)}${title.length > 50 ? '...' : ''}`;
    const notificationMessage = `${name} ha creado un nuevo ticket`;

    const notifResult = await pool.query(
      `INSERT INTO notifications (ticket_id, department, title, message, ticket_tracking_id, created_by_name)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [createdTicket.id, department, notificationTitle, notificationMessage, trackingId, name]
    );

    const notification = notifResult.rows[0];

    // Emitir notificación en tiempo real via WebSocket
    io.to(`department:${department}`).emit('new_notification', {
      id: notification.id,
      ticketId: createdTicket.id,
      trackingId: trackingId,
      department: department,
      title: notificationTitle,
      message: notificationMessage,
      createdByName: name,
      createdAt: notification.created_at
    });

    // Enviar Push Notification al departamento
    if (typeof sendPushToDepartment === 'function') {
        sendPushToDepartment(department, {
        id: notification.id,
        ticketId: createdTicket.id,
        trackingId: trackingId,
        title: notificationTitle,
        message: notificationMessage
        }, priority || 'medium');
    }

    // También notificar al Administrador si el ticket no es para su área
    // EXCEPTO para departamentos restringidos (RRHH, Compras) que son confidenciales
    if (department !== 'Administrador' && !RESTRICTED_DEPARTMENTS.includes(department)) {
      const adminNotifResult = await pool.query(
        `INSERT INTO notifications (ticket_id, department, title, message, ticket_tracking_id, created_by_name)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [createdTicket.id, 'Administrador', notificationTitle, notificationMessage, trackingId, name]
      );

      const adminNotification = adminNotifResult.rows[0];
      io.to('department:Administrador').emit('new_notification', {
        id: adminNotification.id,
        ticketId: createdTicket.id,
        trackingId: trackingId,
        department: 'Administrador',
        title: notificationTitle,
        message: notificationMessage,
        createdByName: name,
        createdAt: adminNotification.created_at
      });

      // Enviar Push Notification al Administrador
      if (typeof sendPushToDepartment === 'function') {
        sendPushToDepartment('Administrador', {
            id: adminNotification.id,
            ticketId: createdTicket.id,
            trackingId: trackingId,
            title: notificationTitle,
            message: notificationMessage
        }, priority || 'medium');
      }
    }


    // Enviar notificación de email de confirmación al creador
    if (emailService && typeof emailService.sendTicketCreated === 'function') {
      try {
        emailService.sendTicketCreated(createdTicket);
      } catch (emailErr) {
        console.error('Error sending confirmation email:', emailErr);
      }
    }

    // Invalidar caché de reportes para reflejar el nuevo ticket
    if (typeof invalidateReportCache === 'function') invalidateReportCache();

    // Enviar respuesta exitosa al cliente para detener el spinner
    res.status(201).json({
      id: createdTicket.id,
      tracking_id: trackingId,
      message: 'Ticket creado exitosamente',
      ticket: createdTicket
    });
  } catch (error) {
    console.error('Error al crear ticket:', error.message);
    res.status(500).json({ error: 'Error al crear ticket' });
  }
});

// Middleware para verificar rol de soporte, gerencia o roles departamentales en API
function canManageTickets(req, res, next) {
  if (!['support', 'administrador', 'gerencia', 'rrhh', 'mantenimiento', 'compras'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Acceso denegado' });
  }
  next();
}

// Middleware para verificar permisos de ESCRITURA en tickets (excluye admin)
function canWriteTickets(req, res, next) {
  // El administrador tiene solo permiso de LECTURA en tickets
  if (req.user.role === 'administrador') {
    return res.status(403).json({ error: 'El administrador tiene acceso de solo lectura a los tickets.' });
  }
  
  if (!['support', 'gerencia', 'rrhh', 'mantenimiento', 'compras'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Acceso denegado' });
  }
  next();
}

// Update ticket status - REQUIERE AUTENTICACIÓN Y ESCRITURA
// El administrador NO puede modificar tickets (solo lectura)
app.put('/api/tickets/:id', authenticateToken, canWriteTickets, async (req, res) => {
  const { id } = req.params;
  const { status, priority } = req.body;

  try {
    // Verificar permisos sobre el ticket específico y obtener estado previo
    const ticketCheck = await pool.query(
        "SELECT id, department, status, priority, title FROM tickets WHERE id = $1",
        [id]
    );

    if (ticketCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Ticket no encontrado' });
    }

    const previousTicket = ticketCheck.rows[0];
    const ticketDept = previousTicket.department;

    // Lógica de permisos por rol
    if (req.user.role === 'administrador') {
        return res.status(403).json({ error: 'Solo lectura' });
    }

    // Roles departamentales: Solo su propio departamento
    if (!['support', 'gerencia'].includes(req.user.role)) {
        const roleToDept = {
            'rrhh': 'Recursos Humanos',
            'mantenimiento': 'Mantenimiento',
            'compras': 'Compras e Insumos'
        };

        const allowedDept = roleToDept[req.user.role];
        if (ticketDept !== allowedDept) {
             return res.status(403).json({ error: 'No tienes permiso para modificar tickets de otro departamento' });
        }
    }

    let updates = [];
    let params = [];
    let paramCount = 1;

    if (status) {
      const validStatuses = ['open', 'in-progress', 'closed'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ error: 'Estado inválido' });
      }
      updates.push(`status = $${paramCount++}`);
      params.push(status);
    }

    if (priority) {
      const validPriorities = ['low', 'medium', 'high'];
      if (!validPriorities.includes(priority)) {
        return res.status(400).json({ error: 'Prioridad inválida' });
      }
      updates.push(`priority = $${paramCount++}`);
      params.push(priority);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No hay campos para actualizar' });
    }

    const query = `UPDATE tickets SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = $${paramCount} RETURNING *`;
    params.push(id);

    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket no encontrado' });
    }

    // Registrar cambios en el historial (ticket_updates)
    const actorName = req.user.name || req.user.email || 'Usuario';

    if (status && status !== previousTicket.status) {
      const statusNames = { 'open': 'Abierto', 'in-progress': 'En Progreso', 'closed': 'Cerrado' };
      const newStatusName = statusNames[status] || status;
      const oldStatusName = statusNames[previousTicket.status] || previousTicket.status;
      let historyText = '';

      if (previousTicket.status === 'closed' && status !== 'closed') {
        historyText = `🔓 Ticket reabierto por ${actorName} (Estado: ${newStatusName})`;
      } else if (status === 'closed') {
        historyText = `🔒 Ticket cerrado por ${actorName}`;
      } else {
        historyText = `🔄 Estado cambiado de "${oldStatusName}" a "${newStatusName}" por ${actorName}`;
      }

      await pool.query(
        `INSERT INTO ticket_updates (ticket_id, user_id, update_type, content, created_at)
         VALUES ($1, $2, 'status_change', $3, NOW())`,
        [id, req.user.id || null, historyText]
      );
    }

    if (priority && priority !== previousTicket.priority) {
      const priorityNames = { 'low': 'Baja', 'medium': 'Media', 'high': 'Alta' };
      const newPriorityName = priorityNames[priority] || priority;
      const oldPriorityName = priorityNames[previousTicket.priority] || previousTicket.priority;
      const historyText = `⚠️ Prioridad cambiada de "${oldPriorityName}" a "${newPriorityName}" por ${actorName}`;

      await pool.query(
        `INSERT INTO ticket_updates (ticket_id, user_id, update_type, content, created_at)
         VALUES ($1, $2, 'priority_change', $3, NOW())`,
        [id, req.user.id || null, historyText]
      );
    }

    const ticketWithUser = await pool.query(
      `SELECT t.*, u.name as assigned_to_name 
       FROM tickets t 
       LEFT JOIN users u ON t.assigned_to = u.id 
       WHERE t.id = $1`,
      [id]
    );

    res.json(ticketWithUser.rows[0]);

    // Enviar notificación de email si cambia el estado
    if (status && typeof emailService?.sendTicketStatusChange === 'function') {
      emailService.sendTicketStatusChange(ticketWithUser.rows[0], status);
    }

    // Invalidar caché de reportes
    if (typeof invalidateReportCache === 'function') invalidateReportCache();
  } catch (error) {
    console.error('Error updating ticket:', error.message);
    res.status(500).json({ error: 'Error al actualizar ticket' });
  }
});

// Add comment/update to ticket - REQUIERE AUTENTICACIÓN
// El administrador tiene solo lectura, no puede comentar/actualizar
app.post('/api/tickets/:id/updates', authenticateToken, canWriteTickets, async (req, res) => {
  const { id } = req.params;
  let { content, user_id, update_type } = req.body;

  if (!content || typeof content !== 'string' || !content.trim()) {
    return res.status(400).json({ error: 'El contenido del comentario es requerido' });
  }

  content = content.trim();
  if (content.length > 3000) {
    return res.status(400).json({ error: 'El comentario no puede superar los 3000 caracteres' });
  }

  try {
    // Verificar permisos sobre el ticket
    const ticketCheck = await pool.query(
        "SELECT department FROM tickets WHERE id = $1",
        [id]
    );

    if (ticketCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Ticket no encontrado' });
    }

    const ticketDept = ticketCheck.rows[0].department;

     // 1. Administrador: Solo lectura
     if (req.user.role === 'administrador') {
        return res.status(403).json({ error: 'Solo lectura' });
    }

    // 2. Soporte y Gerencia: Acceso total
    if (['support', 'gerencia'].includes(req.user.role)) {
        // ok
    } else {
        // 3. Roles departamentales
        const roleToDept = {
            'rrhh': 'Recursos Humanos',
            'mantenimiento': 'Mantenimiento',
            'compras': 'Compras e Insumos'
        };
         const allowedDept = roleToDept[req.user.role];
        if (ticketDept !== allowedDept) {
             return res.status(403).json({ error: 'No tienes permiso para comentar en tickets de otro departamento' });
        }
    }

    const query = `
      INSERT INTO ticket_updates (ticket_id, user_id, update_type, content)
      VALUES ($1, $2, $3, $4)
      RETURNING id
    `;

    const result = await pool.query(query, [
      id,
      user_id || null,
      update_type || 'comment',
      content
    ]);

    res.status(201).json({
      id: result.rows[0].id,
      message: 'Actualización agregada exitosamente'
    });

    // Enviar notificación de email sobre la respuesta
    // Obtenemos los detalles completos del ticket para saber remitentes y destinatarios
    try {
      // Obtener detalles del ticket y usuario asignado
      const ticketResult = await pool.query(
        `SELECT t.*, u.name as assigned_to_name, u.email as assigned_to_email
         FROM tickets t
         LEFT JOIN users u ON t.assigned_to = u.id
         WHERE t.id = $1`,
        [id]
      );

      if (ticketResult.rows.length > 0) {
        const ticket = ticketResult.rows[0];
        
        // Determinar quién hizo la actualización para no auto-notificar
        // req.user contiene el usuario autenticado que hace la acción
        const actionUserEmail = req.user.email;
        const actionUserName = req.user.name;

        // Estructura de actualización para el template
        const updateData = {
          content: content,
          user_name: actionUserName
        };

        // Lógica de notificación bidireccional
        // 1. Si el creador del ticket comenta -> Notificar al asignado (si existe)
        // 2. Si el asignado (o cualquiera de soporte/admin) comenta -> Notificar al creador
        
        // Notificar al Creador del ticket (si no fue él quien comentó)
        if (ticket.created_by_email && ticket.created_by_email !== actionUserEmail) {
          emailService.sendTicketResponse(ticket, updateData, ticket.created_by_email, ticket.created_by_name);
        }

        // Notificar al Asignado (si existe y no fue él quien comentó)
        if (ticket.assigned_to_email && ticket.assigned_to_email !== actionUserEmail) {
          emailService.sendTicketResponse(ticket, updateData, ticket.assigned_to_email, ticket.assigned_to_name);
        }
      }
    } catch (emailErr) {
      console.error('Error enviando notificaciones de respuesta:', emailErr);
      // No fallamos el request si falla el email
    }
  } catch (error) {
    console.error('Error adding ticket update:', error.message);
    res.status(500).json({ error: 'Error al agregar actualización' });
  }
});

// Get ticket updates - REQUIERE AUTENTICACIÓN
// El administrador NO puede ver actualizaciones de tickets de departamentos restringidos
app.get('/api/tickets/:id/updates', authenticateToken, canManageTickets, async (req, res) => {
  const { id } = req.params;

  try {
    // Verificar si el administrador intenta acceder a un ticket restringido
    if (req.user.role === 'administrador') {
      const ticketCheck = await pool.query(
        "SELECT department FROM tickets WHERE id = $1",
        [id]
      );

      if (ticketCheck.rows.length > 0 && RESTRICTED_DEPARTMENTS.includes(ticketCheck.rows[0].department)) {
        return res.status(403).json({ error: 'No tienes permiso para acceder a este ticket' });
      }
    }

    const result = await pool.query(`
      SELECT tu.*, u.name as user_name
      FROM ticket_updates tu
      LEFT JOIN users u ON tu.user_id = u.id
      WHERE tu.ticket_id = $1
      ORDER BY tu.created_at DESC
    `, [id]);

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching ticket updates:', error.message);
    res.status(500).json({ error: 'Error al obtener actualizaciones' });
  }
});

// Get all users (for assignment) - REQUIERE ADMIN O GERENCIA
app.get('/api/users', authenticateToken, isAdminOrGerencia, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, email, role, department FROM users WHERE role IN ('support', 'rrhh', 'mantenimiento', 'compras') AND active = TRUE ORDER BY name"
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error.message);
    res.status(500).json({ error: 'Error al obtener usuarios' });
  }
});

// Get ALL users (para gestión) - REQUIERE ADMIN O GERENCIA
app.get('/api/users/all', authenticateToken, isAdminOrGerencia, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, email, role, department, active, created_at FROM users ORDER BY created_at DESC"
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching all users:', error.message);
    res.status(500).json({ error: 'Error al obtener usuarios' });
  }
});

// Create user - REQUIERE ADMIN O GERENCIA
app.post('/api/users', authenticateToken, isAdminOrGerencia, async (req, res) => {
  const { name, email, password, role, department } = req.body;

  // Validaciones
  if (!name || !email || !password || !role) {
    return res.status(400).json({ error: 'Nombre, email, contraseña y rol son requeridos' });
  }

  // Validar que no estén vacíos después de trim
  if (!name.trim() || !email.trim()) {
    return res.status(400).json({ error: 'Nombre y email no pueden estar vacíos' });
  }

  // Validar formato de email
  if (!isValidEmail(email)) {
    return res.status(400).json({ error: 'Formato de email inválido' });
  }

  // Validar longitud de contraseña
  if (password.length < 8) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 8 caracteres' });
  }

  // Solo ADMINISTRADOR puede crear usuarios administrador o gerencia
  if ((role === 'administrador' || role === 'gerencia') && req.user.role !== 'administrador') {
    return res.status(403).json({ error: 'Solo un administrador puede crear usuarios administrador o gerencia' });
  }

  const validRoles = ['support', 'facturacion', 'rrhh', 'contact', 'gerencia', 'administrador'];
  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: 'Rol inválido' });
  }

  try {
    // Verificar que el email no exista
    const emailCheck = await pool.query("SELECT id FROM users WHERE email = $1", [email]);

    if (emailCheck.rows.length > 0) {
      return res.status(400).json({ error: 'El email ya está registrado' });
    }

    // Hash password
    const hashedPassword = bcrypt.hashSync(password, 8);

    // Crear usuario
    const result = await pool.query(
      "INSERT INTO users (name, email, password, role, department) VALUES ($1, $2, $3, $4, $5) RETURNING id",
      [name, email, hashedPassword, role, department || null]
    );

    res.status(201).json({
      id: result.rows[0].id,
      name,
      email,
      role,
      department,
      message: 'Usuario creado exitosamente'
    });
  } catch (error) {
    console.error('Error creating user:', error.message);
    res.status(500).json({ error: 'Error al crear usuario' });
  }
});

// Update user - REQUIERE ADMIN O GERENCIA
app.put('/api/users/:id', authenticateToken, isAdminOrGerencia, async (req, res) => {
  const { id } = req.params;
  const { name, email, role, department, password, active } = req.body;

  try {
    // Verificar que el usuario existe
    const userCheck = await pool.query("SELECT id, role, email FROM users WHERE id = $1", [id]);

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const targetUser = userCheck.rows[0];

    // Proteger cuenta de administrador principal (no editable ni desactivable desde este endpoint)
    const isDefaultAdmin = targetUser.role === 'administrador' && targetUser.email === 'admin@tiquetera.com';
    if (isDefaultAdmin) {
      return res.status(403).json({ error: 'El usuario administrador principal no se puede editar ni desactivar desde la aplicación. Solo se puede cambiar su contraseña desde la opción dedicada.' });
    }

    // Solo ADMINISTRADOR puede modificar administradores o gerencia
    if ((targetUser.role === 'administrador' || targetUser.role === 'gerencia') && req.user.role !== 'administrador') {
      return res.status(403).json({ error: 'Solo un administrador puede modificar usuarios administrador o gerencia' });
    }

    // Si se intenta cambiar el email, validar que no exista en otro usuario
    if (email) {
      const emailCheck = await pool.query(
        "SELECT id FROM users WHERE email = $1 AND id != $2",
        [email, id]
      );

      if (emailCheck.rows.length > 0) {
        return res.status(400).json({ error: 'El email ya está en uso por otro usuario' });
      }
    }

    // Construir query dinámica
    let updates = [];
    let params = [];
    let paramCount = 1;

    if (name) {
      updates.push(`name = $${paramCount++}`);
      params.push(name);
    }
    if (email) {
      updates.push(`email = $${paramCount++}`);
      params.push(email);
    }
    if (role) {
      // Solo ADMINISTRADOR puede asignar roles administrador o gerencia
      if ((role === 'administrador' || role === 'gerencia') && req.user.role !== 'administrador') {
        return res.status(403).json({ error: 'Solo un administrador puede asignar roles administrador o gerencia' });
      }
      updates.push(`role = $${paramCount++}`);
      params.push(role);
    }
    if (department !== undefined) {
      updates.push(`department = $${paramCount++}`);
      params.push(department);
    }
    if (typeof active !== 'undefined') {
      updates.push(`active = $${paramCount++}`);
      // Aceptar booleano o string "true"/"false"
      const isActive = active === true || active === 'true' || active === 1 || active === '1';
      params.push(isActive);
    }
    if (password) {
      updates.push(`password = $${paramCount++}`);
      params.push(bcrypt.hashSync(password, 8));
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No hay campos para actualizar' });
    }

    const query = `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount}`;
    params.push(id);

    await pool.query(query, params);

    // Devolver usuario actualizado
    const updatedUser = await pool.query(
      "SELECT id, name, email, role, department, created_at FROM users WHERE id = $1",
      [id]
    );

    res.json({
      message: 'Usuario actualizado exitosamente',
      user: updatedUser.rows[0]
    });
  } catch (error) {
    console.error('Error updating user:', error.message);
    res.status(500).json({ error: 'Error al actualizar usuario' });
  }
});

// Delete user - DESHABILITADO: usar activación/desactivación
app.delete('/api/users/:id', authenticateToken, isAdminOrGerencia, async (req, res) => {
  return res.status(405).json({ error: 'La eliminación de usuarios está deshabilitada. Usa activar/desactivar usuario.' });
});

// Cambiar contraseña de cualquier usuario - SOLO ADMINISTRADOR
app.put('/api/users/:id/reset-password', authenticateToken, isAdmin, async (req, res) => {
  const { id } = req.params;
  const { newPassword } = req.body;

  if (!newPassword || newPassword.length < 6) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 6 caracteres' });
  }

  try {
    // Verificar que el usuario existe
    const userCheck = await pool.query("SELECT id, email, name FROM users WHERE id = $1", [id]);

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const user = userCheck.rows[0];

    // Hash de la nueva contraseña
    const hashedPassword = bcrypt.hashSync(newPassword, 8);

    // Actualizar contraseña
    await pool.query("UPDATE users SET password = $1 WHERE id = $2", [hashedPassword, id]);



    res.json({
      message: 'Contraseña actualizada exitosamente',
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      }
    });
  } catch (error) {
    console.error('Error resetting password:', error.message);
    res.status(500).json({ error: 'Error al cambiar contraseña' });
  }
});

// Helper: mapear rol a departamento
const roleToDepartment = {
  support: 'Sistemas',
  facturacion: 'Facturación',
  rrhh: 'Recursos Humanos',
  contact: 'Contact Center',
  mantenimiento: 'Mantenimiento',
  compras: 'Compras e Insumos'
};

// Middleware: acceso por departamento (administrador, gerencia o el dueño)
// El administrador NO puede acceder a departamentos restringidos (RRHH, Compras)
function canAccessDepartment(req, res, next) {
  const requested = decodeURIComponent(req.params.department);

  // El administrador NO puede acceder a departamentos restringidos
  if (req.user.role === 'administrador' && RESTRICTED_DEPARTMENTS.includes(requested)) {
    return res.status(403).json({ error: 'No tienes permiso para acceder a este departamento' });
  }

  if (req.user.role === 'administrador' || req.user.role === 'gerencia') return next();
  const dept = roleToDepartment[req.user.role];
  if (dept && dept === requested) return next();
  return res.status(403).json({ error: 'Acceso denegado al departamento' });
}

// Tickets por departamento (para facturación, rrhh, contact y gerencia)
app.get('/api/tickets/department/:department', authenticateToken, canAccessDepartment, async (req, res) => {
  const department = decodeURIComponent(req.params.department);

  try {
    const { selectSql, countSql, params, isPaginated, limit, page } = buildTicketsQuery({
      baseConditions: ['t.department = $1'],
      baseParams: [department],
      query: req.query
    });

    const result = await pool.query(selectSql, params);

    if (isPaginated || req.query.paginated === 'true') {
      const countParams = params.slice(0, isPaginated ? params.length - 2 : params.length);
      const countResult = await pool.query(countSql, countParams);
      const total = parseInt(countResult.rows[0].total, 10);
      return res.json({
        tickets: result.rows,
        total,
        page,
        limit: limit || result.rows.length,
        totalPages: limit ? Math.ceil(total / limit) : 1
      });
    }

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching tickets by department:', error.message);
    res.status(500).json({ error: 'Error al obtener tickets del departamento' });
  }
});

// Login endpoint con protección de rate limiting específica
app.post('/api/login', loginLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email y contraseña requeridos' });
    }

    // Validar formato de email
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Formato de email inválido' });
    }

    const result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);

    // Mitigación de timing attack: siempre ejecutar bcrypt.compareSync
    const user = result.rows[0];
    const passwordHash = user?.password || '$2a$08$Y.B8FjU4S94wPzJk1FqPoeH3JkGj8vJ3g9F8b5oH8n2x7wS7hWdIe';
    const isValidPassword = bcrypt.compareSync(password, passwordHash);

    // Validar que el usuario existe y la contraseña es correcta
    if (!user || !isValidPassword) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    // Bloquear usuarios inactivos
    if (user.active === false) {
      return res.status(403).json({ error: 'Tu usuario está desactivado. Por favor contacta con la administración.' });
    }

    // Create JWT token con expiración de 24 horas
    const token = jwt.sign(
      { id: user.id, name: user.name, email: user.email, role: user.role, department: user.department },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Establecer token en cookie (httpOnly: true para mitigar ataques XSS)
    res.cookie('token', token, {
      httpOnly: true, // Bloquear acceso JS para mitigar XSS
      secure: false, // Forzar false (necesario para HTTP en red local 192.168.x.x) 
      sameSite: 'lax', // Lax requerido para navegación en red local y evitar bucles de login
      path: '/', // Explícitamente enviar en todas las rutas
      maxAge: 24 * 60 * 60 * 1000 // 24 horas
    });

    res.json({
      token, // También enviar en respuesta para compatibilidad
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department
      }
    });
  } catch (error) {
    console.error('Error en login:', error.message);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Logout endpoint
app.post('/api/logout', (req, res) => {
  res.clearCookie('token');
  res.json({ message: 'Sesión cerrada exitosamente' });
});

// Ruta pública de tracking (sin autenticación)
app.get('/track/:trackingId', (req, res) => {
  res.sendFile(resolveView('public', 'track.html'));
});

// API pública para obtener ticket por tracking ID
app.get('/api/track/:trackingId', async (req, res) => {
  const { trackingId } = req.params;

  try {
    const ticketQuery = `
      SELECT 
        t.id,
        t.tracking_id,
        t.title,
        t.description,
        t.status,
        t.priority,
        t.department,
        t.created_by_name,
        t.created_by_email,
        t.created_at,
        t.updated_at,
        t.attachments,
        t.affected_area,
        u.name as assigned_to_name
      FROM tickets t
      LEFT JOIN users u ON t.assigned_to = u.id
      WHERE t.tracking_id = $1
    `;

    const ticketResult = await pool.query(ticketQuery, [trackingId]);

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket no encontrado' });
    }

    const ticket = ticketResult.rows[0];

    const updatesQuery = `
      SELECT 
        tu.content,
        tu.update_type,
        tu.created_at,
        u.name as user_name
      FROM ticket_updates tu
      LEFT JOIN users u ON tu.user_id = u.id
      WHERE tu.ticket_id = $1
      ORDER BY tu.created_at ASC
    `;

    const updatesResult = await pool.query(updatesQuery, [ticket.id]);

    res.json({ ...ticket, updates: updatesResult.rows || [] });
  } catch (error) {
    console.error('Error fetching ticket by tracking ID:', error.message);
    res.status(500).json({ error: 'Error interno al buscar el ticket' });
  }
});

// Serve frontend
app.get('/', (req, res) => {
  res.sendFile(resolveView('public', 'index.html'));
});

// Rutas protegidas con autenticación y verificación de roles
// Redirigir /admin (legacy) a nuevas rutas o mostrar error
app.get('/admin', requireAuthPage, (req, res) => {
    if (req.user.role === 'administrador') return res.redirect('/administrador');
    if (req.user.role === 'gerencia') return res.redirect('/gerencia');
    return res.redirect('/?error=access_denied');
});

// Panel de Gerencia (Nueva ruta)
app.get('/gerencia', requireAuthPage, requireGerenciaPage, (req, res) => {
  res.sendFile(resolveView('private', 'gerencia.html'));
});

// Panel de administrador (gestión completa) - SOLO ADMINISTRADORES
app.get('/administrador', requireAuthPage, requireAdminPage, (req, res) => {
  res.sendFile(resolveView('private', 'administrador.html'));
});

// Panel de Sistemas - SOLO support y administrador
app.get('/support', requireAuthPage, requireRolePage(['support', 'administrador']), (req, res) => {
  res.sendFile(resolveView('private', 'support.html'));
});

// Panel de RRHH - SOLO rrhh y administrador
app.get('/rrhh', requireAuthPage, requireRolePage(['rrhh', 'administrador']), (req, res) => {
  res.sendFile(resolveView('private', 'rrhh.html'));
});

// Panel de mantenimiento - SOLO mantenimiento y administrador
app.get('/mantenimiento', requireAuthPage, requireRolePage(['mantenimiento', 'administrador']), (req, res) => {
  res.sendFile(resolveView('private', 'mantenimiento.html'));
});

// Panel de compras e insumos - SOLO compras y administrador
app.get('/compras', requireAuthPage, requireRolePage(['compras', 'administrador']), (req, res) => {
  res.sendFile(resolveView('private', 'compras.html'));
});

// Página de historial de notificaciones
app.get('/notificaciones', requireAuthPage, (req, res) => {
  res.sendFile(resolveView('private', 'notificaciones.html'));
});

// ============================================
// API DE NOTIFICACIONES
// ============================================

// Mapeo de rol a departamento para notificaciones
const ROLE_TO_NOTIFICATION_DEPARTMENT = {
  'rrhh': 'Recursos Humanos',
   'support': 'Sistemas',
  'mantenimiento': 'Mantenimiento',
  'compras': 'Compras e Insumos',
  'administrador': 'Administrador'
};

// Obtener notificaciones no leídas del departamento del usuario (últimas 5)
// El administrador NO recibe notificaciones de tickets de departamentos restringidos
app.get('/api/notifications/unread', authenticateToken, async (req, res) => {
  try {
    const userDepartment = ROLE_TO_NOTIFICATION_DEPARTMENT[req.user.role];

    if (!userDepartment) {
      return res.json([]);
    }

    let result;

    // Si es administrador, excluir notificaciones de tickets de departamentos restringidos
    if (req.user.role === 'administrador') {
      result = await pool.query(`
        SELECT n.id, n.ticket_id, n.department, n.title, n.message, n.ticket_tracking_id, 
               n.created_by_name, n.is_read, n.created_at
        FROM notifications n
        LEFT JOIN tickets t ON n.ticket_id = t.id
        WHERE n.department = $1 AND n.is_read = FALSE
          AND (t.department IS NULL OR t.department NOT IN ($2, $3))
        ORDER BY n.created_at DESC
        LIMIT 5
      `, [userDepartment, ...RESTRICTED_DEPARTMENTS]);
    } else {
      result = await pool.query(`
        SELECT id, ticket_id, department, title, message, ticket_tracking_id, 
               created_by_name, is_read, created_at
        FROM notifications 
        WHERE department = $1 AND is_read = FALSE
        ORDER BY created_at DESC
        LIMIT 5
      `, [userDepartment]);
    }

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching unread notifications:', error.message);
    res.status(500).json({ error: 'Error al obtener notificaciones' });
  }
});

// Obtener conteo de notificaciones no leídas
// El administrador NO cuenta notificaciones de tickets de departamentos restringidos
app.get('/api/notifications/count', authenticateToken, async (req, res) => {
  try {
    const userDepartment = ROLE_TO_NOTIFICATION_DEPARTMENT[req.user.role];

    if (!userDepartment) {
      return res.json({ count: 0 });
    }

    let result;

    // Si es administrador, excluir notificaciones de tickets de departamentos restringidos
    if (req.user.role === 'administrador') {
      result = await pool.query(`
        SELECT COUNT(*) as count
        FROM notifications n
        LEFT JOIN tickets t ON n.ticket_id = t.id
        WHERE n.department = $1 AND n.is_read = FALSE
          AND (t.department IS NULL OR t.department NOT IN ($2, $3))
      `, [userDepartment, ...RESTRICTED_DEPARTMENTS]);
    } else {
      result = await pool.query(`
        SELECT COUNT(*) as count
        FROM notifications 
        WHERE department = $1 AND is_read = FALSE
      `, [userDepartment]);
    }

    res.json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    console.error('Error fetching notification count:', error.message);
    res.status(500).json({ error: 'Error al obtener conteo de notificaciones' });
  }
});

// Obtener historial completo de notificaciones (paginado)
// El administrador NO ve notificaciones de tickets de departamentos restringidos
app.get('/api/notifications/history', authenticateToken, async (req, res) => {
  try {
    const userDepartment = ROLE_TO_NOTIFICATION_DEPARTMENT[req.user.role];
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    if (!userDepartment) {
      return res.json({ notifications: [], total: 0, page, totalPages: 0 });
    }

    let countResult, result;

    // Si es administrador, excluir notificaciones de tickets de departamentos restringidos
    if (req.user.role === 'administrador') {
      // Obtener total de notificaciones (excluyendo restringidas)
      countResult = await pool.query(`
        SELECT COUNT(*) as total
        FROM notifications n
        LEFT JOIN tickets t ON n.ticket_id = t.id
        WHERE n.department = $1
          AND (t.department IS NULL OR t.department NOT IN ($2, $3))
      `, [userDepartment, ...RESTRICTED_DEPARTMENTS]);

      // Obtener notificaciones paginadas (excluyendo restringidas)
      result = await pool.query(`
        SELECT n.id, n.ticket_id, n.department, n.title, n.message, n.ticket_tracking_id, 
               n.created_by_name, n.is_read, n.read_at, n.created_at,
               u.name as read_by_name
        FROM notifications n
        LEFT JOIN users u ON n.read_by = u.id
        LEFT JOIN tickets t ON n.ticket_id = t.id
        WHERE n.department = $1
          AND (t.department IS NULL OR t.department NOT IN ($2, $3))
        ORDER BY n.created_at DESC
        LIMIT $4 OFFSET $5
      `, [userDepartment, ...RESTRICTED_DEPARTMENTS, limit, offset]);
    } else {
      // Obtener total de notificaciones
      countResult = await pool.query(`
        SELECT COUNT(*) as total
        FROM notifications 
        WHERE department = $1
      `, [userDepartment]);

      // Obtener notificaciones paginadas
      result = await pool.query(`
        SELECT n.id, n.ticket_id, n.department, n.title, n.message, n.ticket_tracking_id, 
               n.created_by_name, n.is_read, n.read_at, n.created_at,
               u.name as read_by_name
        FROM notifications n
        LEFT JOIN users u ON n.read_by = u.id
        WHERE n.department = $1
        ORDER BY n.created_at DESC
        LIMIT $2 OFFSET $3
      `, [userDepartment, limit, offset]);
    }

    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / limit);

    res.json({
      notifications: result.rows,
      total,
      page,
      totalPages
    });
  } catch (error) {
    console.error('Error fetching notification history:', error.message);
    res.status(500).json({ error: 'Error al obtener historial de notificaciones' });
  }
});

// Marcar notificación como leída
app.put('/api/notifications/:id/read', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userDepartment = ROLE_TO_NOTIFICATION_DEPARTMENT[req.user.role];

    // Verificar que la notificación pertenece al departamento del usuario
    const checkResult = await pool.query(`
      SELECT id FROM notifications WHERE id = $1 AND department = $2
    `, [id, userDepartment]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Notificación no encontrada' });
    }

    await pool.query(`
      UPDATE notifications 
      SET is_read = TRUE, read_by = $1, read_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [req.user.id, id]);

    res.json({ message: 'Notificación marcada como leída' });
  } catch (error) {
    console.error('Error marking notification as read:', error.message);
    res.status(500).json({ error: 'Error al marcar notificación como leída' });
  }
});

// Marcar todas las notificaciones como leídas
app.put('/api/notifications/read-all', authenticateToken, async (req, res) => {
  try {
    const userDepartment = ROLE_TO_NOTIFICATION_DEPARTMENT[req.user.role];

    if (!userDepartment) {
      return res.json({ message: 'No hay notificaciones que marcar' });
    }

    await pool.query(`
      UPDATE notifications 
      SET is_read = TRUE, read_by = $1, read_at = CURRENT_TIMESTAMP
      WHERE department = $2 AND is_read = FALSE
    `, [req.user.id, userDepartment]);

    res.json({ message: 'Todas las notificaciones marcadas como leídas' });
  } catch (error) {
    console.error('Error marking all notifications as read:', error.message);
    res.status(500).json({ error: 'Error al marcar notificaciones como leídas' });
  }
});

// ============================================
// PUSH NOTIFICATIONS API
// ============================================

// Obtener clave pública VAPID
app.get('/api/push/vapid-key', (req, res) => {
  res.json({ publicKey: process.env.VAPID_PUBLIC_KEY || '' });
});

// Suscribir a notificaciones push
app.post('/api/push/subscribe', authenticateToken, async (req, res) => {
  try {
    const { subscription, preferences } = req.body;
    const userId = req.user.id;
    const department = ROLE_TO_NOTIFICATION_DEPARTMENT[req.user.role];

    if (!subscription || !subscription.endpoint) {
      return res.status(400).json({ error: 'Suscripción inválida' });
    }

    // Insertar o actualizar suscripción
    await pool.query(`
      INSERT INTO push_subscriptions (user_id, endpoint, keys_p256dh, keys_auth, department, preferences)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (endpoint) DO UPDATE SET
        user_id = $1,
        keys_p256dh = $3,
        keys_auth = $4,
        department = $5,
        preferences = $6,
        last_used = CURRENT_TIMESTAMP
    `, [
      userId,
      subscription.endpoint,
      subscription.keys.p256dh,
      subscription.keys.auth,
      department,
      JSON.stringify(preferences || {})
    ]);


    res.json({ success: true, message: 'Suscripción guardada' });
  } catch (error) {
    console.error('Error saving push subscription:', error.message);
    res.status(500).json({ error: 'Error al guardar suscripción' });
  }
});

// Desuscribir de notificaciones push
app.post('/api/push/unsubscribe', authenticateToken, async (req, res) => {
  try {
    const { endpoint } = req.body;

    await pool.query('DELETE FROM push_subscriptions WHERE endpoint = $1', [endpoint]);


    res.json({ success: true, message: 'Suscripción eliminada' });
  } catch (error) {
    console.error('Error removing push subscription:', error.message);
    res.status(500).json({ error: 'Error al eliminar suscripción' });
  }
});

// Actualizar preferencias de push
app.put('/api/push/preferences', authenticateToken, async (req, res) => {
  try {
    const { endpoint, preferences } = req.body;

    await pool.query(`
      UPDATE push_subscriptions 
      SET preferences = $1, last_used = CURRENT_TIMESTAMP
      WHERE endpoint = $2
    `, [JSON.stringify(preferences), endpoint]);

    res.json({ success: true, message: 'Preferencias actualizadas' });
  } catch (error) {
    console.error('Error updating push preferences:', error.message);
    res.status(500).json({ error: 'Error al actualizar preferencias' });
  }
});

// Enviar notificación de prueba
app.post('/api/push/test', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    // Buscar suscripción del usuario
    const result = await pool.query(
      'SELECT * FROM push_subscriptions WHERE user_id = $1 LIMIT 1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'No hay suscripción activa' });
    }

    const sub = result.rows[0];
    const pushSubscription = {
      endpoint: sub.endpoint,
      keys: {
        p256dh: sub.keys_p256dh,
        auth: sub.keys_auth
      }
    };

    const payload = JSON.stringify({
      title: '🔔 Notificación de prueba',
      body: 'Las notificaciones push están funcionando correctamente.',
      icon: '/img/logo-icon.svg',
      badge: '/img/badge-icon.svg',
      tag: 'test-notification',
      timestamp: Date.now(),
      data: { url: '/' }
    });

    await webpush.sendNotification(pushSubscription, payload);

    res.json({ success: true, message: 'Notificación de prueba enviada' });
  } catch (error) {
    console.error('Error sending test push:', error.message);

    // Si la suscripción ya no es válida, eliminarla
    if (error.statusCode === 410) {
      await pool.query('DELETE FROM push_subscriptions WHERE user_id = $1', [req.user.id]);
      return res.status(410).json({ error: 'Suscripción expirada, por favor vuelve a suscribirte' });
    }

    res.status(500).json({ error: 'Error al enviar notificación de prueba' });
  }
});

// Registrar métricas de push
app.post('/api/push/metrics', async (req, res) => {
  try {
    const { notificationId, action, timestamp } = req.body;

    await pool.query(`
      INSERT INTO push_metrics (notification_id, action, created_at)
      VALUES ($1, $2, to_timestamp($3 / 1000.0))
    `, [notificationId, action, timestamp]);

    res.json({ success: true });
  } catch (error) {
    console.error('Error recording push metric:', error.message);
    res.status(500).json({ error: 'Error al registrar métrica' });
  }
});

// Obtener métricas de push (solo admin)
app.get('/api/push/metrics', authenticateToken, isAdmin, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN delivered THEN 1 END) as delivered,
        COUNT(CASE WHEN clicked THEN 1 END) as clicked,
        COUNT(CASE WHEN closed THEN 1 END) as closed
      FROM push_metrics
      WHERE created_at > NOW() - INTERVAL '7 days'
    `);

    const subscriptions = await pool.query('SELECT COUNT(*) as count FROM push_subscriptions');

    res.json({
      metrics: result.rows[0],
      activeSubscriptions: parseInt(subscriptions.rows[0].count)
    });
  } catch (error) {
    console.error('Error fetching push metrics:', error.message);
    res.status(500).json({ error: 'Error al obtener métricas' });
  }
});

// ============================================
// REPORTS API ENDPOINTS
// ============================================

// Caché en memoria para reportes (TTL: 5 minutos)
const reportCache = new Map();
const REPORT_CACHE_TTL = 5 * 60 * 1000; // 5 minutos

// Helper para obtener/establecer caché
function getCachedReport(key) {
  const cached = reportCache.get(key);
  if (cached && Date.now() < cached.expiresAt) {
    return cached.data;
  }
  reportCache.delete(key);
  return null;
}

function setCachedReport(key, data) {
  reportCache.set(key, {
    data,
    expiresAt: Date.now() + REPORT_CACHE_TTL
  });
}

// Invalidar caché de reportes
function invalidateReportCache() {
  reportCache.clear();
}

// Helper para parsear período
function getPeriodDays(period) {
  const periods = {
    '1d': 1,
    '7d': 7,
    '30d': 30,
    '90d': 90,
    '180d': 180,
    '365d': 365
  };
  return periods[period] || 30;
}

// Helper para registrar auditoría
async function logAudit(userId, action, resource, parameters, ipAddress) {
  try {
    await pool.query(
      `INSERT INTO audit_log (user_id, action, resource, parameters, ip_address) VALUES ($1, $2, $3, $4, $5)`,
      [userId, action, resource, parameters ? JSON.stringify(parameters) : null, ipAddress]
    );
  } catch (error) {
    console.error('Error logging audit:', error.message);
  }
}

// GET /api/reports/stats - Estadísticas generales
app.get('/api/reports/stats', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    const { period = '30d', department = 'all' } = req.query;
    const days = getPeriodDays(period);

    const cacheKey = `stats:${period}:${department}`;
    const cached = getCachedReport(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    let whereClause = `WHERE created_at >= NOW() - INTERVAL '${days} days'`;
    const params = [];

    if (department !== 'all') {
      params.push(department);
      whereClause += ` AND department = $${params.length}`;
    }

    // Tickets totales, abiertos, cerrados, en progreso
    const statsQuery = `
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'open' THEN 1 END) as open,
        COUNT(CASE WHEN status = 'in-progress' THEN 1 END) as in_progress,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed,
        COUNT(CASE WHEN status != 'closed' AND assigned_to IS NULL THEN 1 END) as unassigned
      FROM tickets
      ${whereClause}
    `;

    const statsResult = await pool.query(statsQuery, params);

    // Tiempo promedio de resolución (tickets cerrados)
    let avgTimeClause = whereClause.replace('created_at', 't.created_at');
    if (department !== 'all') {
      avgTimeClause = avgTimeClause.replace('department', 't.department');
    }

    const avgTimeQuery = `
      SELECT 
        COALESCE(AVG(EXTRACT(EPOCH FROM (t.updated_at - t.created_at)) / 3600), 0) as avg_resolution_hours
      FROM tickets t
      ${avgTimeClause} AND t.status = 'closed'
    `;

    const avgTimeResult = await pool.query(avgTimeQuery, params);

    // Estadísticas del período anterior para comparación
    const prevWhereClause = whereClause
      .replace(`NOW() - INTERVAL '${days} days'`, `NOW() - INTERVAL '${days * 2} days'`)
      + ` AND created_at < NOW() - INTERVAL '${days} days'`;

    const prevStatsQuery = `
      SELECT COUNT(*) as total
      FROM tickets
      ${prevWhereClause}
    `;

    const prevStatsResult = await pool.query(prevStatsQuery, params);

    const stats = statsResult.rows[0];
    const prevTotal = parseInt(prevStatsResult.rows[0]?.total || 0);
    const currentTotal = parseInt(stats.total || 0);

    const changePercent = prevTotal > 0
      ? ((currentTotal - prevTotal) / prevTotal * 100).toFixed(1)
      : 0;

    const result = {
      total: parseInt(stats.total || 0),
      open: parseInt(stats.open || 0),
      inProgress: parseInt(stats.in_progress || 0),
      closed: parseInt(stats.closed || 0),
      unassigned: parseInt(stats.unassigned || 0),
      pending: parseInt(stats.open || 0) + parseInt(stats.in_progress || 0),
      avgResolutionHours: parseFloat(avgTimeResult.rows[0]?.avg_resolution_hours || 0).toFixed(1),
      resolutionRate: currentTotal > 0
        ? ((parseInt(stats.closed || 0) / currentTotal) * 100).toFixed(1)
        : 0,
      changePercent: parseFloat(changePercent),
      period: period,
      department: department
    };

    setCachedReport(cacheKey, result);

    // Registrar auditoría
    await logAudit(req.user.id, 'view_report', '/api/reports/stats', { period, department }, req.ip);

    res.json(result);
  } catch (error) {
    console.error('Error fetching report stats:', error.message);
    res.status(500).json({ error: 'Error al obtener estadísticas' });
  }
});

// GET /api/reports/trends - Datos para gráficos de tendencias
app.get('/api/reports/trends', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    const { period = '30d', department = 'all' } = req.query;
    const days = getPeriodDays(period);

    const cacheKey = `trends:${period}:${department}`;
    const cached = getCachedReport(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    let whereClause = `WHERE created_at >= NOW() - INTERVAL '${days} days'`;
    const params = [];

    if (department !== 'all') {
      params.push(department);
      whereClause += ` AND department = $${params.length}`;
    }

    // Agrupar por día o por semana según el período
    const groupBy = days <= 30 ? 'day' : 'week';
    const dateFormat = groupBy === 'day' ? 'YYYY-MM-DD' : 'IYYY-IW';

    const trendsQuery = `
      SELECT 
        TO_CHAR(created_at, '${dateFormat}') as date_group,
        DATE(created_at) as date,
        COUNT(*) as created,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed,
        COUNT(CASE WHEN status IN ('open', 'in-progress') THEN 1 END) as pending
      FROM tickets
      ${whereClause}
      GROUP BY date_group, DATE(created_at)
      ORDER BY date ASC
    `;

    const trendsResult = await pool.query(trendsQuery, params);

    const result = trendsResult.rows.map(row => ({
      date: row.date,
      created: parseInt(row.created || 0),
      closed: parseInt(row.closed || 0),
      pending: parseInt(row.pending || 0)
    }));

    setCachedReport(cacheKey, result);

    await logAudit(req.user.id, 'view_report', '/api/reports/trends', { period, department }, req.ip);

    res.json(result);
  } catch (error) {
    console.error('Error fetching report trends:', error.message);
    res.status(500).json({ error: 'Error al obtener tendencias' });
  }
});

// GET /api/reports/by-department - Métricas por departamento
app.get('/api/reports/by-department', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    const days = getPeriodDays(period);

    // Determinar alcance de departamento efectivo
    let department = 'all';
    if (req.user.role === 'mantenimiento') {
      department = 'Mantenimiento';
    } else if (req.user.role === 'support') {
      department = 'Sistemas';
    } else if (req.user.role === 'rrhh') {
      department = 'RRHH';
    } else if (req.user.role === 'compras') {
      department = 'Compras';
    } else if (req.query.department && req.query.department !== 'all') {
      department = req.query.department;
    }

    const userScope = req.user.role === 'mantenimiento' ? 'mantenimiento' : (req.user.role === 'support' ? 'sistemas' : (req.user.role === 'rrhh' ? 'rrhh' : (req.user.role === 'compras' ? 'compras' : 'admin')));
    const cacheKey = `by-department:${period}:${userScope}:${department}`;
    const cached = getCachedReport(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    let deptWhere = `WHERE created_at >= NOW() - INTERVAL '${days} days' AND department IS NOT NULL`;
    const params = [];
    if (department !== 'all') {
      params.push(department);
      deptWhere += ` AND department = $${params.length}`;
    }

    const deptQuery = `
      SELECT 
        department,
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'open' THEN 1 END) as open,
        COUNT(CASE WHEN status = 'in-progress' THEN 1 END) as in_progress,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed,
        COALESCE(AVG(CASE WHEN status = 'closed' 
          THEN EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600 END), 0) as avg_resolution_hours
      FROM tickets
      ${deptWhere}
      GROUP BY department
      ORDER BY total DESC
    `;

    const deptResult = await pool.query(deptQuery, params);

    const result = deptResult.rows.map(row => ({
      department: row.department,
      total: parseInt(row.total || 0),
      open: parseInt(row.open || 0),
      inProgress: parseInt(row.in_progress || 0),
      closed: parseInt(row.closed || 0),
      avgResolutionHours: parseFloat(row.avg_resolution_hours || 0).toFixed(1),
      resolutionRate: parseInt(row.total) > 0
        ? ((parseInt(row.closed) / parseInt(row.total)) * 100).toFixed(1)
        : 0
    }));

    setCachedReport(cacheKey, result);

    await logAudit(req.user.id, 'view_report', '/api/reports/by-department', { period, department }, req.ip);

    res.json(result);
  } catch (error) {
    console.error('Error fetching report by department:', error.message);
    res.status(500).json({ error: 'Error al obtener métricas por departamento' });
  }
});

// GET /api/reports/kpis - KPIs calculados
app.get('/api/reports/kpis', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    const { period = '30d', department = 'all' } = req.query;
    const days = getPeriodDays(period);

    const cacheKey = `kpis:${period}:${department}`;
    const cached = getCachedReport(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    let whereClause = `WHERE created_at >= NOW() - INTERVAL '${days} days'`;
    const params = [];

    if (department !== 'all') {
      params.push(department);
      whereClause += ` AND department = $${params.length}`;
    }

    // KPIs principales
    const kpiQuery = `
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed,
        COUNT(CASE WHEN priority = 'high' THEN 1 END) as high_priority,
        COUNT(CASE WHEN priority = 'high' AND status = 'closed' THEN 1 END) as high_priority_closed,
        COALESCE(AVG(CASE WHEN status = 'closed' 
          THEN EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600 END), 0) as avg_resolution_hours,
        COALESCE(AVG(CASE WHEN status IN ('open', 'in-progress') 
          THEN EXTRACT(EPOCH FROM (NOW() - created_at)) / 3600 END), 0) as avg_pending_hours
      FROM tickets
      ${whereClause}
    `;

    const kpiResult = await pool.query(kpiQuery, params);
    const kpi = kpiResult.rows[0];

    const total = parseInt(kpi.total || 0);
    const closed = parseInt(kpi.closed || 0);
    const highPriority = parseInt(kpi.high_priority || 0);
    const highPriorityClosed = parseInt(kpi.high_priority_closed || 0);

    const result = {
      resolutionRate: total > 0 ? ((closed / total) * 100).toFixed(1) : 0,
      avgResolutionHours: parseFloat(kpi.avg_resolution_hours || 0).toFixed(1),
      avgPendingHours: parseFloat(kpi.avg_pending_hours || 0).toFixed(1),
      highPriorityResolutionRate: highPriority > 0
        ? ((highPriorityClosed / highPriority) * 100).toFixed(1)
        : 0,
      totalReceived: total,
      totalClosed: closed,
      totalPending: total - closed,
      period: period,
      department: department
    };

    setCachedReport(cacheKey, result);

    await logAudit(req.user.id, 'view_report', '/api/reports/kpis', { period, department }, req.ip);

    res.json(result);
  } catch (error) {
    console.error('Error fetching report KPIs:', error.message);
    res.status(500).json({ error: 'Error al obtener KPIs' });
  }
});

// GET /api/reports/departments - Lista de departamentos disponibles
app.get('/api/reports/departments', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    if (req.user.role === 'mantenimiento') {
      return res.json(['Mantenimiento']);
    }
    if (req.user.role === 'support') {
      return res.json(['Sistemas']);
    }
    if (req.user.role === 'rrhh') {
      return res.json(['RRHH']);
    }
    if (req.user.role === 'compras') {
      return res.json(['Compras']);
    }

    const deptQuery = `
      SELECT DISTINCT department 
      FROM tickets 
      WHERE department IS NOT NULL 
      ORDER BY department
    `;
    const result = await pool.query(deptQuery);
    res.json(result.rows.map(r => r.department));
  } catch (error) {
    console.error('Error fetching departments:', error.message);
    res.status(500).json({ error: 'Error al obtener departamentos' });
  }
});

// ============================================
// REPORTES COMPARTIBLES (ENLACES PÚBLICOS)
// ============================================

// POST /api/reports/share - Crear nuevo enlace público de reporte
app.post('/api/reports/share', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    const { title, period = '7d', expireInDays = 7 } = req.body;
    let department = req.body.department || 'all';

    if (req.user.role === 'mantenimiento') {
      department = 'Mantenimiento';
    } else if (req.user.role === 'support') {
      department = 'Sistemas';
    } else if (req.user.role === 'rrhh') {
      department = 'RRHH';
    } else if (req.user.role === 'compras') {
      department = 'Compras';
    }

    const token = crypto.randomBytes(24).toString('hex');
    const defaultTitle = req.user.role === 'mantenimiento'
      ? `Reporte de Mantenimiento (${period === '7d' ? 'Semanal' : period}) - Imagen Diagnóstica`
      : (req.user.role === 'support'
          ? `Reporte de Soporte Técnico (${period === '7d' ? 'Semanal' : period}) - Imagen Diagnóstica`
          : (req.user.role === 'rrhh'
              ? `Reporte de Recursos Humanos (${period === '7d' ? 'Semanal' : period}) - Imagen Diagnóstica`
              : (req.user.role === 'compras'
                  ? `Reporte de Compras (${period === '7d' ? 'Semanal' : period}) - Imagen Diagnóstica`
                  : (department !== 'all'
                      ? `Reporte de ${department} (${period === '7d' ? 'Semanal' : period}) - Imagen Diagnóstica`
                      : `Reporte ${period === '7d' ? 'Semanal' : period} - Imagen Diagnóstica`))));

    const reportTitle = (title && typeof title === 'string' && title.trim())
      ? title.trim()
      : defaultTitle;

    let expiresAt = null;
    const daysNum = parseInt(expireInDays, 10);
    if (!isNaN(daysNum) && daysNum > 0) {
      expiresAt = new Date(Date.now() + daysNum * 24 * 60 * 60 * 1000);
    }

    const query = `
      INSERT INTO shared_reports (token, title, period, department, created_by, expires_at, is_active)
      VALUES ($1, $2, $3, $4, $5, $6, TRUE)
      RETURNING *
    `;

    const result = await pool.query(query, [
      token,
      reportTitle,
      period,
      department,
      req.user.id,
      expiresAt
    ]);

    const sharedReport = result.rows[0];
    const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
    const shareUrl = `${baseUrl}/reportes/publico/${token}`;

    // Registrar auditoría
    await logAudit(req.user.id, 'create_shared_report', '/api/reports/share', { token, period, department }, req.ip);

    res.status(201).json({
      success: true,
      message: 'Enlace público generado con éxito',
      token,
      url: shareUrl,
      report: sharedReport
    });
  } catch (error) {
    console.error('Error al crear reporte compartido:', error.message);
    res.status(500).json({ error: 'Error al generar enlace público del reporte' });
  }
});

// GET /api/reports/share - Listar enlaces públicos creados
app.get('/api/reports/share', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    let query = `
      SELECT sr.*, u.name as created_by_name
      FROM shared_reports sr
      LEFT JOIN users u ON sr.created_by = u.id
      WHERE sr.is_active = TRUE
    `;
    const params = [];

    if (req.user.role === 'mantenimiento') {
      query += ` AND (sr.department = 'Mantenimiento' OR sr.created_by = $1)`;
      params.push(req.user.id);
    } else if (req.user.role === 'support') {
      query += ` AND (sr.department = 'Sistemas' OR sr.created_by = $1)`;
      params.push(req.user.id);
    } else if (req.user.role === 'rrhh') {
      query += ` AND (sr.department = 'RRHH' OR sr.created_by = $1)`;
      params.push(req.user.id);
    } else if (req.user.role === 'compras') {
      query += ` AND (sr.department = 'Compras' OR sr.created_by = $1)`;
      params.push(req.user.id);
    }

    query += ` ORDER BY sr.created_at DESC`;

    const result = await pool.query(query, params);

    const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
    const reports = result.rows.map(r => ({
      ...r,
      url: `${baseUrl}/reportes/publico/${r.token}`,
      isExpired: r.expires_at ? new Date(r.expires_at) < new Date() : false
    }));

    res.json(reports);
  } catch (error) {
    console.error('Error al listar reportes compartidos:', error.message);
    res.status(500).json({ error: 'Error al obtener enlaces compartidos' });
  }
});

// DELETE /api/reports/share/:token - Eliminar enlace público
app.delete('/api/reports/share/:token', authenticateToken, isAuthorizedForReports, async (req, res) => {
  try {
    const { token } = req.params;
    let query = `DELETE FROM shared_reports WHERE token = $1`;
    const params = [token];

    if (req.user.role === 'mantenimiento') {
      query += ` AND (department = 'Mantenimiento' OR created_by = $2)`;
      params.push(req.user.id);
    } else if (req.user.role === 'support') {
      query += ` AND (department = 'Sistemas' OR created_by = $2)`;
      params.push(req.user.id);
    } else if (req.user.role === 'rrhh') {
      query += ` AND (department = 'RRHH' OR created_by = $2)`;
      params.push(req.user.id);
    } else if (req.user.role === 'compras') {
      query += ` AND (department = 'Compras' OR created_by = $2)`;
      params.push(req.user.id);
    }

    query += ` RETURNING id`;

    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Enlace no encontrado o no tiene permisos para eliminarlo' });
    }

    await logAudit(req.user.id, 'delete_shared_report', `/api/reports/share/${token}`, null, req.ip);

    res.json({ success: true, message: 'Enlace público eliminado exitosamente' });
  } catch (error) {
    console.error('Error al eliminar reporte compartido:', error.message);
    res.status(500).json({ error: 'Error al eliminar enlace' });
  }
});

// GET /reportes/publico/:token - Vista pública HTML del reporte
app.get('/reportes/publico/:token', (req, res) => {
  res.sendFile(resolveView('public', 'reporte-publico.html'));
});

// GET /api/reports/public/:token - Datos para la vista pública (sin autenticación requerida)
app.get('/api/reports/public/:token', async (req, res) => {
  try {
    const { token } = req.params;
    const checkResult = await pool.query(`
      SELECT sr.*, u.name as created_by_name
      FROM shared_reports sr
      LEFT JOIN users u ON sr.created_by = u.id
      WHERE sr.token = $1
    `, [token]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'El enlace de reporte no existe o es inválido' });
    }

    const reportConfig = checkResult.rows[0];

    if (!reportConfig.is_active) {
      return res.status(410).json({ error: 'Este enlace de reporte ha sido revocado o desactivado' });
    }

    if (reportConfig.expires_at && new Date(reportConfig.expires_at) < new Date()) {
      return res.status(410).json({ error: 'Este enlace de reporte ha expirado' });
    }

    // Incrementar contador de visitas de forma atómica
    await pool.query(`
      UPDATE shared_reports 
      SET views_count = views_count + 1, last_viewed_at = NOW() 
      WHERE id = $1
    `, [reportConfig.id]);

    const period = reportConfig.period || '7d';
    const department = reportConfig.department || 'all';
    const days = getPeriodDays(period);

    // 1. Stats
    let whereClause = `WHERE created_at >= NOW() - INTERVAL '${days} days'`;
    const params = [];
    if (department !== 'all') {
      params.push(department);
      whereClause += ` AND department = $${params.length}`;
    }

    const statsQuery = `
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'open' THEN 1 END) as open,
        COUNT(CASE WHEN status = 'in-progress' THEN 1 END) as in_progress,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed,
        COUNT(CASE WHEN status != 'closed' AND assigned_to IS NULL THEN 1 END) as unassigned
      FROM tickets
      ${whereClause}
    `;
    const statsResult = await pool.query(statsQuery, params);

    let avgTimeClause = whereClause.replace('created_at', 't.created_at');
    if (department !== 'all') {
      avgTimeClause = avgTimeClause.replace('department', 't.department');
    }
    const avgTimeQuery = `
      SELECT 
        COALESCE(AVG(EXTRACT(EPOCH FROM (t.updated_at - t.created_at)) / 3600), 0) as avg_resolution_hours
      FROM tickets t
      ${avgTimeClause} AND t.status = 'closed'
    `;
    const avgTimeResult = await pool.query(avgTimeQuery, params);

    const prevWhereClause = whereClause
      .replace(`NOW() - INTERVAL '${days} days'`, `NOW() - INTERVAL '${days * 2} days'`)
      + ` AND created_at < NOW() - INTERVAL '${days} days'`;
    const prevStatsResult = await pool.query(`SELECT COUNT(*) as total FROM tickets ${prevWhereClause}`, params);

    const stats = statsResult.rows[0];
    const prevTotal = parseInt(prevStatsResult.rows[0]?.total || 0, 10);
    const currentTotal = parseInt(stats.total || 0, 10);
    const changePercent = prevTotal > 0 ? ((currentTotal - prevTotal) / prevTotal * 100).toFixed(1) : 0;

    const statsData = {
      total: currentTotal,
      open: parseInt(stats.open || 0, 10),
      inProgress: parseInt(stats.in_progress || 0, 10),
      closed: parseInt(stats.closed || 0, 10),
      unassigned: parseInt(stats.unassigned || 0, 10),
      pending: parseInt(stats.open || 0, 10) + parseInt(stats.in_progress || 0, 10),
      avgResolutionHours: parseFloat(avgTimeResult.rows[0]?.avg_resolution_hours || 0).toFixed(1),
      resolutionRate: currentTotal > 0 ? ((parseInt(stats.closed || 0, 10) / currentTotal) * 100).toFixed(1) : 0,
      changePercent: parseFloat(changePercent),
      period,
      department
    };

    // 2. Trends
    const groupBy = days <= 30 ? 'day' : 'week';
    const dateFormat = groupBy === 'day' ? 'YYYY-MM-DD' : 'IYYY-IW';
    const trendsQuery = `
      SELECT 
        TO_CHAR(created_at, '${dateFormat}') as date_group,
        DATE(created_at) as date,
        COUNT(*) as created,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed,
        COUNT(CASE WHEN status IN ('open', 'in-progress') THEN 1 END) as pending
      FROM tickets
      ${whereClause}
      GROUP BY date_group, DATE(created_at)
      ORDER BY date ASC
    `;
    const trendsResult = await pool.query(trendsQuery, params);
    const trendsData = trendsResult.rows.map(row => ({
      date: row.date,
      created: parseInt(row.created || 0, 10),
      closed: parseInt(row.closed || 0, 10),
      pending: parseInt(row.pending || 0, 10)
    }));

    // 3. By Department
    let pubDeptWhere = `WHERE created_at >= NOW() - INTERVAL '${days} days' AND department IS NOT NULL`;
    const pubDeptParams = [];
    if (department !== 'all') {
      pubDeptParams.push(department);
      pubDeptWhere += ` AND department = $${pubDeptParams.length}`;
    }

    const deptQuery = `
      SELECT 
        department,
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'open' THEN 1 END) as open,
        COUNT(CASE WHEN status = 'in-progress' THEN 1 END) as in_progress,
        COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed,
        COALESCE(AVG(CASE WHEN status = 'closed' 
          THEN EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600 END), 0) as avg_resolution_hours
      FROM tickets
      ${pubDeptWhere}
      GROUP BY department
      ORDER BY total DESC
    `;
    const deptResult = await pool.query(deptQuery, pubDeptParams);
    const byDepartmentData = deptResult.rows.map(row => ({
      department: row.department,
      total: parseInt(row.total || 0, 10),
      open: parseInt(row.open || 0, 10),
      inProgress: parseInt(row.in_progress || 0, 10),
      closed: parseInt(row.closed || 0, 10),
      avgResolutionHours: parseFloat(row.avg_resolution_hours || 0).toFixed(1),
      resolutionRate: parseInt(row.total, 10) > 0 ? ((parseInt(row.closed, 10) / parseInt(row.total, 10)) * 100).toFixed(1) : 0
    }));

    res.json({
      success: true,
      reportInfo: {
        title: reportConfig.title,
        period: reportConfig.period,
        department: reportConfig.department,
        createdBy: reportConfig.created_by_name || 'Dirección',
        createdAt: reportConfig.created_at,
        expiresAt: reportConfig.expires_at,
        viewsCount: reportConfig.views_count + 1
      },
      data: {
        stats: statsData,
        trends: trendsData,
        byDepartment: byDepartmentData
      }
    });
  } catch (error) {
    console.error('Error al obtener datos del reporte público:', error.message);
    res.status(500).json({ error: 'Error al cargar datos del reporte público' });
  }
});

// Función helper para enviar push a un departamento
async function sendPushToDepartment(department, notification, priority = 'normal') {
  try {
    // Obtener todas las suscripciones del departamento
    const result = await pool.query(`
      SELECT * FROM push_subscriptions 
      WHERE department = $1
    `, [department]);

    if (result.rows.length === 0) return;

    const payload = JSON.stringify({
      title: notification.title,
      body: notification.message,
      icon: '/img/logo-icon.svg',
      badge: '/img/badge-icon.svg',
      tag: `ticket-${notification.ticketId}`,
      ticketId: notification.ticketId,
      trackingId: notification.trackingId,
      department: department,
      notificationId: notification.id,
      priority: priority,
      timestamp: Date.now(),
      url: `/${department.toLowerCase().replace(/\s+/g, '')}`,
      actions: [
        { action: 'view', title: '📋 Ver ticket' },
        { action: 'dismiss', title: '❌ Cerrar' }
      ]
    });

    // Enviar a todas las suscripciones
    const sendPromises = result.rows.map(async (sub) => {
      // Verificar preferencias
      const prefs = sub.preferences || {};
      if (prefs.urgentOnly && priority !== 'high') return;
      if (!prefs.newTickets) return;

      const pushSubscription = {
        endpoint: sub.endpoint,
        keys: {
          p256dh: sub.keys_p256dh,
          auth: sub.keys_auth
        }
      };

      try {
        await webpush.sendNotification(pushSubscription, payload);

        // Registrar entrega exitosa
        await pool.query(`
          INSERT INTO push_metrics (notification_id, subscription_id, action, delivered)
          VALUES ($1, $2, 'delivered', TRUE)
        `, [notification.id, sub.id]);

      } catch (err) {
        console.error(`Error enviando push a ${sub.endpoint}:`, err.message);

        // Si la suscripción expiró, eliminarla
        if (err.statusCode === 410) {
          await pool.query('DELETE FROM push_subscriptions WHERE id = $1', [sub.id]);
        }

        // Registrar error
        await pool.query(`
          INSERT INTO push_metrics (notification_id, subscription_id, action, error)
          VALUES ($1, $2, 'error', $3)
        `, [notification.id, sub.id, err.message]);
      }
    });

    await Promise.allSettled(sendPromises);
    console.log(`📤 Push enviado a ${result.rows.length} suscriptores de ${department}`);
  } catch (error) {
    console.error('Error sending push to department:', error.message);
  }
}

// ============================================
// WEBSOCKET - MANEJO DE CONEXIONES
// ============================================

// Helper para obtener el valor de una cookie de un string de cookies (para WebSockets)
function getCookieValue(cookieHeader, name) {
  if (!cookieHeader) return null;
  const pairs = cookieHeader.split(';');
  for (const pair of pairs) {
    const [key, value] = pair.split('=').map(c => c.trim());
    if (key === name) return decodeURIComponent(value);
  }
  return null;
}

io.on('connection', (socket) => {


  // Autenticar y unir al room del departamento
  socket.on('join_department', (data) => {
    try {
      let token = data?.token;

      // Fallback: si no viene en el payload (por ser cookie HttpOnly), buscar en handshake cookies
      if (!token && socket.handshake.headers.cookie) {
        token = getCookieValue(socket.handshake.headers.cookie, 'token');
      }

      if (!token) {
        socket.emit('error', { message: 'Token no proporcionado' });
        return;
      }

      jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
          socket.emit('error', { message: 'Token inválido' });
          return;
        }

        const department = ROLE_TO_NOTIFICATION_DEPARTMENT[user.role];

        if (department) {
          socket.join(`department:${department}`);
          socket.userData = { ...user, department };

  
          socket.emit('joined', { department, message: `Conectado a notificaciones de ${department}` });
        }
      });
    } catch (error) {
      console.error('Error en join_department:', error.message);
      socket.emit('error', { message: 'Error al unirse al departamento' });
    }
  });

  // Solicitar conteo actualizado de notificaciones
  socket.on('request_count', async () => {
    if (!socket.userData) return;

    try {
      const result = await pool.query(`
        SELECT COUNT(*) as count
        FROM notifications 
        WHERE department = $1 AND is_read = FALSE
      `, [socket.userData.department]);

      socket.emit('notification_count', { count: parseInt(result.rows[0].count) });
    } catch (error) {
      console.error('Error fetching notification count via socket:', error.message);
    }
  });

  socket.on('disconnect', () => {
  
  });
});

// ==============================================
// MÓDULO DE TAREAS DE MANTENIMIENTO Y CHECKLIST
// ==============================================

const isMaintenanceRole = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'No autenticado' });
  }
  if (['support', 'mantenimiento', 'administrador', 'gerencia'].includes(req.user.role)) {
    return next();
  }
  return res.status(403).json({ error: 'Acceso no autorizado al módulo de tareas' });
};

// GET /api/maintenance/tasks - Listar tareas con filtros
app.get('/api/maintenance/tasks', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const { status, priority, category, sede, is_recurring, search, assigned_to } = req.query;

    let targetDepartment = req.query.department;
    if (req.user.role === 'support') {
      targetDepartment = 'Sistemas';
    } else if (req.user.role === 'mantenimiento') {
      targetDepartment = 'Mantenimiento';
    }

    let query = `
      SELECT 
        mt.*,
        u_assign.name as assigned_to_name,
        u_create.name as created_by_name,
        u_comp.name as completed_by_name
      FROM maintenance_tasks mt
      LEFT JOIN users u_assign ON mt.assigned_to = u_assign.id
      LEFT JOIN users u_create ON mt.created_by = u_create.id
      LEFT JOIN users u_comp ON mt.completed_by = u_comp.id
      WHERE 1=1
    `;
    const params = [];

    if (targetDepartment && targetDepartment !== 'all' && targetDepartment !== 'Todas') {
      params.push(targetDepartment);
      query += ` AND (mt.department = $${params.length} OR (mt.department IS NULL AND $${params.length} = 'Mantenimiento'))`;
    }

    if (status) {
      params.push(status);
      query += ` AND mt.status = $${params.length}`;
    }

    if (priority) {
      params.push(priority);
      query += ` AND mt.priority = $${params.length}`;
    }

    if (category && category !== 'all' && category !== 'Todas') {
      params.push(category);
      query += ` AND mt.category = $${params.length}`;
    }

    if (sede && sede !== 'all' && sede !== 'Todas') {
      params.push(sede);
      query += ` AND mt.sede = $${params.length}`;
    }

    if (is_recurring !== undefined && is_recurring !== '') {
      params.push(is_recurring === 'true' || is_recurring === true);
      query += ` AND mt.is_recurring = $${params.length}`;
    }

    if (assigned_to) {
      params.push(parseInt(assigned_to, 10));
      query += ` AND mt.assigned_to = $${params.length}`;
    }

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      query += ` AND (mt.title ILIKE $${params.length} OR mt.description ILIKE $${params.length} OR mt.category ILIKE $${params.length})`;
    }

    query += ` ORDER BY CASE WHEN mt.status = 'completed' THEN 2 ELSE 1 END, mt.due_date ASC NULLS LAST, mt.created_at DESC`;

    const result = await pool.query(query, params);

    // Calcular métricas de checklist
    const tasks = result.rows.map(task => {
      const items = Array.isArray(task.checklist) ? task.checklist : [];
      const totalItems = items.length;
      const completedItems = items.filter(i => i && i.done).length;
      const progressPercent = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : (task.status === 'completed' ? 100 : 0);

      return {
        ...task,
        checklist: items,
        checklistMetrics: {
          total: totalItems,
          completed: completedItems,
          percent: progressPercent
        }
      };
    });

    res.json(tasks);
  } catch (error) {
    console.error('Error al listar tareas:', error.message);
    res.status(500).json({ error: 'Error al obtener tareas' });
  }
});

// GET /api/maintenance/tasks-stats - Estadísticas para tarjetas KPI
app.get('/api/maintenance/tasks-stats', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    let targetDepartment = req.query.department;
    if (req.user.role === 'support') {
      targetDepartment = 'Sistemas';
    } else if (req.user.role === 'mantenimiento') {
      targetDepartment = 'Mantenimiento';
    }

    let whereStats = 'WHERE 1=1';
    const statParams = [];
    if (targetDepartment && targetDepartment !== 'all' && targetDepartment !== 'Todas') {
      statParams.push(targetDepartment);
      whereStats += ` AND (department = $${statParams.length} OR (department IS NULL AND $${statParams.length} = 'Mantenimiento'))`;
    }

    const result = await pool.query(`
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN status = 'in-progress' THEN 1 END) as in_progress,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
        COUNT(CASE WHEN is_recurring = TRUE THEN 1 END) as recurring_count,
        COUNT(CASE WHEN priority IN ('high', 'urgent') AND status != 'completed' THEN 1 END) as urgent_count
      FROM maintenance_tasks
      ${whereStats}
    `, statParams);

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener estadísticas de tareas:', error.message);
    res.status(500).json({ error: 'Error al obtener estadísticas de tareas' });
  }
});

// Helper para normalizar fechas en hora local a las 12:00:00 evitando desfases de huso horario UTC
function parseLocalDate(dateInput) {
  if (!dateInput) return null;
  if (dateInput instanceof Date) {
    return new Date(dateInput.getFullYear(), dateInput.getMonth(), dateInput.getDate(), 12, 0, 0);
  }
  const str = String(dateInput).substring(0, 10);
  const parts = str.split('-');
  if (parts.length === 3) {
    return new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10), 12, 0, 0);
  }
  const fallback = new Date(dateInput);
  return isNaN(fallback.getTime()) ? null : new Date(fallback.getFullYear(), fallback.getMonth(), fallback.getDate(), 12, 0, 0);
}

// POST /api/maintenance/tasks - Crear nueva tarea
app.post('/api/maintenance/tasks', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const {
      title,
      description,
      priority = 'medium',
      category = 'General',
      sede = 'Todas',
      assigned_to = null,
      assigned_technician = null,
      due_date = null,
      is_recurring = false,
      recurrence_interval = 'none',
      checklist = []
    } = req.body;

    let department = req.body.department || 'Mantenimiento';
    if (req.user.role === 'support') {
      department = 'Sistemas';
    } else if (req.user.role === 'mantenimiento') {
      department = 'Mantenimiento';
    }

    if (!title || !title.trim()) {
      return res.status(400).json({ error: 'El título de la tarea es requerido' });
    }

    const formattedChecklist = Array.isArray(checklist)
      ? checklist.map((item, idx) => ({
          id: item.id || `chk_${Date.now()}_${idx}`,
          text: String(item.text || item).trim(),
          done: Boolean(item.done)
        })).filter(i => i.text.length > 0)
      : [];

    const result = await pool.query(`
      INSERT INTO maintenance_tasks (
        title, description, priority, category, department, sede, assigned_to, assigned_technician,
        status, due_date, is_recurring, recurrence_interval, checklist,
        created_by
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending', $9, $10, $11, $12, $13)
      RETURNING *
    `, [
      title.trim(),
      description ? description.trim() : null,
      priority,
      category,
      department,
      sede,
      assigned_to ? parseInt(assigned_to, 10) : null,
      assigned_technician ? String(assigned_technician).trim() : null,
      due_date ? parseLocalDate(due_date) : null,
      Boolean(is_recurring),
      recurrence_interval || 'none',
      JSON.stringify(formattedChecklist),
      req.user.id
    ]);

    const createdTask = result.rows[0];
    await logAudit(req.user.id, 'create_maintenance_task', `/api/maintenance/tasks/${createdTask.id}`, { title: createdTask.title }, req.ip);

    res.status(201).json(createdTask);
  } catch (error) {
    console.error('Error al crear tarea de mantenimiento:', error.message);
    res.status(500).json({ error: 'Error al crear la tarea de mantenimiento' });
  }
});

// PUT /api/maintenance/tasks/:id - Editar tarea existente
app.put('/api/maintenance/tasks/:id', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      priority,
      category,
      sede,
      assigned_to,
      assigned_technician,
      due_date,
      is_recurring,
      recurrence_interval,
      checklist,
      status
    } = req.body;

    const formattedChecklist = Array.isArray(checklist)
      ? checklist.map((item, idx) => ({
          id: item.id || `chk_${Date.now()}_${idx}`,
          text: String(item.text || item).trim(),
          done: Boolean(item.done),
          done_at: item.done_at || null,
          done_by: item.done_by || null
        })).filter(i => i.text.length > 0)
      : [];

    const result = await pool.query(`
      UPDATE maintenance_tasks
      SET 
        title = COALESCE($1, title),
        description = $2,
        priority = COALESCE($3, priority),
        category = COALESCE($4, category),
        sede = COALESCE($5, sede),
        assigned_to = $6,
        assigned_technician = $7,
        due_date = $8,
        is_recurring = COALESCE($9, is_recurring),
        recurrence_interval = COALESCE($10, recurrence_interval),
        checklist = $11,
        status = COALESCE($12, status),
        updated_at = NOW()
      WHERE id = $13
      RETURNING *
    `, [
      title ? title.trim() : null,
      description !== undefined ? (description ? description.trim() : null) : null,
      priority,
      category,
      sede,
      assigned_to ? parseInt(assigned_to, 10) : null,
      assigned_technician !== undefined ? (assigned_technician ? String(assigned_technician).trim() : null) : null,
      due_date ? parseLocalDate(due_date) : null,
      is_recurring !== undefined ? Boolean(is_recurring) : null,
      recurrence_interval,
      JSON.stringify(formattedChecklist),
      status,
      parseInt(id, 10)
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al actualizar tarea de mantenimiento:', error.message);
    res.status(500).json({ error: 'Error al actualizar la tarea' });
  }
});

// PATCH /api/maintenance/tasks/:id/checklist/:itemId - Tildar/destildar ítem del checklist
app.patch('/api/maintenance/tasks/:id/checklist/:itemId', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const { id, itemId } = req.params;
    const { done } = req.body;

    const taskResult = await pool.query('SELECT * FROM maintenance_tasks WHERE id = $1', [parseInt(id, 10)]);
    if (taskResult.rows.length === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }

    const task = taskResult.rows[0];
    const items = Array.isArray(task.checklist) ? task.checklist : [];
    
    const updatedItems = items.map(item => {
      if (String(item.id) === String(itemId)) {
        const isDone = done !== undefined ? Boolean(done) : !item.done;
        return {
          ...item,
          done: isDone,
          done_at: isDone ? new Date().toISOString() : null,
          done_by_name: isDone ? req.user.name || 'Personal Mantenimiento' : null
        };
      }
      return item;
    });

    const total = updatedItems.length;
    const completed = updatedItems.filter(i => i.done).length;
    const allDone = total > 0 && completed === total;

    // Si todos los ítems fueron tildados, sugerir o avanzar a en progreso/completada
    let newStatus = task.status;
    if (task.status === 'pending' && completed > 0) {
      newStatus = 'in-progress';
    }

    const updateRes = await pool.query(`
      UPDATE maintenance_tasks
      SET checklist = $1, status = $2, updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `, [JSON.stringify(updatedItems), newStatus, parseInt(id, 10)]);

    res.json({
      success: true,
      task: updateRes.rows[0],
      checklistMetrics: {
        total,
        completed,
        percent: total > 0 ? Math.round((completed / total) * 100) : 0,
        allDone
      }
    });
  } catch (error) {
    console.error('Error al actualizar ítem de checklist:', error.message);
    res.status(500).json({ error: 'Error al actualizar ítem del checklist' });
  }
});

// PATCH /api/maintenance/tasks/:id/status - Cambiar estado de tarea y manejar recurrencia
app.patch('/api/maintenance/tasks/:id/status', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['pending', 'in-progress', 'completed'].includes(status)) {
      return res.status(400).json({ error: 'Estado inválido' });
    }

    const taskResult = await pool.query('SELECT * FROM maintenance_tasks WHERE id = $1', [parseInt(id, 10)]);
    if (taskResult.rows.length === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }

    const currentTask = taskResult.rows[0];
    const isNowCompleted = status === 'completed';

    // 1. Siempre actualizar el estado de la tarea actual
    const updateResult = await pool.query(`
      UPDATE maintenance_tasks
      SET 
        status = $1,
        completed_at = $2,
        completed_by = $3,
        updated_at = NOW()
      WHERE id = $4
      RETURNING *
    `, [
      status,
      isNowCompleted ? new Date() : null,
      isNowCompleted ? req.user.id : null,
      parseInt(id, 10)
    ]);

    // 2. Si la tarea es recurrente y se marca como completada, se crea una NUEVA instancia futura
    // manteniendo la actual completada en su fecha para histórico y trackeo en el calendario
    if (isNowCompleted && currentTask.is_recurring && currentTask.recurrence_interval && currentTask.recurrence_interval !== 'none') {
      const today = parseLocalDate(new Date());
      // Fecha base del ciclo: respetamos la fecha programada de la tarea original
      const baseDueDate = currentTask.due_date ? parseLocalDate(currentTask.due_date) : today;
      let nextDueDate = new Date(baseDueDate);

      const recurrenceInterval = currentTask.recurrence_interval || 'weekly';

      if (typeof recurrenceInterval === 'string' && recurrenceInterval.startsWith('custom:')) {
        const days = recurrenceInterval.replace('custom:', '').split(',').map(n => parseInt(n.trim(), 10)).filter(n => !isNaN(n));

        if (days.length > 0) {
          const advanceCustomDays = (date, daysArr) => {
            const d = new Date(date);
            for (let offset = 1; offset <= 7; offset++) {
              const testDate = new Date(d);
              testDate.setDate(testDate.getDate() + offset);
              if (daysArr.includes(testDate.getDay())) {
                return testDate;
              }
            }
            d.setDate(d.getDate() + 7);
            return d;
          };

          if (baseDueDate < today) {
            // Si la tarea venció en el pasado o se salteó un día previo:
            // Programar para el día configurado más cercano (hoy si hoy es uno de los días, o el próximo día configurado)
            if (days.includes(today.getDay())) {
              nextDueDate = new Date(today);
            } else {
              nextDueDate = advanceCustomDays(today, days);
            }
          } else {
            // La tarea era para hoy o una fecha futura:
            // Avanzar al siguiente día del ciclo configurado (ej: Martes -> Jueves -> Martes)
            nextDueDate = advanceCustomDays(baseDueDate, days);
          }
        } else {
          nextDueDate.setDate(nextDueDate.getDate() + 7);
        }
      } else {
        // Intervalos estándar: daily, weekly, biweekly, monthly, quarterly, yearly
        const advanceStandardCycle = (date, interval) => {
          const d = new Date(date);
          switch (interval) {
            case 'daily':
              d.setDate(d.getDate() + 1);
              if (d.getDay() === 0) d.setDate(d.getDate() + 1);
              break;
            case 'weekly':
              d.setDate(d.getDate() + 7);
              break;
            case 'biweekly':
              d.setDate(d.getDate() + 14);
              break;
            case 'monthly':
              d.setMonth(d.getMonth() + 1);
              break;
            case 'quarterly':
              d.setMonth(d.getMonth() + 3);
              break;
            case 'yearly':
              d.setFullYear(d.getFullYear() + 1);
              break;
            default:
              d.setDate(d.getDate() + 7);
              break;
          }
          return d;
        };

        nextDueDate = advanceStandardCycle(nextDueDate, recurrenceInterval);
        let guardIterations = 0;
        while (nextDueDate < today && guardIterations < 100) {
          nextDueDate = advanceStandardCycle(nextDueDate, recurrenceInterval);
          guardIterations++;
        }
      }

      // Reiniciar checklist limpio para el nuevo ciclo
      const cleanChecklist = (Array.isArray(currentTask.checklist) ? currentTask.checklist : []).map(i => ({
        id: i.id || `chk_${Date.now()}_${Math.random().toString(36).substring(7)}`,
        text: i.text,
        done: false
      }));

      const nextTaskResult = await pool.query(`
        INSERT INTO maintenance_tasks (
          title, description, priority, category, department, sede, assigned_to, assigned_technician,
          status, due_date, is_recurring, recurrence_interval, checklist,
          created_by
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending', $9, true, $10, $11, $12)
        RETURNING *
      `, [
        currentTask.title,
        currentTask.description,
        currentTask.priority,
        currentTask.category,
        currentTask.department || 'Mantenimiento',
        currentTask.sede,
        currentTask.assigned_to,
        currentTask.assigned_technician,
        nextDueDate,
        currentTask.recurrence_interval,
        JSON.stringify(cleanChecklist),
        currentTask.created_by || req.user.id
      ]);

      return res.json({
        success: true,
        task: updateResult.rows[0],
        nextTask: nextTaskResult.rows[0],
        isRecurringCycleReset: true,
        nextDueDate: nextDueDate
      });
    }

    res.json({
      success: true,
      task: updateResult.rows[0],
      isRecurringCycleReset: false
    });
  } catch (error) {
    console.error('Error al cambiar estado de tarea:', error.message);
    res.status(500).json({ error: 'Error al cambiar estado de la tarea' });
  }
});

// DELETE /api/maintenance/tasks/:id - Eliminar tarea
app.delete('/api/maintenance/tasks/:id', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM maintenance_tasks WHERE id = $1 RETURNING id, title', [parseInt(id, 10)]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }

    await logAudit(req.user.id, 'delete_maintenance_task', `/api/maintenance/tasks/${id}`, { title: result.rows[0].title }, req.ip);

    res.json({ success: true, message: 'Tarea eliminada exitosamente' });
  } catch (error) {
    console.error('Error al eliminar tarea de mantenimiento:', error.message);
    res.status(500).json({ error: 'Error al eliminar tarea' });
  }
});

// ==============================================
// RUTAS DE COMPARTIR TABLERO DE TAREAS PÚBLICO
// ==============================================

// POST /api/maintenance/tasks/share - Crear nuevo enlace público de tablero de tareas
app.post('/api/maintenance/tasks/share', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const { title, expireInDays = 7 } = req.body;
    let department = req.body.department || 'all';

    if (req.user.role === 'mantenimiento') {
      department = 'Mantenimiento';
    } else if (req.user.role === 'support') {
      department = 'Sistemas';
    }

    const token = crypto.randomBytes(24).toString('hex');
    const defaultTitle = req.user.role === 'mantenimiento'
      ? `Tablero de Tareas y Mantenimiento - Imagen Diagnóstica`
      : (req.user.role === 'support'
          ? `Tablero de Tareas de Soporte Técnico - Imagen Diagnóstica`
          : (department !== 'all' ? `Tablero de Tareas de ${department} - Imagen Diagnóstica` : `Tablero General de Tareas - Imagen Diagnóstica`));

    const boardTitle = (title && typeof title === 'string' && title.trim())
      ? title.trim()
      : defaultTitle;

    let expiresAt = null;
    const daysNum = parseInt(expireInDays, 10);
    if (!isNaN(daysNum) && daysNum > 0) {
      expiresAt = new Date(Date.now() + daysNum * 24 * 60 * 60 * 1000);
    }

    const query = `
      INSERT INTO shared_tasks_boards (token, title, department, created_by, expires_at, is_active)
      VALUES ($1, $2, $3, $4, $5, TRUE)
      RETURNING *
    `;

    const result = await pool.query(query, [
      token,
      boardTitle,
      department,
      req.user.id,
      expiresAt
    ]);

    const sharedBoard = result.rows[0];
    const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
    const shareUrl = `${baseUrl}/tareas/publico/${token}`;

    await logAudit(req.user.id, 'create_shared_tasks_board', '/api/maintenance/tasks/share', { token, department }, req.ip);

    res.status(201).json({
      success: true,
      message: 'Enlace público del tablero generado con éxito',
      token,
      url: shareUrl,
      board: sharedBoard
    });
  } catch (error) {
    console.error('Error al crear tablero compartido:', error.message);
    res.status(500).json({ error: 'Error al generar enlace público del tablero' });
  }
});

// GET /api/maintenance/tasks/share - Listar enlaces públicos de tareas creados
app.get('/api/maintenance/tasks/share', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    let query = `
      SELECT stb.*, u.name as created_by_name
      FROM shared_tasks_boards stb
      LEFT JOIN users u ON stb.created_by = u.id
      WHERE stb.is_active = TRUE
    `;
    const params = [];

    if (req.user.role === 'mantenimiento') {
      query += ` AND (stb.department = 'Mantenimiento' OR stb.created_by = $1)`;
      params.push(req.user.id);
    } else if (req.user.role === 'support') {
      query += ` AND (stb.department = 'Sistemas' OR stb.created_by = $1)`;
      params.push(req.user.id);
    }

    query += ` ORDER BY stb.created_at DESC`;

    const result = await pool.query(query, params);

    const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
    const boards = result.rows.map(b => ({
      ...b,
      url: `${baseUrl}/tareas/publico/${b.token}`,
      isExpired: b.expires_at ? new Date(b.expires_at) < new Date() : false
    }));

    res.json(boards);
  } catch (error) {
    console.error('Error al listar tableros compartidos:', error.message);
    res.status(500).json({ error: 'Error al obtener enlaces compartidos del tablero' });
  }
});

// DELETE /api/maintenance/tasks/share/:token - Eliminar enlace público de tareas
app.delete('/api/maintenance/tasks/share/:token', authenticateToken, isMaintenanceRole, async (req, res) => {
  try {
    const { token } = req.params;
    let query = `DELETE FROM shared_tasks_boards WHERE token = $1`;
    const params = [token];

    if (req.user.role === 'mantenimiento') {
      query += ` AND (department = 'Mantenimiento' OR created_by = $2)`;
      params.push(req.user.id);
    } else if (req.user.role === 'support') {
      query += ` AND (department = 'Sistemas' OR created_by = $2)`;
      params.push(req.user.id);
    }

    query += ` RETURNING id`;
    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Enlace no encontrado o sin permisos para eliminarlo' });
    }

    await logAudit(req.user.id, 'delete_shared_tasks_board', `/api/maintenance/tasks/share/${token}`, null, req.ip);

    res.json({ success: true, message: 'Enlace público eliminado exitosamente' });
  } catch (error) {
    console.error('Error al eliminar enlace de tablero compartido:', error.message);
    res.status(500).json({ error: 'Error al eliminar enlace' });
  }
});

// GET /tareas/publico/:token - Vista HTML pública del tablero
app.get('/tareas/publico/:token', (req, res) => {
  res.sendFile(resolveView('public', 'tareas-publico.html'));
});

// GET /api/maintenance/tasks/public/:token - Datos para vista pública del tablero
app.get('/api/maintenance/tasks/public/:token', async (req, res) => {
  try {
    const { token } = req.params;
    const checkResult = await pool.query(`
      SELECT stb.*, u.name as created_by_name
      FROM shared_tasks_boards stb
      LEFT JOIN users u ON stb.created_by = u.id
      WHERE stb.token = $1
    `, [token]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'El enlace del tablero no existe o es inválido' });
    }

    const boardConfig = checkResult.rows[0];

    if (!boardConfig.is_active) {
      return res.status(410).json({ error: 'Este enlace ha sido revocado o desactivado' });
    }

    if (boardConfig.expires_at && new Date(boardConfig.expires_at) < new Date()) {
      return res.status(410).json({ error: 'Este enlace ha expirado' });
    }

    let taskWhere = 'WHERE 1=1';
    const params = [];
    if (boardConfig.department && boardConfig.department !== 'all') {
      params.push(boardConfig.department);
      taskWhere += ` AND (mt.department = $${params.length} OR (mt.department IS NULL AND $${params.length} = 'Mantenimiento'))`;
    }

    const tasksQuery = `
      SELECT 
        mt.*,
        u_assign.name as assigned_to_name,
        u_create.name as created_by_name,
        u_comp.name as completed_by_name
      FROM maintenance_tasks mt
      LEFT JOIN users u_assign ON mt.assigned_to = u_assign.id
      LEFT JOIN users u_create ON mt.created_by = u_create.id
      LEFT JOIN users u_comp ON mt.completed_by = u_comp.id
      ${taskWhere}
      ORDER BY CASE WHEN mt.status = 'completed' THEN 2 ELSE 1 END, mt.due_date ASC NULLS LAST, mt.created_at DESC
    `;

    const tasksResult = await pool.query(tasksQuery, params);

    const tasks = tasksResult.rows.map(task => {
      const items = Array.isArray(task.checklist) ? task.checklist : [];
      const totalItems = items.length;
      const completedItems = items.filter(i => i && i.done).length;
      const progressPercent = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : (task.status === 'completed' ? 100 : 0);

      return {
        ...task,
        checklist: items,
        checklistMetrics: {
          total: totalItems,
          completed: completedItems,
          percent: progressPercent
        }
      };
    });

    const stats = {
      total: tasks.length,
      pending: tasks.filter(t => t.status === 'pending').length,
      in_progress: tasks.filter(t => t.status === 'in-progress').length,
      completed: tasks.filter(t => t.status === 'completed').length,
      recurring_count: tasks.filter(t => t.is_recurring).length
    };

    res.json({
      board: {
        title: boardConfig.title,
        department: boardConfig.department,
        created_at: boardConfig.created_at,
        created_by_name: boardConfig.created_by_name,
        expires_at: boardConfig.expires_at
      },
      stats,
      tasks
    });
  } catch (error) {
    console.error('Error al obtener datos públicos del tablero:', error.message);
    res.status(500).json({ error: 'Error al cargar datos del tablero' });
  }
});

// ==============================================
// RUTA PROTEGIDA PARA REPORTES
// ==============================================
app.get('/reportes', (req, res, next) => {
  const token = req.cookies.token;

  if (!token) {
    return res.redirect('/?error=auth_required');
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.redirect('/?error=invalid_token');
    }

    // Permitir acceso a gerencia, administrador, mantenimiento, soporte, rrhh y compras
    if (!['gerencia', 'administrador', 'mantenimiento', 'support', 'rrhh', 'compras'].includes(user.role)) {
      return res.redirect('/?error=access_denied');
    }

    res.sendFile(resolveView('private', 'reportes.html'));
  });
});

// Start server with WebSocket support (solo en entornos locales / servidores dedicados)
if (!process.env.VERCEL) {
  server.on('error', (error) => {
    if (error.syscall !== 'listen') throw error;
    const bind = typeof PORT === 'string' ? 'Pipe ' + PORT : 'Port ' + PORT;
    switch (error.code) {
      case 'EACCES':
        console.error(`❌ ERROR: ${bind} requiere privilegios elevados.`);
        process.exit(1);
        break;
      case 'EADDRINUSE':
        console.error(`❌ ERROR: ${bind} ya está en uso.`);
        process.exit(1);
        break;
      default:
        console.error('❌ Error al iniciar el servidor:', error.message);
        throw error;
    }
  });

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor corriendo en el puerto ${PORT}`);
  });
}

// Exportar app para despliegue Serverless en Vercel
module.exports = app;
