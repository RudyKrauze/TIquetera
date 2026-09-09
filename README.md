# 🎫 Sistema de Gestión de Tickets y Mantenimiento

Sistema corporativo de gestión de tickets de soporte, checklist preventivo, seguimiento en tiempo real, tableros compartidos y notificaciones para múltiples áreas (Sistemas, Mantenimiento, RRHH, Compras, Gerencia y Administración).

---

## 🏛️ Arquitectura Dual y Coexistencia (Docker ↔ Supabase / Vercel)

El proyecto está diseñado bajo un modelo de **código único compatible con dos entornos de despliegue en paralelo**:

```
                                  ┌──────────────────────────────────────────────┐
                                  │                CÓDIGO BASE                   │
                                  │ (server.js, db_init.js, /public, /private)   │
                                  └───────┬──────────────────────────────┬───────┘
                                          │                              │
                   ┌──────────────────────┴──────┐                ┌──────┴──────────────────────┐
                   │   ENTORNO A: LOCAL / ON-PREM│                │   ENTORNO B: CLOUD / VERCEL │
                   │       (Docker Compose)      │                │       + SUPABASE            │
                   └──────────────┬──────────────┘                └──────────────┬──────────────┘
                                  │                                              │
              ┌───────────────────┼──────────────────┐        ┌──────────────────┼──────────────────┐
              ▼                   ▼                  ▼        ▼                  ▼                  ▼
       [Node.js Server]    [PostgreSQL 16]   [Disco Local]   [Vercel Serverless] [Supabase DB 6543] [Supa Storage]
       Puerto: 3005        Puerto: 5433/5432 /uploads/...    api/index.js        Transaction Pooler Bucket 'ticket-attachments'
       WebSockets: OK      Backup cron local WebSockets: -    SSL obligatorio    URLs públicas
```

### Tabla Comparativa de Ambientes

| Componente / Característica | Entorno On-Prem / Local (Docker) | Entorno Cloud (Vercel + Supabase) |
| :--- | :--- | :--- |
| **Motor de Ejecución** | Contenedor Node 18 (`docker-compose`) | Serverless Functions (`api/index.js`) |
| **Base de Datos** | PostgreSQL 16 local (`db:5432` / host `5433`) | Supabase PostgreSQL (`aws-0-*.pooler.supabase.com`) |
| **Modo de Conexión DB** | Conexión directa por variables discretas (`DB_HOST`, `DB_PORT`) | Connection Pooler URI (`DATABASE_URL`, pgbouncer en port 6543) |
| **Almacenamiento de Adjuntos** | Disco local (`/public/uploads/tickets`) | Supabase Storage (`bucket: ticket-attachments`) |
| **Tiempo Real** | WebSockets bidireccionales (`socket.io`) | Notificaciones Push Web (VAPID) / Polling REST |
| **Inicialización de Tablas** | `db_init.js` al arranque del contenedor | `db_init.js` bajo demanda vía promesa singleton |
| **Backups** | Servicio `backup` en Compose (cada 6h a `./backups`) | Backups automatizados en Supabase Dashboard |

---

## ⚡ Regla de Oro: Cómo Mantener Cambios Compatibles en Ambos Ambientes

Para que cualquier funcionalidad, corrección o mejora opere transparentemente en Docker y en Supabase/Vercel, debes respetar las siguientes directrices:

### 1. Consultas y Esquemas de Base de Datos
- **Sintaxis PostgreSQL Pura**: Utiliza siempre sintaxis ANSI/PostgreSQL estándar (`$1, $2`, `jsonb`, `CURRENT_TIMESTAMP`).
- **Migraciones Idempotentes**: Todo script o cambio en `db_schema.sql` y `db_init.js` debe usar `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS` y `CREATE INDEX IF NOT EXISTS`.
- **Zonas Horarias**: El backend fuerza `America/Argentina/Buenos_Aires` (UTC-3). Usa `TIMESTAMP` o funciones estándar como `NOW()`.
- **Pool de Conexiones**: No abras clientes manuales sin liberarlos. Usa siempre `pool.query(...)`.

### 2. Manejo de Archivos e Imágenes (Multer / Storage)
- **Nunca asumas que el disco es persistente**: Vercel ejecuta en un sistema de archivos de solo lectura (`/tmp` efímero).
- `server.js` detecta automáticamente si existen credenciales de Supabase:
  - Si existen `SUPABASE_URL` y `SUPABASE_KEY`: Los archivos se reciben en **memoria** (`multer.memoryStorage()`) y se suben directo al bucket `tickets` de Supabase Storage.
  - Si no existen: Multer escribe en disco (`public/uploads/tickets`).
- Al generar URLs de adjuntos, usa siempre la ruta relativa `/uploads/tickets/...` para local o la URL pública de Supabase Storage.

### 3. Resolución de Vistas y Assets
- Nunca uses rutas relativas fijas como `./private/support.html`.
- Utiliza la función helper `resolveView(folder, filename)` implementada en `server.js` que verifica `process.cwd()` y `__dirname` para funcionar tanto en Docker como en los empaquetados Serverless de Vercel.

### 4. Soporte Serverless vs Servidor Continuo
- En Docker/Local, el servidor inicia con `server.listen(...)` y habilita `socket.io`.
- En Vercel (`process.env.VERCEL` presente), `server.js` **no** ejecuta `server.listen()`; en su lugar exporta `module.exports = app` para ser consumido por `api/index.js`.
- Las funciones críticas no deben depender exclusivamente de WebSockets; deben disponer de fallback por HTTP REST para que Vercel responda con el 100% de la funcionalidad.

---

## 📁 Estructura del Repositorio

```text
├── api/
│   └── index.js              # Entrypoint Serverless para Vercel
├── private/                  # Vistas protegidas por sesión/roles
│   ├── administrador.html    # Panel de administración general
│   ├── compras.html          # Panel de compras e insumos
│   ├── gerencia.html         # Panel directivo y métricas
│   ├── mantenimiento.html    # Tareas preventivas y checklist
│   ├── notificaciones.html   # Centro de avisos y web push
│   ├── reportes.html         # Análisis estadístico avanzado
│   ├── rrhh.html             # Panel de recursos humanos
│   └── support.html          # Mesa de ayuda de sistemas
├── public/                   # Archivos estáticos y públicos
│   ├── css/                  # Hojas de estilo modulares
│   ├── js/                   # Lógica frontend (support, mant, etc.)
│   ├── index.html            # Portal de ingreso / Login
│   ├── track.html            # Consulta de ticket por tracking ID
│   ├── tareas-publico.html   # Tablero compartido de mantenimiento
│   └── reporte-publico.html  # Reportes compartidos con token
├── services/
│   └── emailService.js       # Notificaciones por correo SMTP
├── db_init.js                # Inicializador de tablas y usuarios semilla
├── db_schema.sql             # Definición canónica del esquema SQL
├── docker-compose.yml        # Orquestación de App + Postgres + Backups
├── Dockerfile                # Imagen Docker de Node.js
├── server.js                 # API Express, middlewares y lógica principal
├── vercel.json               # Configuración de rutas y rewrites de Vercel
├── .env.example              # Plantilla documentada de variables de entorno
└── README.md                 # Este documento
```

---

## 🚀 Despliegue y Ejecución

### Opción 1: Entorno Docker (Local / On-Premise)

1. **Configurar el archivo `.env`**:
   Copia el archivo de ejemplo:
   ```bash
   cp .env.example .env
   ```
   Asegúrate de configurar los parámetros locales:
   ```ini
   PORT=3005
   NODE_ENV=development
   JWT_SECRET=tu_clave_secreta_jwt
   ALLOWED_ORIGINS=http://localhost:3005,http://192.168.2.41:3005
   BASE_URL=http://localhost:3005

   # Conexión directa a PostgreSQL dentro de la red Docker
   DB_HOST=db
   DB_PORT=5432
   DB_NAME=tiquetera_db
   DB_USER=ticket_app
   DB_PASSWORD=TicketApp123!
   DB_SSL=false
   ```

2. **Iniciar contenedores**:
   ```bash
   docker-compose up -d --build
   ```

3. **Verificar estado y logs**:
   ```bash
   docker-compose ps
   docker-compose logs -f app
   ```

4. **Acceso al sistema**:
   - Aplicación: `http://localhost:3005`
   - Base de Datos accesible desde el host: puerto `5433`

---

### Opción 2: Entorno Cloud (Vercel + Supabase)

1. **Preparar Supabase**:
   - En el **SQL Editor** de Supabase:
     - Si vas a **migrar los datos reales existentes en Docker**: ejecuta el archivo generado `supabase_migration.sql` (contiene las 12 tablas, secuencias, usuarios, tickets y tareas).
     - Si vas a iniciar una **base de datos desde cero**: ejecuta el archivo `db_schema.sql`.
   - En **Storage**, crea un bucket público llamado `ticket-attachments` (con acceso público de lectura para que las imágenes se visualicen en los tickets).
   - En **Settings -> Database**, copia la Connection String en modo **Transaction Pooler** (puerto `6543`) con SSL habilitado.

2. **Configurar Variables de Entorno en Vercel**:
   En el dashboard del proyecto en Vercel (*Settings -> Environment Variables*), carga:

   | Variable | Valor / Descripción |
   | :--- | :--- |
   | `DATABASE_URL` | `postgresql://postgres.[REF]:[PASS]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true` |
   | `DB_SSL` | `true` |
   | `DB_POOL_MAX` | `5` *(Límite recomendado para Vercel Serverless)* |
   | `SUPABASE_URL` | `https://[REF].supabase.co` |
   | `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGciOi...` *(Para gestionar Storage y permisos)* |
   | `JWT_SECRET` | Generado con `openssl rand -base64 64` |
   | `ALLOWED_ORIGINS` | `https://tu-dominio.vercel.app` |
   | `BASE_URL` | `https://tu-dominio.vercel.app` |
   | `NODE_ENV` | `production` |
   | `VAPID_PUBLIC_KEY` | Tu clave pública Web Push |
   | `VAPID_PRIVATE_KEY` | Tu clave privada Web Push |
   | `SMTP_HOST`, `SMTP_USER`, etc. | Credenciales de tu proveedor de correo |

3. **Desplegar en Vercel**:
   ```bash
   vercel --prod
   ```
   El archivo `vercel.json` se encarga de dirigir todas las rutas hacia `api/index.js` y de incluir los directorios `private/` y `public/`.

---

## 👥 Usuarios por Defecto (Semilla Inicial)

Al inicializarse una base de datos limpia, `db_init.js` creará las siguientes cuentas administrativas básicas:

| Rol / Departamento | Correo Electrónico | Contraseña Predeterminada |
| :--- | :--- | :--- |
| **Administrador** | `admin@tiquetera.com` | `admin123` *(configurable vía `DEFAULT_ADMIN_PASSWORD`)* |
| **Sistemas** | `soporte@tiquetera.com` | `support123` *(configurable vía `DEFAULT_SUPPORT_PASSWORD`)* |
| **Recursos Humanos** | `rrhh@tiquetera.com` | `rrhh123` *(configurable vía `DEFAULT_RRHH_PASSWORD`)* |
| **Mantenimiento** | `mantenimiento@tiquetera.com` | `mant123` *(configurable vía `DEFAULT_MANT_PASSWORD`)* |
| **Compras e Insumos** | `compras@tiquetera.com` | `compras123` *(configurable vía `DEFAULT_COMPRAS_PASSWORD`)* |

> ⚠️ **Importante**: Cambia las contraseñas inmediatamente al desplegar en producción desde el panel de Administración.

---

## 🔄 Flujo de Trabajo para Nuevas Funcionalidades

Cuando agregues nuevas pantallas, campos en la base de datos o lógica de negocio:

1. **¿Modificaste la base de datos?**
   - Agrega la sentencia con `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` en `db_schema.sql`.
   - Si requiere migración de datos, inclúyela también en `db_init.js` para que se aplique automáticamente tanto al levantar el contenedor de Docker como al ejecutarse la primera petición en Vercel.
2. **¿Añadiste una nueva vista HTML?**
   - Si es privada, ubícala en `private/` y sírvela usando `resolveView('private', 'nombre.html')`.
   - Verifica que `vercel.json` contenga la ruta en `includeFiles` (por defecto `private/**,public/**,db_schema.sql`).
3. **¿Probaste en local?**
   - Reinicia el contenedor para verificar el arranque:
     ```bash
     docker-compose restart app
     ```
   - Corre una verificación de sintaxis rápida:
     ```bash
     node --check server.js
     ```
