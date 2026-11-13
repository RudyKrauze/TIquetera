const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

function getEnvPasswordOrRandom(envVarValue) {
  if (envVarValue && String(envVarValue).trim() !== '') {
    return String(envVarValue).trim();
  }
  return crypto.randomBytes(16).toString('hex');
}

/**
 * Inicializa la base de datos: crea tablas, índices y usuarios por defecto.
 * @param {import('pg').Pool} pool - Pool de conexiones de PostgreSQL
 */
async function initializeDatabase(pool) {
  try {
    console.log('🏁 Iniciando proceso de inicialización de base de datos...');

    // 1. Leer y ejecutar el esquema SQL
    const schemaPath = path.join(__dirname, 'db_schema.sql');
    if (fs.existsSync(schemaPath)) {
      const schemaSql = fs.readFileSync(schemaPath, 'utf8');
      await pool.query(schemaSql);
      console.log('✅ Esquema de tablas e índices verificado/creado.');
    } else {
      console.warn('⚠️ No se encontró db_schema.sql. Saltando creación de tablas.');
    }

    // 2. Verificar si ya se crearon los usuarios por defecto
    const configCheck = await pool.query("SELECT value FROM system_config WHERE key = 'default_users_created'");
    
    if (configCheck.rows.length === 0) {
      console.log('⚙️  Detectada primera ejecución: sembrando usuarios por defecto...');

      const defaultUsers = [
        {
          email: process.env.ADMIN_EMAIL || process.env.DEFAULT_ADMIN_EMAIL || 'admin@tiquetera.com',
          password: getEnvPasswordOrRandom(process.env.ADMIN_PASSWORD || process.env.DEFAULT_ADMIN_PASSWORD),
          name: 'Administrador',
          role: 'administrador',
          department: null
        },
        {
          email: process.env.DEFAULT_SUPPORT_EMAIL || 'soporte@tiquetera.com',
          password: getEnvPasswordOrRandom(process.env.DEFAULT_SUPPORT_PASSWORD),
          name: 'Sistemas',
          role: 'support',
          department: 'Sistemas'
        },
        {
          email: process.env.DEFAULT_RRHH_EMAIL || 'rrhh@tiquetera.com',
          password: getEnvPasswordOrRandom(process.env.DEFAULT_RRHH_PASSWORD),
          name: 'Recursos Humanos',
          role: 'rrhh',
          department: 'Recursos Humanos'
        },
        {
          email: process.env.DEFAULT_MANT_EMAIL || 'mantenimiento@tiquetera.com',
          password: getEnvPasswordOrRandom(process.env.DEFAULT_MANT_PASSWORD),
          name: 'Mantenimiento',
          role: 'mantenimiento',
          department: 'Mantenimiento'
        },
        {
          email: process.env.DEFAULT_COMPRAS_EMAIL || 'compras@tiquetera.com',
          password: getEnvPasswordOrRandom(process.env.DEFAULT_COMPRAS_PASSWORD),
          name: 'Compras e Insumos',
          role: 'compras',
          department: 'Compras e Insumos'
        },
        {
          email: process.env.DEFAULT_GERENCIA_EMAIL || 'gerencia@tiquetera.com',
          password: getEnvPasswordOrRandom(process.env.DEFAULT_GERENCIA_PASSWORD),
          name: 'Gerencia',
          role: 'gerencia',
          department: 'Gerencia'
        }
      ];

      for (const user of defaultUsers) {
        const hashedPassword = bcrypt.hashSync(user.password, 8);
        await pool.query(
          `INSERT INTO users (email, password, name, role, department) 
           VALUES ($1, $2, $3, $4, $5) ON CONFLICT (email) DO NOTHING`,
          [user.email, hashedPassword, user.name, user.role, user.department]
        );
      }

      await pool.query(`INSERT INTO system_config (key, value) VALUES ($1, $2)`, ['default_users_created', 'true']);
      console.log('✅ Usuarios por defecto creados exitosamente.');
    }

    // 3. Verificar migración de áreas v2
    const migrationCheck = await pool.query("SELECT value FROM system_config WHERE key = 'areas_migrated_v2'");
    if (migrationCheck.rows.length === 0) {
      console.log('⚙️  Ejecutando migración de áreas...');
      await pool.query("UPDATE users SET active = FALSE WHERE role IN ('facturacion', 'contact')");
      await pool.query(`INSERT INTO system_config (key, value) VALUES ($1, $2) ON CONFLICT DO NOTHING`, ['areas_migrated_v2', 'true']);
      console.log('✅ Migración de áreas completada.');
    }

    // 3b. Habilitar área y usuario de Gerencia
    try {
      await pool.query("UPDATE users SET active = TRUE, department = 'Gerencia' WHERE role = 'gerencia' AND (active = FALSE OR department IS NULL OR department != 'Gerencia')");
      const gerenciaCheck = await pool.query("SELECT id FROM users WHERE role = 'gerencia'");
      if (gerenciaCheck.rows.length === 0) {
        const hashedPassword = bcrypt.hashSync(getEnvPasswordOrRandom(process.env.DEFAULT_GERENCIA_PASSWORD), 8);
        await pool.query(
          `INSERT INTO users (email, password, name, role, department, active) 
           VALUES ($1, $2, 'Gerencia', 'gerencia', 'Gerencia', TRUE) ON CONFLICT (email) DO UPDATE SET active = TRUE, department = 'Gerencia'`,
          [process.env.DEFAULT_GERENCIA_EMAIL || 'gerencia@tiquetera.com', hashedPassword]
        );
      }
      console.log('✅ Usuario y área Gerencia verificados y activados.');
    } catch (gErr) {
      console.warn('⚠️ Error no crítico al activar gerencia:', gErr.message);
    }

    // 4. Migración: Agregar columna affected_area si no existe
    try {
      await pool.query(`
        ALTER TABLE tickets ADD COLUMN IF NOT EXISTS affected_area VARCHAR(255);
      `);
      console.log('✅ Verificación de columna affected_area completada.');
    } catch (migError) {
      console.log('ℹ️ Nota: Error no crítico al verificar columna affected_area:', migError.message);
    }

    // 4b. Migración: Agregar columna attachments si no existe
    try {
      await pool.query(`
        ALTER TABLE tickets ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]'::jsonb;
      `);
      console.log('✅ Verificación de columna attachments completada.');
    } catch (migError) {
      console.log('ℹ️ Nota: Error no crítico al verificar columna attachments:', migError.message);
    }

    // 4c. Migración: Agregar columna sede si no existe
    try {
      await pool.query(`
        ALTER TABLE tickets ADD COLUMN IF NOT EXISTS sede VARCHAR(100) DEFAULT 'Todas';
      `);
      console.log('✅ Verificación de columna sede completada.');
    } catch (migError) {
      console.log('ℹ️ Nota: Error no crítico al verificar columna sede:', migError.message);
    }

    // 5. Migración: Crear tabla shared_reports si no existe
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS shared_reports (
            id SERIAL PRIMARY KEY,
            token VARCHAR(64) UNIQUE NOT NULL,
            title VARCHAR(255) NOT NULL,
            period VARCHAR(50) DEFAULT '7d',
            department VARCHAR(255) DEFAULT 'all',
            created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP,
            is_active BOOLEAN DEFAULT TRUE,
            views_count INTEGER DEFAULT 0,
            last_viewed_at TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS idx_shared_reports_token ON shared_reports(token);
        CREATE INDEX IF NOT EXISTS idx_shared_reports_active ON shared_reports(is_active);
      `);
      console.log('✅ Verificación de tabla shared_reports completada.');
    } catch (sharedError) {
      console.log('ℹ️ Nota: Error no crítico al verificar tabla shared_reports:', sharedError.message);
    }

    // 6. Migración: Crear tabla maintenance_tasks si no existe
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS maintenance_tasks (
            id SERIAL PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT,
            priority VARCHAR(20) DEFAULT 'medium',
            category VARCHAR(100) DEFAULT 'General',
            department VARCHAR(100) DEFAULT 'Mantenimiento',
            sede VARCHAR(100) DEFAULT 'Todas',
            assigned_to INTEGER REFERENCES users(id) ON DELETE SET NULL,
            status VARCHAR(50) DEFAULT 'pending',
            due_date TIMESTAMP,
            is_recurring BOOLEAN DEFAULT FALSE,
            recurrence_interval VARCHAR(50) DEFAULT 'none',
            checklist JSONB DEFAULT '[]'::jsonb,
            completed_at TIMESTAMP,
            completed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
            created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS department VARCHAR(100) DEFAULT 'Mantenimiento';
        ALTER TABLE maintenance_tasks ADD COLUMN IF NOT EXISTS assigned_technician VARCHAR(100);
        CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_status ON maintenance_tasks(status);
        CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_assigned ON maintenance_tasks(assigned_to);
        CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_recurring ON maintenance_tasks(is_recurring, recurrence_interval);
        CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_department ON maintenance_tasks(department);
      `);
      console.log('✅ Verificación de tabla maintenance_tasks completada.');
    } catch (maintError) {
      console.log('ℹ️ Nota: Error no crítico al verificar tabla maintenance_tasks:', maintError.message);
    }

    // 6b. Migración: Agregar columna assigned_technician a tickets si no existe
    try {
      await pool.query(`
        ALTER TABLE tickets ADD COLUMN IF NOT EXISTS assigned_technician VARCHAR(100);
        CREATE INDEX IF NOT EXISTS idx_tickets_assigned_technician ON tickets(assigned_technician);
      `);
      console.log('✅ Verificación de columna assigned_technician en tickets completada.');
    } catch (techError) {
      console.log('ℹ️ Nota: Error no crítico al verificar assigned_technician en tickets:', techError.message);
    }

    // 7. Migración: Crear tabla shared_tasks_boards si no existe
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS shared_tasks_boards (
            id SERIAL PRIMARY KEY,
            token VARCHAR(64) UNIQUE NOT NULL,
            title VARCHAR(255) NOT NULL,
            period VARCHAR(50) DEFAULT '7d',
            start_date DATE,
            end_date DATE,
            department VARCHAR(255) DEFAULT 'Mantenimiento',
            created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
            expires_at TIMESTAMP,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        ALTER TABLE shared_tasks_boards ADD COLUMN IF NOT EXISTS period VARCHAR(50) DEFAULT '7d';
        ALTER TABLE shared_tasks_boards ADD COLUMN IF NOT EXISTS start_date DATE;
        ALTER TABLE shared_tasks_boards ADD COLUMN IF NOT EXISTS end_date DATE;
        CREATE INDEX IF NOT EXISTS idx_shared_tasks_boards_token ON shared_tasks_boards(token);
        CREATE INDEX IF NOT EXISTS idx_shared_tasks_boards_active ON shared_tasks_boards(is_active);
      `);
      console.log('✅ Verificación de tabla shared_tasks_boards completada.');
    } catch (stbError) {
      console.log('ℹ️ Nota: Error no crítico al verificar tabla shared_tasks_boards:', stbError.message);
    }

    // 8. Tabla de eventos de seguridad para creación de tickets (anti-spam, replay y duplicados)
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS ticket_security_events (
          id SERIAL PRIMARY KEY,
          ip_address TEXT NOT NULL,
          email TEXT,
          content_hash TEXT NOT NULL,
          form_jti TEXT UNIQUE,
          event_type TEXT NOT NULL DEFAULT 'ticket_created',
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS idx_ticket_sec_ip_created ON ticket_security_events(ip_address, created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_ticket_sec_email_created ON ticket_security_events(email, created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_ticket_sec_hash_created ON ticket_security_events(content_hash, created_at DESC);
      `);
      console.log('✅ Verificación de tabla ticket_security_events completada.');
    } catch (secErr) {
      console.log('ℹ️ Nota: Error no crítico al verificar ticket_security_events:', secErr.message);
    }

    // 9. Habilitar Row Level Security (RLS) en todas las tablas públicas (defensa en profundidad en Supabase)
    try {
      const rlsTables = [
        'users',
        'tickets',
        'ticket_updates',
        'notifications',
        'notification_settings',
        'audit_log',
        'report_cache',
        'push_subscriptions',
        'ticket_departments',
        'ticket_categories',
        'maintenance_tasks',
        'shared_tasks_boards',
        'ticket_security_events'
      ];
      for (const tbl of rlsTables) {
        await pool.query(`ALTER TABLE IF EXISTS ${tbl} ENABLE ROW LEVEL SECURITY`);
      }
      console.log('✅ Verificación de RLS en tablas públicas completada.');
    } catch (rlsErr) {
      console.log('ℹ️ Nota: Error no crítico al habilitar RLS:', rlsErr.message);
    }

    // 10. Endurecer límites del bucket de Supabase Storage (4MB, sin SVG) y limpiar política UPDATE si es posible
    try {
      const bucketCheck = await pool.query(`SELECT to_regclass('storage.buckets') AS tbl`);
      if (bucketCheck.rows[0] && bucketCheck.rows[0].tbl) {
        await pool.query(`
          UPDATE storage.buckets
          SET file_size_limit = 4194304,
              allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif']
          WHERE id = 'ticket-attachments'
        `);
        console.log('✅ Límites de bucket ticket-attachments actualizados (4MB, sin SVG).');
      }
    } catch (bucketErr) {
      console.log('ℹ️ Nota: No se pudo actualizar storage.buckets desde db_init (aplicar supabase/security_hardening.sql):', bucketErr.message);
    }

    try {
      const objCheck = await pool.query(`SELECT to_regclass('storage.objects') AS tbl`);
      if (objCheck.rows[0] && objCheck.rows[0].tbl) {
        await pool.query(`DROP POLICY IF EXISTS "Allow Updates ticket-attachments" ON storage.objects`);
      }
    } catch (polErr) {
      console.log('ℹ️ Nota: Sin permisos de propietario para DROP POLICY en storage.objects (ejecutar supabase/security_hardening.sql en SQL Editor):', polErr.message);
    }

    console.log('🚀 Inicialización de base de datos finalizada con éxito.');
  } catch (error) {
    console.error('❌ Error crítico durante la inicialización de la base de datos:', error.message);
    // Re-lanzar para que server.js maneje la salida fatal
    throw error;
  }
}

module.exports = { initializeDatabase };
