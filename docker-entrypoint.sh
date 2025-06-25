#!/bin/bash
set -e

# Eliminar archivo PID si existe
rm -f /usr/src/redmine/tmp/pids/server.pid

# Crear archivo database.yml con variables de entorno
cat > /usr/src/redmine/config/database.yml <<EOF
production:
  adapter: postgresql
  host: ${REDMINE_DB_POSTGRES:-db}
  database: ${REDMINE_DB_DATABASE:-redmine}
  username: ${REDMINE_DB_USERNAME:-redmine}
  password: ${REDMINE_DB_PASSWORD:-redmine}
  encoding: utf8
EOF

# Esperar a que PostgreSQL esté listo
echo "Esperando a que PostgreSQL esté listo..."
until PGPASSWORD=$REDMINE_DB_PASSWORD psql -h "${REDMINE_DB_POSTGRES:-db}" -U "${REDMINE_DB_USERNAME:-redmine}" -d "${REDMINE_DB_DATABASE:-redmine}" -c '\q' 2>/dev/null; do
  >&2 echo "PostgreSQL no está disponible - esperando..."
  sleep 1
done

echo "PostgreSQL está listo, continuando..."

# Ejecutar migraciones de la base de datos de Redmine
echo "Ejecutando migraciones de la base de datos..."
bundle exec rake db:migrate RAILS_ENV=production

# Ejecutar migraciones de los plugins
echo "Ejecutando migraciones de los plugins..."
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# Precargar la base de datos por defecto (solo si no hay datos)
echo "Verificando datos iniciales..."
bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=es

# Asegurar los permisos de los archivos
echo "Ajustando permisos..."
chown -R redmine:redmine /usr/src/redmine/files
chmod -R 755 /usr/src/redmine/files

# Iniciar Redmine
echo "Iniciando Redmine..."
exec "$@"