
## Restaurar `backup_tiquetera` dentro de Docker

> Estos pasos asumen que tienes Docker Desktop en Windows y que los archivos `backup_tiquetera.dump` (formato custom) y `backup_tiquetera.sql` (plaintext) están en la raíz del repo.

### 1. Crear el contenedor PostgreSQL

> El carácter `^` solo funciona como continuador de línea en **CMD** (o Git Bash). PowerShell no lo interpreta igual y mostrará `-e no se reconoce...`. Usa el formato que corresponda:

**CMD / Git Bash**

```cmd
docker run -d --name tiquetera-db ^
  -e POSTGRES_DB=tiquetera_db ^
  -e POSTGRES_USER=ticket_app ^
  -e POSTGRES_PASSWORD=tu_password_segura ^
  -p 5432:5432 ^
  postgres:18
```

**PowerShell (una sola línea)**

```powershell
docker run -d --name tiquetera-db -e POSTGRES_DB=tiquetera_db -e POSTGRES_USER=ticket_app -e POSTGRES_PASSWORD=tu_password_segura -p 5432:5432 postgres:18
```

**PowerShell (multilínea con backtick)**

```powershell
docker run -d --name tiquetera-db `
  -e POSTGRES_DB=tiquetera_db `
  -e POSTGRES_USER=ticket_app `
  -e POSTGRES_PASSWORD=tu_password_segura `
  -p 5432:5432 `
  postgres:18
```

> Cambia `POSTGRES_PASSWORD` y el puerto externo si ya usas PostgreSQL local.

### 2. Copiar el backup dentro del contenedor

```powershell
docker cp backup_tiquetera.dump tiquetera-db:/tmp/backup_tiquetera.dump
docker cp backup_tiquetera.sql tiquetera-db:/tmp/backup_tiquetera.sql
```

### 3. Restaurar el backup

#### Opción A – Usar el `.dump` (pg_restore)

```powershell
docker exec -it tiquetera-db bash -c "pg_restore -U ticket_app -d tiquetera_db /tmp/backup_tiquetera.dump"
```

#### Opción B – Usar el `.sql` (psql)

```powershell
docker exec -it tiquetera-db bash -c "psql -U ticket_app -d tiquetera_db -f /tmp/backup_tiquetera.sql"
```

### 4. Verificar tablas / roles

```powershell
docker exec -it tiquetera-db psql -U ticket_app -d tiquetera_db -c "\dt"
```

Si la app usa otro usuario (por ejemplo `postgres`), crea el rol y otorga permisos:

```powershell
docker exec -it tiquetera-db psql -U ticket_app -d postgres -c "CREATE ROLE postgres LOGIN PASSWORD 'tu_password_postgres';"
docker exec -it tiquetera-db psql -U ticket_app -d tiquetera_db -c "GRANT ALL ON DATABASE tiquetera_db TO postgres;"
```

### 5. Configurar la aplicación

En `.env`, usa `DB_HOST=localhost`, `DB_PORT=5432`, `DB_NAME=tiquetera_db`, `DB_USER` y `DB_PASSWORD` con los valores definidos en el contenedor. Luego inicia la app con el script habitual (`npm start`, `node server.js`, etc.).
