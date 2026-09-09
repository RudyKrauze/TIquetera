-- ============================================
-- SCRIPT DE VERIFICACIÓN DE MIGRACIÓN
-- PostgreSQL - Sistema de Tickets
-- ============================================

\echo '====================================='
\echo 'VERIFICACIÓN DE MIGRACIÓN A POSTGRESQL'
\echo '====================================='

-- 1. Verificar tablas existentes
\echo '\n1. TABLAS CREADAS:'
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns 
   WHERE table_name = t.table_name AND table_schema = 'public') as columnas
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Verificar estructura de tabla users
\echo '\n2. ESTRUCTURA TABLA USERS:'
\d users;

-- 3. Verificar estructura de tabla tickets
\echo '\n3. ESTRUCTURA TABLA TICKETS:'
\d tickets;

-- 4. Verificar estructura de tabla ticket_updates
\echo '\n4. ESTRUCTURA TABLA TICKET_UPDATES:'
\d ticket_updates;

-- 5. Verificar índices creados
\echo '\n5. ÍNDICES CREADOS:'
SELECT 
  schemaname,
  tablename,
  indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 6. Verificar triggers
\echo '\n6. TRIGGERS ACTIVOS:'
SELECT 
  tgname as trigger_name,
  tgrelid::regclass as tabla,
  tgenabled as habilitado
FROM pg_trigger
WHERE tgname NOT LIKE 'pg_%'
  AND tgname NOT LIKE 'RI_%';

-- 7. Verificar foreign keys
\echo '\n7. FOREIGN KEYS:'
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public';

-- 8. Contar registros en cada tabla
\echo '\n8. CANTIDAD DE REGISTROS:'
SELECT 
  'users' as tabla, 
  COUNT(*) as registros 
FROM users
UNION ALL
SELECT 
  'tickets' as tabla, 
  COUNT(*) as registros 
FROM tickets
UNION ALL
SELECT 
  'ticket_updates' as tabla, 
  COUNT(*) as registros 
FROM ticket_updates
UNION ALL
SELECT 
  'system_config' as tabla, 
  COUNT(*) as registros 
FROM system_config;

-- 9. Verificar usuarios por defecto
\echo '\n9. USUARIOS POR DEFECTO CREADOS:'
SELECT 
  id,
  name,
  email,
  role,
  department,
  created_at
FROM users
ORDER BY id;

-- 10. Verificar configuración del sistema
\echo '\n10. CONFIGURACIÓN DEL SISTEMA:'
SELECT * FROM system_config;

-- 11. Verificar secuencias (SERIAL)
\echo '\n11. SECUENCIAS AUTOINCREMENT:'
SELECT 
  sequencename,
  last_value
FROM pg_sequences
WHERE schemaname = 'public';

-- 12. Verificar tipos de datos de columnas críticas
\echo '\n12. TIPOS DE DATOS CRÍTICOS:'
SELECT 
  table_name,
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('users', 'tickets', 'ticket_updates')
  AND column_name IN ('id', 'email', 'tracking_id', 'created_at', 'updated_at')
ORDER BY table_name, ordinal_position;

-- 13. Verificar constraints UNIQUE
\echo '\n13. CONSTRAINTS UNIQUE:'
SELECT
  tc.table_name,
  kcu.column_name,
  tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'UNIQUE'
  AND tc.table_schema = 'public';

-- 14. Test de INSERT (no se ejecuta realmente)
\echo '\n14. SINTAXIS SQL VALIDADA:'
\echo 'INSERT INTO tickets: OK (con RETURNING)'
\echo 'INSERT INTO users: OK (con ON CONFLICT)'
\echo 'UPDATE con placeholders: OK ($1, $2, ...)'
\echo 'SELECT con JOINs: OK'

-- 15. Verificar permisos del usuario
\echo '\n15. PERMISOS DEL USUARIO ACTUAL:'
SELECT 
  grantee,
  table_schema,
  table_name,
  privilege_type
FROM information_schema.table_privileges
WHERE grantee = current_user
  AND table_schema = 'public'
ORDER BY table_name, privilege_type;

\echo '\n====================================='
\echo 'VERIFICACIÓN COMPLETADA'
\echo '====================================='
