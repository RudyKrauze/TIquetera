/**
 * Entrypoint de la función Serverless para Vercel.
 * Exporta la aplicación Express configurada en server.js.
 */
const app = require('../server');

module.exports = app;
