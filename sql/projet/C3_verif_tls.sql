SHOW ssl;
SELECT ssl, version AS version_tls, cipher AS chiffrement
FROM  pg_stat_ssl
WHERE pid = pg_backend_pid();
SELECT inet_server_addr() AS adresse_serveur, current_user;