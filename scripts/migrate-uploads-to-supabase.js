/**
 * scripts/migrate-uploads-to-supabase.js
 * =========================================
 * Migra los archivos adjuntos locales (public/uploads/tickets/) a Supabase Storage.
 * Actualiza las referencias en la base de datos (columna attachments de tickets).
 *
 * Ejecutar UNA SOLA VEZ antes del deploy final:
 *   npm run migrate:uploads
 *
 * Prerequisitos:
 *   - SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en .env
 *   - DATABASE_URL en .env
 *   - El bucket 'ticket-files' debe existir en Supabase Storage (crear si no existe)
 */
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

// Validar variables de entorno
const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, DATABASE_URL, POSTGRES_URL, SUPABASE_DB_URL } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error('❌ Faltan SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en .env');
    process.exit(1);
}

const dbConnectionString = DATABASE_URL || POSTGRES_URL || SUPABASE_DB_URL;
if (!dbConnectionString) {
    console.error('❌ Falta DATABASE_URL (o POSTGRES_URL / SUPABASE_DB_URL) en .env');
    process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const pool = new Pool({
    connectionString: dbConnectionString,
    ssl: { rejectUnauthorized: false }
});

const BUCKET_NAME = 'ticket-files';
const UPLOADS_DIR = path.join(__dirname, '../public/uploads/tickets');
const SUPABASE_FOLDER = 'ticket-attachments';

function getMimeType(filename) {
    const ext = path.extname(filename).toLowerCase();
    const mimeMap = {
        '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.jfif': 'image/jpeg',
        '.png': 'image/png', '.webp': 'image/webp', '.avif': 'image/avif',
        '.heic': 'image/heic', '.heif': 'image/heif', '.gif': 'image/gif'
    };
    return mimeMap[ext] || 'application/octet-stream';
}

async function ensureBucketExists() {
    const { data: buckets } = await supabase.storage.listBuckets();
    const exists = buckets?.some(b => b.name === BUCKET_NAME);
    if (!exists) {
        const { error } = await supabase.storage.createBucket(BUCKET_NAME, { public: true });
        if (error) throw new Error(`No se pudo crear el bucket '${BUCKET_NAME}': ${error.message}`);
        console.log(`✅ Bucket '${BUCKET_NAME}' creado en Supabase Storage`);
    } else {
        console.log(`✅ Bucket '${BUCKET_NAME}' ya existe`);
    }
}

async function migrateUploads() {
    console.log('🚀 Iniciando migración de uploads a Supabase Storage...\n');

    // 1. Verificar que el directorio de uploads existe
    if (!fs.existsSync(UPLOADS_DIR)) {
        console.log('ℹ️  No hay directorio de uploads locales. Nada que migrar.');
        await pool.end();
        return;
    }

    // 2. Verificar/crear bucket en Supabase
    await ensureBucketExists();

    // 3. Listar archivos locales
    const files = fs.readdirSync(UPLOADS_DIR).filter(f => !f.startsWith('.'));
    if (files.length === 0) {
        console.log('ℹ️  No hay archivos locales para migrar.');
        await pool.end();
        return;
    }

    console.log(`📦 Encontrados ${files.length} archivos para migrar...\n`);

    let migrated = 0;
    let failed = 0;
    const urlMap = {}; // oldUrl → newUrl para actualizar la BD

    for (const filename of files) {
        const localPath = path.join(UPLOADS_DIR, filename);
        const fileBuffer = fs.readFileSync(localPath);
        const mimeType = getMimeType(filename);
        const supabasePath = `${SUPABASE_FOLDER}/${filename}`;
        const oldUrl = `/uploads/tickets/${filename}`;

        try {
            // Subir a Supabase Storage (upsert: no falla si ya existe)
            const { error: uploadError } = await supabase.storage
                .from(BUCKET_NAME)
                .upload(supabasePath, fileBuffer, { contentType: mimeType, upsert: true });

            if (uploadError) throw new Error(uploadError.message);

            // Obtener URL pública
            const { data: { publicUrl } } = supabase.storage
                .from(BUCKET_NAME)
                .getPublicUrl(supabasePath);

            urlMap[oldUrl] = publicUrl;
            migrated++;
            const sizeMB = (fileBuffer.length / 1024 / 1024).toFixed(2);
            console.log(`  ✅ [${migrated}/${files.length}] ${filename} (${sizeMB} MB) → ${publicUrl}`);

        } catch (err) {
            failed++;
            console.error(`  ❌ Error al migrar ${filename}: ${err.message}`);
        }
    }

    // 4. Actualizar referencias en la base de datos
    if (Object.keys(urlMap).length > 0) {
        console.log('\n📝 Actualizando referencias en la base de datos...');

        // Obtener todos los tickets con attachments
        const { rows: tickets } = await pool.query(
            `SELECT id, attachments FROM tickets WHERE attachments IS NOT NULL AND attachments != '[]'::jsonb`
        );

        let dbUpdated = 0;
        for (const ticket of tickets) {
            let attachmentsStr = JSON.stringify(ticket.attachments);
            let changed = false;

            for (const [oldUrl, newUrl] of Object.entries(urlMap)) {
                if (attachmentsStr.includes(oldUrl)) {
                    attachmentsStr = attachmentsStr.split(oldUrl).join(newUrl);
                    changed = true;
                }
            }

            if (changed) {
                await pool.query(
                    `UPDATE tickets SET attachments = $1::jsonb WHERE id = $2`,
                    [attachmentsStr, ticket.id]
                );
                dbUpdated++;
            }
        }

        console.log(`  ✅ ${dbUpdated} ticket(s) actualizados en la BD`);
    }

    await pool.end();

    console.log('\n' + '='.repeat(50));
    console.log(`🎉 Migración completada:`);
    console.log(`   ✅ Subidos: ${migrated} archivos`);
    if (failed > 0) console.log(`   ❌ Fallidos: ${failed} archivos`);
    console.log('='.repeat(50));

    if (migrated > 0 && failed === 0) {
        console.log('\n⚠️  Próximo paso: una vez verificado que todo funciona en producción,');
        console.log('   podés eliminar el directorio public/uploads/ del repositorio.');
    }
}

migrateUploads().catch(err => {
    console.error('❌ Error crítico en la migración:', err.message);
    pool.end();
    process.exit(1);
});
