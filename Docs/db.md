## Crear la BD vacía (si es necesario):

createdb -U ticket_app tiquetera_db

## Restaurar:

psql -U ticket_app -d tiquetera_db -f backup_tiquetera.sql

## En resumen: tu backup es bueno para migrar o restaurar la aplicación.