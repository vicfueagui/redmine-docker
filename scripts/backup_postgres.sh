#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# backup_postgres.sh  –  Copia de seguridad de la base de datos Redmine
#
# Guarda un dump en formato personalizado (-F c) dentro de ~/Documents/redmine-docker/postgres-backup
# Nombre de archivo:  redmine_YYYYMMDD_HHMMSS.dump.gz
#
# Requisitos:
#   • Contenedor postgres: redmine_postgres
#   • Variables de entorno heredadas de docker-compose (.env o export en shell)
#     POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
# -----------------------------------------------------------------------------
set -e

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/postgres-backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILE="$BACKUP_DIR/redmine_${TIMESTAMP}.dump.gz"

mkdir -p "$BACKUP_DIR"

echo "[INFO] Generando backup en $FILE ..."
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" redmine_postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -F c -b \
  | gzip > "$FILE"

echo "[OK] Backup completado."

# Retención: conserva los 7 últimos dumps, borra el resto
echo "[INFO] Limpiando backups antiguos (conservando 7 archivos)..."
ls -1t "$BACKUP_DIR"/redmine_*.dump.gz | tail -n +8 | xargs -r rm -f
echo "[OK] Limpieza terminada."
