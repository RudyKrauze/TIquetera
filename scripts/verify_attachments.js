const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config();

const BASE_URL = 'http://localhost:3005';

// Crear un archivo temporal para probar la subida
const testFileSize = 1024 * 10; // 10KB
const testFilePath = path.join(__dirname, 'test_image.png');
// Crear un archivo "fake" (solo texto, pero con extension png para pasar el filtro de multer si verifica extension)
// O mejor, validemos si el filtro chequea magic numbers. El server.js usa `file.mimetype.startsWith('image/')`
// Axios form-data permite especificar filename y contentType.

// Crear un archivo pequeño
fs.writeFileSync(testFilePath, 'fake image data');

async function testAttachments() {
  const form = new FormData();
  form.append('name', 'Attachment Tester');
  form.append('email', 'test@attachments.com');
  form.append('affected_area', 'QA');
  form.append('department', 'Sistemas');
  form.append('title', 'Ticket con adjuntos');
  form.append('description', 'Probando subida de archivos');
  form.append('attachments', fs.createReadStream(testFilePath), {
    filename: 'test_image.png',
    contentType: 'image/png'
  });

  try {
    console.log('🚀 Subiendo ticket con archivo...');
    const response = await axios.post(`${BASE_URL}/api/tickets`, form, {
      headers: { ...form.getHeaders() }
    });

    const ticket = response.data.ticket || response.data;
    console.log('✅ Ticket creado:', ticket.tracking_id);

    // Verificar en BD
    const pool = new Pool({
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        database: process.env.DB_NAME || 'tiquetera_db',
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD,
    });

    const res = await pool.query("SELECT attachments FROM tickets WHERE id = $1", [ticket.id]);
    const attachments = res.rows[0].attachments;
    console.log('📦 Attachments en BD:', JSON.stringify(attachments, null, 2));

    await pool.end();

    if (Array.isArray(attachments) && attachments.length > 0) {
        const filePath = path.join(__dirname, 'public', attachments[0]);
        if (fs.existsSync(filePath)) {
            console.log('🎉 Archivo encontrado en disco:', filePath);
        } else {
            console.error('❌ Archivo NO encontrado en disco:', filePath);
        }
    } else {
        console.error('❌ No se guardaron adjuntos en la BD');
    }

  } catch (error) {
    console.error('❌ Error full:', error);
    if (error.response) console.error('Data:', error.response.data);
  } finally {
    if (fs.existsSync(testFilePath)) fs.unlinkSync(testFilePath);
  }
}

testAttachments();
