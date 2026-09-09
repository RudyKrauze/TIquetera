-- Migración: Añadir campo sede a tabla tickets
-- Fecha: 2026-02-09

-- Añadir columna sede
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS sede VARCHAR(50);

-- Crear índice para optimizar consultas por sede
CREATE INDEX IF NOT EXISTS idx_tickets_sede ON tickets(sede);

-- Verificar que la columna fue agregada correctamente
SELECT column_name, data_type, character_maximum_length 
FROM information_schema.columns 
WHERE table_name = 'tickets' AND column_name = 'sede';
