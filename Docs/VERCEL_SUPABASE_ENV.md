# 🚀 Guía de Variables de Entorno de Producción (Vercel + Supabase)

Esta guía detalla todas las variables de entorno necesarias para desplegar el proyecto **TIquetera** en **Vercel** conectado a la base de datos PostgreSQL de **Supabase**.

---

## 📋 Bloque Listo para Copiar y Pegar en Vercel

En el panel de **Vercel** (`Settings -> Environment Variables`), selecciona el botón **"Environment Variables"** -> **"Paste .env"** y pega el siguiente bloque:

```env
# ==========================================
# ENTORNO Y SERVIDOR
# ==========================================
NODE_ENV=production
BASE_URL=https://tu-app-tiquetera.vercel.app
ALLOWED_ORIGINS=https://tu-app-tiquetera.vercel.app

# ==========================================
# SEGURIDAD (JWT Y CREDENCIALES DE ADMIN)
# ==========================================
# Reemplazar con una clave aleatoria de 64 o 128 caracteres
JWT_SECRET=gOHPWPWmn5wn4rRHSKBAQ7fwFFI3QJ21CvuhV3UM7M7ABgW78AYb6CsmEympi9/oP+iO4TnMs6XVX+7+N292xQ==
ADMIN_EMAIL=admin@tiquetera.com
ADMIN_PASSWORD=admin123

# ==========================================
# BASE DE DATOS (SUPABASE TRANSACTION POOLER)
# ==========================================
# Obtener de Supabase: Settings -> Database -> Connection string -> Connection pooling (Transaction / Puerto 6543)
DATABASE_URL=postgresql://postgres.[PROJ_REF]:[TU_PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true
DB_SSL=true
DB_POOL_MAX=5

# ==========================================
# NOTIFICACIONES PUSH (VAPID KEYS)
# ==========================================
VAPID_PUBLIC_KEY=BIIEIYnOFClKHR4iTGOH0h-Wxzpz7_8ErCrg_lhtrdGtwco-GNnEGlyiwESVpQjinZhvqiRstswKob5J0RRQjZI
VAPID_PRIVATE_KEY=gEU58CmXpcm_FW2Z2M8WhqTHKv3RdQVK3EPfPsfnAog
VAPID_SUBJECT=mailto:soporte@tu-dominio.com

# ==========================================
# NOTIFICACIONES POR CORREO (SMTP)
# ==========================================
SMTP_HOST=mail.tu-dominio.com
SMTP_PORT=587
SMTP_USER=notificaciones@tu-dominio.com
SMTP_PASS=TuPasswordSMTP123!
EMAIL_FROM="Sistema de Tickets <noreply@tu-dominio.com>"
```

---

## 🛠️ Detalle de Variables y Cómo Obtenerlas

### 1. Base de Datos Supabase (`DATABASE_URL`)
* **¿Por qué puerto 6543?**: En arquitectura serverless (Vercel Node.js Functions), cada invocación abre/cierra conexiones de forma efímera. Supabase ofrece **PgBouncer (Transaction Pooler)** en el puerto `6543`.
* **Dónde encontrarla en Supabase**:
  1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard).
  2. Haz clic en **Project Settings** (⚙️) -> **Database**.
  3. En la sección **Connection string**, selecciona el tab **URI**.
  4. Selecciona la opción **Connection pooling** y el modo **Transaction** (Puerto `6543`).
  5. Copia la cadena y asegúrate de agregar `?pgbouncer=true` al final si no lo incluye.

### 2. Seguridad JWT (`JWT_SECRET`)
* Es la firma secreta para validar los tokens de sesión de los usuarios.
* Para generar una clave segura desde la terminal (PowerShell o Bash), ejecuta:
  ```bash
  node -e "console.log(require('crypto').randomBytes(64).toString('base64'))"
  ```

### 3. URL del Sitio (`BASE_URL` / `ALLOWED_ORIGINS`)
* Reemplaza `https://tu-app-tiquetera.vercel.app` por el dominio real que Vercel le asigne a tu proyecto o por tu dominio personalizado (ej. `https://tickets.midominio.com`).

### 4. Notificaciones Web Push (`VAPID_*`)
* Permiten enviar notificaciones emergentes en el navegador (Service Workers).
* Si deseas generar un nuevo par de llaves VAPID en produccion:
  ```bash
  npx web-push generate-vapid-keys
  ```

### 5. Envío de Emails (`SMTP_*`)
* Configura los datos del servidor de correo saliente.
* Para servidores seguros estándar se recomienda `SMTP_PORT=587` (TLS) o `465` (SSL).

---

## ⚙️ Pasos para Configurar en Vercel

1. Entra a tu panel en [Vercel Dashboard](https://vercel.com/dashboard).
2. Selecciona tu proyecto (`TIquetera` o `TicketHTML`).
3. Ve a **Settings** -> **Environment Variables**.
4. Haz clic en **Paste .env** y pega las variables anteriores personalizadas.
5. Selecciona los entornos deseados:
   - ✅ **Production**
   - ✅ **Preview** (para ramas de test)
   - ✅ **Development** (si usas `vercel dev`)
6. Presiona **Save**.
7. Si el proyecto ya fue desplegado previamente, ve a **Deployments** -> **Redeploy** para aplicar los cambios de variables.
