# Guía de Dockerización - Aplicación Node.js + PostgreSQL + Backups

Guía genérica para dockerizar una aplicación Node.js con base de datos PostgreSQL y sistema de backups automáticos.

---

## Variables a Personalizar

Antes de usar estos archivos, reemplaza las siguientes variables con tus valores:

| Variable               | Descripción                                    | Ejemplo          |
| ---------------------- | ---------------------------------------------- | ---------------- |
| `{{APP_NAME}}`         | Nombre del proyecto (minúsculas, sin espacios) | `miapp`          |
| `{{APP_PORT}}`         | Puerto de la aplicación                        | `3005`           |
| `{{DB_PORT_EXTERNAL}}` | Puerto externo para acceder a PostgreSQL       | `5433`           |
| `{{DB_NAME}}`          | Nombre de la base de datos                     | `mi_base_datos`  |
| `{{DB_USER}}`          | Usuario de PostgreSQL                          | `app_user`       |
| `{{DB_PASSWORD}}`      | Contraseña de PostgreSQL                       | `MiPassword123!` |
| `{{SERVER_IP}}`        | IP o dominio del servidor                      | `192.168.1.100`  |
| `{{JWT_SECRET}}`       | Clave secreta para JWT (generar una nueva)     | `abc123...`      |
| `{{BACKUP_SCHEDULE}}`  | Frecuencia de backup automático                | `@every 6h00m`   |

---

## 1. Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE {{APP_PORT}}

CMD ["npm", "start"]
```

---

## 2. docker-compose.yml

```yaml
version: "3.8"

services:
  # ==================== APLICACIÓN ====================
  app:
    build: .
    ports:
      - "{{APP_PORT}}:{{APP_PORT}}"
    depends_on:
      - db
    env_file:
      - .env
    environment:
      - DB_HOST=db
      - DB_PORT=5432
    volumes:
      - .:/app
      - /app/node_modules
    restart: always

  # ==================== BASE DE DATOS ====================
  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_USER: { { DB_USER } }
      POSTGRES_PASSWORD: { { DB_PASSWORD } }
      POSTGRES_DB: { { DB_NAME } }
    ports:
      - "{{DB_PORT_EXTERNAL}}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # ==================== BACKUPS AUTOMÁTICOS ====================
  backup:
    image: prodrigestivill/postgres-backup-local
    restart: always
    depends_on:
      - db
    links:
      - db:db
    volumes:
      - ./backups:/backups
    environment:
      - POSTGRES_HOST=db
      - POSTGRES_DB={{DB_NAME}}
      - POSTGRES_USER={{DB_USER}}
      - POSTGRES_PASSWORD={{DB_PASSWORD}}
      - SCHEDULE={{BACKUP_SCHEDULE}}
      - BACKUP_KEEP_DAYS=7
      - BACKUP_KEEP_WEEKS=4
      - BACKUP_KEEP_MONTHS=6
      - HEALTHCHECK_PORT=8080

volumes:
  postgres_data:
```

---

## 3. Archivo .env

```env
# ==================== SERVIDOR ====================
PORT={{APP_PORT}}
NODE_ENV=development

# ==================== SEGURIDAD ====================
JWT_SECRET={{JWT_SECRET}}
ALLOWED_ORIGINS=http://{{SERVER_IP}}:{{APP_PORT}}
BASE_URL=http://{{SERVER_IP}}:{{APP_PORT}}

# ==================== BASE DE DATOS ====================
# Nota: Dentro de Docker, la app usa DB_HOST=db y DB_PORT=5432
# Estas variables son para conexiones EXTERNAS (herramientas, scripts)
DB_HOST={{SERVER_IP}}
DB_PORT={{DB_PORT_EXTERNAL}}
DB_NAME={{DB_NAME}}
DB_USER={{DB_USER}}
DB_PASSWORD={{DB_PASSWORD}}

# ==================== OPCIONALES ====================
# Push Notifications (generar claves VAPID)
# VAPID_PUBLIC_KEY=
# VAPID_PRIVATE_KEY=
# VAPID_SUBJECT=mailto:tu@email.com

# SMTP
# SMTP_HOST=smtp.ejemplo.com
# SMTP_PORT=587
# SMTP_USER=usuario@ejemplo.com
# SMTP_PASS=contraseña
# EMAIL_FROM="Sistema <noreply@ejemplo.com>"
```

---

## 4. Script de Backup Manual

### Windows - `backup_now.bat`

```batch
@echo off
echo Ejecutando backup manual...
docker exec {{APP_NAME}}-backup-1 /backup.sh
echo Backup completado. Revisa la carpeta 'backups'.
pause
```

### Linux/Mac - `backup_now.sh`

```bash
#!/bin/bash
echo "Ejecutando backup manual..."
docker exec {{APP_NAME}}-backup-1 /backup.sh
echo "Backup completado. Revisa la carpeta 'backups'."
```

> **Nota:** El nombre del contenedor sigue el patrón `{{APP_NAME}}-backup-1`. Verifica el nombre exacto con `docker ps`.

---

## 5. Comandos Esenciales

```bash
# Iniciar todos los servicios
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f app
docker-compose logs -f db
docker-compose logs -f backup

# Detener servicios
docker-compose down

# Reiniciar un servicio
docker-compose restart app

# Reconstruir imagen (después de cambios en Dockerfile)
docker-compose up -d --build

# Ver contenedores activos
docker ps
```

---

## 6. Restaurar Backup

Los backups se guardan en `./backups/daily/` como archivos `.sql.gz`.

```bash
# Método 1: Descomprimir y restaurar
gunzip -c backups/daily/{{DB_NAME}}-FECHA.sql.gz | \
  docker exec -i {{APP_NAME}}-db-1 psql -U {{DB_USER}} -d {{DB_NAME}}

# Método 2: Paso a paso
gunzip -k backups/daily/{{DB_NAME}}-FECHA.sql.gz
docker cp backups/daily/{{DB_NAME}}-FECHA.sql {{APP_NAME}}-db-1:/tmp/
docker exec -it {{APP_NAME}}-db-1 psql -U {{DB_USER}} -d {{DB_NAME}} -f /tmp/{{DB_NAME}}-FECHA.sql
```

---

## 7. Acceso a la Base de Datos

### Terminal dentro del contenedor:

```bash
docker exec -it {{APP_NAME}}-db-1 psql -U {{DB_USER}} -d {{DB_NAME}}
```

### Herramientas externas (DBeaver, pgAdmin, etc.):

| Parámetro     | Valor                         |
| ------------- | ----------------------------- |
| Host          | `localhost` o `{{SERVER_IP}}` |
| Puerto        | `{{DB_PORT_EXTERNAL}}`        |
| Usuario       | `{{DB_USER}}`                 |
| Contraseña    | `{{DB_PASSWORD}}`             |
| Base de datos | `{{DB_NAME}}`                 |

---

## 8. Estructura de Carpetas

```
{{APP_NAME}}/
├── docker-compose.yml
├── Dockerfile
├── .env
├── backup_now.bat          # Windows
├── backup_now.sh           # Linux/Mac
├── backups/
│   └── daily/
│       └── {{DB_NAME}}-YYYY-MM-DDTHH-MM-SS.sql.gz
├── package.json
├── server.js               # O tu archivo principal
└── ...
```

---

## 9. Generar JWT_SECRET

Para generar una clave segura para JWT:

```bash
# Node.js
node -e "console.log(require('crypto').randomBytes(64).toString('base64'))"

# OpenSSL
openssl rand -base64 64

# PowerShell
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Maximum 256 }))
```

---

## 10. Opciones de BACKUP_SCHEDULE

| Formato         | Descripción                             |
| --------------- | --------------------------------------- |
| `@every 1h00m`  | Cada hora                               |
| `@every 6h00m`  | Cada 6 horas                            |
| `@every 12h00m` | Cada 12 horas                           |
| `@daily`        | Una vez al día (medianoche)             |
| `@weekly`       | Una vez por semana (domingo medianoche) |
| `0 2 * * *`     | Formato cron: 2:00 AM diario            |

---

## 11. Checklist de Producción

- [ ] Cambiar todas las contraseñas por defecto
- [ ] Generar nuevo `JWT_SECRET`
- [ ] Cambiar `NODE_ENV=production`
- [ ] Configurar HTTPS (reverse proxy: nginx, traefik, caddy)
- [ ] Remover volumen de código (`.:/app`) y usar solo imagen
- [ ] Configurar firewall para exponer solo puertos necesarios
- [ ] Configurar dominio y DNS
- [ ] Habilitar logs persistentes
- [ ] Probar restauración de backup

---

## Ejemplo Completo Personalizado

Si tu aplicación se llama `mitienda`, estos serían los valores:

```
{{APP_NAME}} = mitienda
{{APP_PORT}} = 3000
{{DB_PORT_EXTERNAL}} = 5434
{{DB_NAME}} = mitienda_db
{{DB_USER}} = tienda_user
{{DB_PASSWORD}} = TiendaSecreta2024!
{{SERVER_IP}} = 192.168.1.50
{{BACKUP_SCHEDULE}} = @daily
```

Y el contenedor de backup sería: `mitienda-backup-1`

---

_Plantilla genérica para dockerización de aplicaciones Node.js + PostgreSQL_
