const nodemailer = require('nodemailer');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3005';
const defaultFrom = process.env.EMAIL_FROM || '"Sistema de Tickets" <no-reply@tiquetera.com>';

// Configuración del transporter uando variables de entorno
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp-relay.brevo.com',
  port: parseInt(process.env.SMTP_PORT) || 587,
  secure: false, // true para 465, false para otros puertos
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// Branding colors
const COLORS = {
  primary: '#008B8B',       // Teal/Cyan principal
  primaryDark: '#006B6B',   // Teal oscuro
  secondary: '#4A4A4A',     // Gris oscuro
  bg: '#F5F7FB',            // Fondo suave
  surface: '#FFFFFF',       // Blanco
  textMain: '#1F2933',      // Texto principal
  textMuted: '#6B7280',     // Texto secundario
  success: '#2F9E44',       // Verde
  warning: '#F59F00',       // Amarillo
  danger: '#E03131',        // Rojo
  info: '#4C6FFF'           // Azul
};

/**
 * Función auxiliar para generar el wrapper HTML común
 */
function getEmailTemplate(title, content) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 0; font-family: 'Montserrat', Arial, sans-serif; background-color: ${COLORS.bg}; color: ${COLORS.textMain}; }
        .container { max-width: 600px; margin: 0 auto; background-color: ${COLORS.surface}; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
        .header { background: linear-gradient(135deg, ${COLORS.primary} 0%, ${COLORS.primaryDark} 100%); padding: 25px; text-align: center; }
        .header h1 { color: #FFFFFF; margin: 0; font-size: 24px; font-weight: 600; letter-spacing: 1px; }
        .content { padding: 35px 25px; }
        .footer { background-color: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: ${COLORS.textMuted}; border-top: 1px solid #e2e8f0; }
        .btn { display: inline-block; padding: 12px 24px; background-color: ${COLORS.primary}; color: #FFFFFF; text-decoration: none; border-radius: 50px; font-weight: 600; margin-top: 20px; transition: background 0.3s; }
        .btn:hover { background-color: ${COLORS.primaryDark}; }
        .info-box { background-color: #f1fbfb; padding: 20px; border-radius: 8px; border-left: 4px solid ${COLORS.primary}; margin: 20px 0; }
        .label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: ${COLORS.textMuted}; font-weight: 700; display: block; margin-bottom: 4px; }
        .value { font-size: 15px; font-weight: 500; color: ${COLORS.textMain}; display: block; margin-bottom: 12px; }
        h2 { color: ${COLORS.primaryDark}; font-size: 20px; margin-top: 0; }
        p { line-height: 1.6; color: ${COLORS.secondary}; margin-bottom: 15px; }
      </style>
    </head>
    <body>
      <div style="padding: 20px;">
        <div class="container">
          <div class="header">
            <!-- Puedes reemplazar el texto por una etiqueta <img> si tienes una URL pública para el logo -->
            <h1>TIQUETERA</h1>
          </div>
          <div class="content">
            ${content}
          </div>
          <div class="footer">
            <p style="margin: 0;">&copy; ${new Date().getFullYear()} Sistema de Tickets. Todos los derechos reservados.</p>
            <p style="margin: 5px 0 0;">Este es un mensaje automático, por favor no respondas directamente.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
}

/**
 * Envía un correo de confirmación al crear un ticket
 * @param {Object} ticket - Objeto del ticket creado
 */
async function sendTicketCreated(ticket) {
  if (!ticket.created_by_email) return;

  const ticketUrl = `${BASE_URL}/track/${ticket.tracking_id}`;
  
  const htmlContent = `
    <h2>¡Ticket Recibido!</h2>
    <p>Hola <strong>${ticket.created_by_name}</strong>,</p>
    <p>Hemos recibido tu solicitud correctamente. Nuestro equipo ya ha sido notificado y comenzará a trabajar en ello pronto.</p>
    
    <div class="info-box">
      <span class="label">ID de Seguimiento</span>
      <span class="value" style="font-size: 18px; font-family: monospace;">${ticket.tracking_id}</span>
      
      <span class="label">Título</span>
      <span class="value">${ticket.title}</span>
      
      <span class="label">Departamento</span>
      <span class="value">${ticket.department}</span>
      
      <span class="label">Sede</span>
      <span class="value">${ticket.sede || 'No especificada'}</span>
      
      <span class="label">Prioridad</span>
      <span class="value" style="margin-bottom: 0;">${ticket.priority.charAt(0).toUpperCase() + ticket.priority.slice(1)}</span>
    </div>

    <p style="font-size: 14px; border-left: 2px solid #e2e8f0; padding-left: 10px; color: ${COLORS.textMuted};">
      "${ticket.description}"
    </p>

    <div style="text-align: center;">
      <a href="${ticketUrl}" class="btn">Ver estado del Ticket</a>
    </div>
  `;

  try {
    const info = await transporter.sendMail({
      from: defaultFrom,
      to: ticket.created_by_email,
      subject: `[Ticket #${ticket.tracking_id}] Recibido: ${ticket.title}`,
      html: getEmailTemplate('Ticket Recibido', htmlContent),
    });
    console.log(`📧 Email de creación enviado a ${ticket.created_by_email} (MsgID: ${info.messageId})`);
  } catch (error) {
    console.error('❌ Error enviando email de creación:', error);
  }
}

/**
 * Envía notificación de notificación de respuesta (comentario)
 */
async function sendTicketResponse(ticket, update, recipientEmail, recipientName) {
  if (!recipientEmail) return;

  const ticketUrl = `${BASE_URL}/track/${ticket.tracking_id}`;

  const htmlContent = `
    <h2>Nueva Actualización</h2>
    <p>Hola <strong>${recipientName}</strong>,</p>
    <p>Se ha agregado un nuevo comentario al ticket <strong>#${ticket.tracking_id}</strong>.</p>
    
    <div style="background-color: #f8fafc; padding: 15px; border-radius: 8px; border: 1px solid #e2e8f0; margin: 20px 0;">
      <p style="margin: 0; font-weight: 600; color: ${COLORS.primary}; font-size: 12px;">${update.user_name || 'Sistema'} escribió:</p>
      <p style="margin: 8px 0 0; white-space: pre-wrap; color: ${COLORS.textMain};">${update.content}</p>
    </div>

    <div style="text-align: center;">
      <a href="${ticketUrl}" class="btn">Ver conversación completa</a>
    </div>
  `;

  try {
    const info = await transporter.sendMail({
      from: defaultFrom,
      to: recipientEmail,
      subject: `[Ticket #${ticket.tracking_id}] Nueva actualización: ${ticket.title}`,
      html: getEmailTemplate('Nueva Actualización', htmlContent),
    });
    console.log(`📧 Email de respuesta enviado a ${recipientEmail} (MsgID: ${info.messageId})`);
  } catch (error) {
    console.error('❌ Error enviando email de respuesta:', error);
  }
}

/**
 * Envía notificación de cambio de estado de ticket
 */
async function sendTicketStatusChange(ticket, newStatus) {
  if (!ticket.created_by_email) return;

  const ticketUrl = `${BASE_URL}/track/${ticket.tracking_id}`;
  
  const statusMap = {
    'open': { label: 'Abierto', color: COLORS.info },
    'in-progress': { label: 'En Progreso', color: COLORS.warning },
    'closed': { label: 'Cerrado', color: COLORS.success }
  };

  const statusInfo = statusMap[newStatus] || { label: newStatus, color: COLORS.secondary };
  const isClosed = newStatus === 'closed';

  const htmlContent = `
    <h2 style="color: ${statusInfo.color}">Estado Actualizado</h2>
    <p>Hola <strong>${ticket.created_by_name}</strong>,</p>
    <p>El estado del ticket <strong>#${ticket.tracking_id}</strong> ha cambiado a:</p>
    
    <div style="text-align: center; margin: 25px 0;">
      <span style="display: inline-block; padding: 10px 20px; background-color: ${statusInfo.color}; color: #fff; border-radius: 4px; font-weight: bold; font-size: 16px;">
        ${statusInfo.label}
      </span>
    </div>
    
    <div class="info-box">
      <span class="label">Título del Ticket</span>
      <span class="value" style="margin-bottom: 0;">${ticket.title}</span>
    </div>

    ${isClosed 
      ? '<p>Esperamos haber resuelto tu solicitud satisfactoriamente. Si necesitas más ayuda, no dudes en contactarnos.</p>' 
      : '<p>Te mantendremos informado sobre cualquier novedad adicional en tu caso.</p>'}

    <div style="text-align: center;">
      <a href="${ticketUrl}" class="btn">Ver detalle del Ticket</a>
    </div>
  `;

  try {
    const info = await transporter.sendMail({
      from: defaultFrom,
      to: ticket.created_by_email,
      subject: `[Ticket #${ticket.tracking_id}] Estado Actualizado: ${statusInfo.label}`,
      html: getEmailTemplate('Estado Actualizado', htmlContent),
    });
    console.log(`📧 Email de cambio de estado (${newStatus}) enviado a ${ticket.created_by_email} (MsgID: ${info.messageId})`);
  } catch (error) {
    console.error('❌ Error enviando email de cambio de estado:', error);
  }
}

module.exports = {
  sendTicketCreated,
  sendTicketResponse,
  sendTicketStatusChange
};
