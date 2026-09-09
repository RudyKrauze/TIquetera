# Guía de Despliegue en Producción: Vercel + Supabase

Esta guía detalla los pasos exactos para poner en producción el sistema de **Tiquetera** utilizando **Supabase** como base de datos PostgreSQL y almacenamiento de archivos, y **Vercel** como plataforma de hosting Serverless.

---

## 1. Configuración de Supabase

### 1.1 Crear Proyecto en Supabase
1. Ingresa a [supabase.com](https://supabase.com) e inicia sesión o crea una cuenta.
2. Haz clic en **New project**.
3. Asigna un nombre (ej. `tiquetera-prod`), una contraseña segura para la base de datos y selecciona la región más cercana a tus usuarios (ej. `sa-east-1` São Paulo).
4. Espera 1-2 minutos a que el proyecto termine de aprovisionarse.

### 1.2 Ejecutar el Esquema de Base de Datos
1. En el menú lateral izquierdo de Supabase, ve a **SQL Editor**.
2. Haz clic en **New query**.
3. Copia y pega el contenido íntegro del archivo [`supabase/schema.sql`](file:///c:/Coding/TicketHTML/supabase/schema.sql).
4. Haz clic en **Run** (o presiona `Ctrl + Enter`).
5. Verifica que todas las tablas, índices y el bucket `ticket-attachments` se hayan creado exitosamente.

### 1.3 Obtener Credenciales de Supabase
En el panel de tu proyecto Supabase:
1. **Cadena de Conexión (DATABASE_URL):**
   - Ve a **Project Settings** (ícono de engranaje) -> **Database**.
   - En la sección **Connection string**, selecciona la pestaña **URI**.
   - Selecciona el modo **Transaction** (puerto `6543`) con `pgbouncer=true`.
   - Copia la URL. Tendrá el formato:
     ```
     postgresql://postgres.[PROJECT_REF]:[TU_PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true
     ```
   *(Reemplaza `[TU_PASSWORD]` por la contraseña que creaste en el paso 1.1)*.

2. **API Keys y URL del Proyecto:**
   - Ve a **Project Settings** -> **API**.
   - Copia la **Project URL** (ej. `https://xyzcompany.supabase.co`).
   - Copia la clave **anon / public**.
   - Copia la clave **service_role** (secreta, usada por el backend para subida segura de adjuntos).

---

## 2. Despliegue en Vercel

### Opción A: Despliegue mediante GitHub (Recomendado)
1. Sube tu repositorio a GitHub (ej. privado o de organización).
2. Ingresa a [vercel.com](https://vercel.com) y haz clic en **Add New...** -> **Project**.
3. Importa el repositorio de la Tiquetera.
4. En **Framework Preset**, selecciona **Other** (la configuración la gestionará automáticamente `vercel.json` y `api/index.js`).
5. En la sección **Environment Variables**, agrega las variables detalladas en la sección 3 de esta guía.
6. Haz clic en **Deploy**.

### Opción B: Despliegue mediante Vercel CLI
Si prefieres desplegar directamente desde la terminal:
```bash
# 1. Instalar Vercel CLI globalmente (si no lo tienes)
npm i -g vercel

# 2. Iniciar sesión en Vercel
vercel login

# 3. Vincular y desplegar en producción
vercel --prod
```

---

## 3. Variables de Entorno en Vercel

Configura las siguientes variables en **Project Settings** -> **Environment Variables** en el panel de Vercel:

| Variable | Descripción | Ejemplo / Valor |
| :--- | :--- | :--- |
| `NODE_ENV` | Entorno de ejecución | `production` |
| `DATABASE_URL` | URI del Transaction Pooler de Supabase | `postgresql://postgres.[REF]:[PASS]@aws-0-[REG].pooler.supabase.com:6543/postgres?pgbouncer=true` |
| `DB_SSL` | Activa SSL para PostgreSQL | `true` |
| `DB_POOL_MAX` | Límite de conexiones del pool serverless | `5` |
| `SUPABASE_URL` | URL de tu proyecto Supabase | `https://[PROJECT_REF].supabase.co` |
| `SUPABASE_ANON_KEY` | Clave anónima pública de Supabase | `eyJhbGci...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Clave de servicio de Supabase | `eyJhbGci...` |
| `JWT_SECRET` | Clave secreta para firmar sesiones | `Cadena_Larga_Y_Aleatoria_64_Caracteres` |
| `ALLOWED_ORIGINS` | Orígenes permitidos para CORS | `https://tu-proyecto.vercel.app` |
| `BASE_URL` | URL pública de tu aplicación | `https://tu-proyecto.vercel.app` |
| `SMTP_HOST` | Servidor SMTP de correo | `smtp-relay.brevo.com` |
| `SMTP_PORT` | Puerto SMTP | `587` |
| `SMTP_USER` | Usuario SMTP | `tu_correo@tudominio.com` |
| `SMTP_PASS` | Contraseña SMTP | `tu_contraseña_smtp` |
| `EMAIL_FROM` | Remitente de los correos | `"Soporte Tiquetera <no-reply@tiquetera.com>"` |
| `VAPID_PUBLIC_KEY` | Clave pública Web Push | *(Obtenida de tu .env actual)* |
| `VAPID_PRIVATE_KEY` | Clave privada Web Push | *(Obtenida de tu .env actual)* |
| `VAPID_SUBJECT` | Correo de contacto VAPID | `mailto:admin@tiquetera.com` |

---

## 4. Usuarios Iniciales por Defecto

Una vez ejecutado el script en Supabase o inicializada la base de datos, los usuarios predeterminados son:

| Rol | Correo Electrónico | Contraseña por Defecto |
| :--- | :--- | :--- |
| **Administrador** | `admin@tiquetera.com` | `admin123` |
| **Sistemas / Soporte** | `soporte@tiquetera.com` | `support123` |
| **Recursos Humanos** | `rrhh@tiquetera.com` | `rrhh123` |
| **Mantenimiento** | `mantenimiento@tiquetera.com` | `mant123` |
| **Compras e Insumos** | `compras@tiquetera.com` | `compras123` |

> [!WARNING]
> **Seguridad:** En el primer inicio de sesión en producción, cambia inmediatamente las contraseñas de todos los usuarios predeterminados desde el panel de administración.

---

## 5. Verificación de Producción

Una vez desplegada la aplicación en `https://tu-proyecto.vercel.app`:

1. **Prueba de Carga Inicial:** Ingresa a la URL raíz y verifica que cargue la interfaz pública para emitir tickets.
2. **Prueba de Inicio de Sesión:** Accede con `admin@tiquetera.com` y verifica que el middleware de sesión y redirección funcione correctamente.
3. **Prueba de Creación de Tickets con Adjuntos:**
   - Crea un ticket de prueba adjuntando una o más fotos.
   - Accede a la URL de seguimiento `https://tu-proyecto.vercel.app/track/TKT-...` y verifica que las fotos carguen directamente desde el Storage público de Supabase.
4. **Prueba de Tableros Públicos de Tareas y Reportes:**
   - Genera un enlace público en Mantenimiento (`/tareas/publico/...`) y en Reportes (`/reportes/publico/...`) y comprueba que carguen sin necesidad de autenticación.
