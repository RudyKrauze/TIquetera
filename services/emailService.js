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
 * Escapa caracteres especiales HTML para prevenir XSS en correos electrónicos
 */
function escapeHtml(value) {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Limpia encabezados/asuntos para evitar inyección de cabeceras CRLF
 */
function sanitizeSubjectText(value, maxLen = 120) {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/[\r\n\t]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, maxLen);
}

/**
 * Función auxiliar para generar el wrapper HTML común
 */
function getEmailTemplate(title, content) {
  const safeTitle = escapeHtml(title || 'Sistema de Tickets');
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${safeTitle}</title>
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
 * Construye el HTML seguro del email de creación de ticket
 */
function buildTicketCreatedHtml(ticket) {
  const safeTrackingId = escapeHtml(ticket.tracking_id || '');
  const safeName = escapeHtml(ticket.created_by_name || '');
  const safeTitle = escapeHtml(ticket.title || '');
  const safeDepartment = escapeHtml(ticket.department || '');
  const safeSede = escapeHtml(ticket.sede || 'No especificada');
  const rawPriority = String(ticket.priority || 'medium');
  const safePriority = escapeHtml(rawPriority.charAt(0).toUpperCase() + rawPriority.slice(1));
  const safeDescription = escapeHtml(ticket.description || '');
  const ticketUrl = `${BASE_URL}/track/${encodeURIComponent(ticket.tracking_id || '')}`;

  const htmlContent = `
    <h2>¡Ticket Recibido!</h2>
    <p>Hola <strong>${safeName}</strong>,</p>
    <p>Hemos recibido tu solicitud correctamente. Nuestro equipo ya ha sido notificado y comenzará a trabajar en ello pronto.</p>
    
    <div class="info-box">
      <span class="label">ID de Seguimiento</span>
      <span class="value" style="font-size: 18px; font-family: monospace;">${safeTrackingId}</span>
      
      <span class="label">Título</span>
      <span class="value">${safeTitle}</span>
      
      <span class="label">Departamento</span>
      <span class="value">${safeDepartment}</span>
      
      <span class="label">Sede</span>
      <span class="value">${safeSede}</span>
      
      <span class="label">Prioridad</span>
      <span class="value" style="margin-bottom: 0;">${safePriority}</span>
    </div>

    <p style="font-size: 14px; border-left: 2px solid #e2e8f0; padding-left: 10px; color: ${COLORS.textMuted}; white-space: pre-wrap;">
      &ldquo;${safeDescription}&rdquo;
    </p>

    <div style="text-align: center;">
      <a href="${escapeHtml(ticketUrl)}" class="btn">Ver estado del Ticket</a>
    </div>
  `;

  return getEmailTemplate('Ticket Recibido', htmlContent);
}

/**
 * Envía un correo de confirmación al crear un ticket
 * @param {Object} ticket - Objeto del ticket creado
 */
async function sendTicketCreated(ticket) {
  if (!ticket || !ticket.created_by_email) return;

  try {
    const safeSubjectTracking = sanitizeSubjectText(ticket.tracking_id, 40);
    const safeSubjectTitle = sanitizeSubjectText(ticket.title, 120);
    const info = await transporter.sendMail({
      from: defaultFrom,
      to: ticket.created_by_email,
      subject: `[Ticket #${safeSubjectTracking}] Recibido: ${safeSubjectTitle}`,
      html: buildTicketCreatedHtml(ticket),
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

  const ticketUrl = `${BASE_URL}/track/${encodeURIComponent(ticket.tracking_id || '')}`;
  const safeRecipientName = escapeHtml(recipientName || '');
  const safeTrackingId = escapeHtml(ticket.tracking_id || '');
  const safeAuthor = escapeHtml((update && update.user_name) || 'Sistema');
  const safeContent = escapeHtml((update && update.content) || '');

  const htmlContent = `
    <h2>Nueva Actualización</h2>
    <p>Hola <strong>${safeRecipientName}</strong>,</p>
    <p>Se ha agregado un nuevo comentario al ticket <strong>#${safeTrackingId}</strong>.</p>
    
    <div style="background-color: #f8fafc; padding: 15px; border-radius: 8px; border: 1px solid #e2e8f0; margin: 20px 0;">
      <p style="margin: 0; font-weight: 600; color: ${COLORS.primary}; font-size: 12px;">${safeAuthor} escribió:</p>
      <p style="margin: 8px 0 0; white-space: pre-wrap; color: ${COLORS.textMain};">${safeContent}</p>
    </div>

    <div style="text-align: center;">
      <a href="${escapeHtml(ticketUrl)}" class="btn">Ver conversación completa</a>
    </div>
  `;

  try {
    const safeSubjectTracking = sanitizeSubjectText(ticket.tracking_id, 40);
    const safeSubjectTitle = sanitizeSubjectText(ticket.title, 120);
    const info = await transporter.sendMail({
      from: defaultFrom,
      to: recipientEmail,
      subject: `[Ticket #${safeSubjectTracking}] Nueva actualización: ${safeSubjectTitle}`,
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
  if (!ticket || !ticket.created_by_email) return;

  const ticketUrl = `${BASE_URL}/track/${encodeURIComponent(ticket.tracking_id || '')}`;
  
  const statusMap = {
    'open': { label: 'Abierto', color: COLORS.info },
    'in-progress': { label: 'En Progreso', color: COLORS.warning },
    'closed': { label: 'Cerrado', color: COLORS.success }
  };

  const statusInfo = statusMap[newStatus] || { label: newStatus, color: COLORS.secondary };
  const isClosed = newStatus === 'closed';
  const safeName = escapeHtml(ticket.created_by_name || '');
  const safeTrackingId = escapeHtml(ticket.tracking_id || '');
  const safeTitle = escapeHtml(ticket.title || '');
  const safeStatusLabel = escapeHtml(statusInfo.label || '');

  const htmlContent = `
    <h2 style="color: ${statusInfo.color}">Estado Actualizado</h2>
    <p>Hola <strong>${safeName}</strong>,</p>
    <p>El estado del ticket <strong>#${safeTrackingId}</strong> ha cambiado a:</p>
    
    <div style="text-align: center; margin: 25px 0;">
      <span style="display: inline-block; padding: 10px 20px; background-color: ${statusInfo.color}; color: #fff; border-radius: 4px; font-weight: bold; font-size: 16px;">
        ${safeStatusLabel}
      </span>
    </div>
    
    <div class="info-box">
      <span class="label">Título del Ticket</span>
      <span class="value" style="margin-bottom: 0;">${safeTitle}</span>
    </div>

    ${isClosed 
      ? '<p>Esperamos haber resuelto tu solicitud satisfactoriamente. Si necesitas más ayuda, no dudes en contactarnos.</p>' 
      : '<p>Te mantendremos informado sobre cualquier novedad adicional en tu caso.</p>'}

    <div style="text-align: center;">
      <a href="${escapeHtml(ticketUrl)}" class="btn">Ver detalle del Ticket</a>
    </div>
  `;

  try {
    const safeSubjectTracking = sanitizeSubjectText(ticket.tracking_id, 40);
    const safeSubjectStatus = sanitizeSubjectText(statusInfo.label, 40);
    const info = await transporter.sendMail({
      from: defaultFrom,
      to: ticket.created_by_email,
      subject: `[Ticket #${safeSubjectTracking}] Estado Actualizado: ${safeSubjectStatus}`,
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
  sendTicketStatusChange,
  buildTicketCreatedHtml,
  escapeHtml
};
