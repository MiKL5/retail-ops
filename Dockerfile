FROM postgres:18

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-18-pgaudit \
    && rm -rf /var/lib/apt/lists/*

COPY config/entrypoint-tls.sh /usr/local/bin/entrypoint-tls.sh
RUN chmod +x /usr/local/bin/entrypoint-tls.sh

ENTRYPOINT ["entrypoint-tls.sh"]
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]