#######################################################################
# Dockerfile – Redmine 5.1.8 con Agile 1.6.x + tema PurpleMine2
#  * Basado en redmine:5.1.8-bookworm (Ruby 3.1, Debian 12)
#  * Compila gemas nativas y aplica migraciones del plugin
#######################################################################
FROM redmine:5.1.8-bookworm

# 1. Dependencias del sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    git \
    curl \
    postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/redmine

# 2. Instalar gemas sin ejecutar migraciones
RUN bundle config set --local without 'development test' && \
    bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# 3. Puerto interno (el host se mapea a 3100 en docker-compose.yml)
EXPOSE 3000

# 4. Script de inicio personalizado
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 5. Usamos el ENTRYPOINT personalizado que ejecutará las migraciones al iniciar
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]
#######################################################################
