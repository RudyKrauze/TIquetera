-- Script idempotente de endurecimiento de seguridad para Supabase (SQL Editor)
-- Ejecutar en Supabase Dashboard -> SQL Editor (con privilegios de propietario / supabase_admin)

-- 1. Tabla de auditoría anti-spam, replay y duplicados en creación de tickets
CREATE TABLE IF NOT EXISTS public.ticket_security_events (
    id SERIAL PRIMARY KEY,
    ip_address TEXT NOT NULL,
    email TEXT,
    content_hash TEXT NOT NULL,
    form_jti TEXT UNIQUE,
    event_type TEXT NOT NULL DEFAULT 'ticket_created',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ticket_sec_ip_created ON public.ticket_security_events(ip_address, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ticket_sec_email_created ON public.ticket_security_events(email, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ticket_sec_hash_created ON public.ticket_security_events(content_hash, created_at DESC);

-- 2. Habilitar Row Level Security (RLS) en las 13 tablas públicas
-- Bloquea lecturas y escrituras directas desde clientes anon/authenticated de PostgREST
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ticket_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.report_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.push_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ticket_departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ticket_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.maintenance_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.shared_tasks_boards ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ticket_security_events ENABLE ROW LEVEL SECURITY;

-- 3. Endurecer el bucket "ticket-attachments" (límite 4MB y sin SVG para evitar Stored XSS)
UPDATE storage.buckets
SET public = true,
    file_size_limit = 4194304,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif']
WHERE id = 'ticket-attachments';

-- 4. Endurecer políticas de storage.objects (ejecutar desde SQL Editor como propietario)
-- Elimina permisos peligrosos de actualización pública
DROP POLICY IF EXISTS "Allow Updates ticket-attachments" ON storage.objects;

-- IMPORTANTE:
-- Verifica primero que SUPABASE_SERVICE_ROLE_KEY en .env y en Vercel contenga la clave real "service_role"
-- (NO la clave "anon"). Mientras el backend use una clave con rol "anon", cambiar INSERT a "TO service_role"
-- impedirá que el backend suba adjuntos.
--
-- Opción A (transitoria si aún usas anon key en backend, restringe al menos path y extensiones):
-- DROP POLICY IF EXISTS "Allow Uploads ticket-attachments" ON storage.objects;
-- CREATE POLICY "Allow Uploads ticket-attachments"
-- ON storage.objects FOR INSERT
-- TO public
-- WITH CHECK (
--     bucket_id = 'ticket-attachments'
--     AND name LIKE 'tickets/%'
--     AND lower(storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif')
-- );
--
-- Opción B (RECOMENDADA una vez configurada la verdadera SUPABASE_SERVICE_ROLE_KEY en .env y Vercel):
DROP POLICY IF EXISTS "Allow Uploads ticket-attachments" ON storage.objects;
CREATE POLICY "Allow Uploads ticket-attachments"
ON storage.objects FOR INSERT
TO service_role
WITH CHECK (
    bucket_id = 'ticket-attachments'
    AND name LIKE 'tickets/%'
    AND lower(storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif')
);
