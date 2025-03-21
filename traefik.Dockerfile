FROM docker.io/traefik:v3.3

COPY volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt

RUN cat /usr/local/share/ca-certificates/root_ca.crt >> /etc/ssl/certs/ca-certificates.crt
