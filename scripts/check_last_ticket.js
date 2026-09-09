const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'tiquetera_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

async function checkLast() {
  try {
    const res = await pool.query("SELECT id, tracking_id, priority, attachments FROM tickets ORDER BY id DESC LIMIT 1");
    if (res.rows.length > 0) {
        console.log('Último Ticket:', JSON.stringify(res.rows[0], null, 2));
    } else {
        console.log('No hay tickets.');
    }
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}

checkLast();
