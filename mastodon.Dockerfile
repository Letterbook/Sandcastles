FROM docker.io/bitnami/mastodon:4

USER root

COPY volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt

RUN cat /usr/local/share/ca-certificates/root_ca.crt >> /etc/ssl/certs/ca-certificates.crt

USER 1001
