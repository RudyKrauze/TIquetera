@echo off
echo Triggering manual backup...
docker exec tickethtml-backup-1 /backup.sh
echo Backup process initialized. Check the 'backups' folder.
pause
