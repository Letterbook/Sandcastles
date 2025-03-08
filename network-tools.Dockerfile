FROM docker.io/smallstep/step-cli:0.25.0 AS step-cli

FROM docker.io/jonlabelle/network-tools:latest

USER root

COPY --from=step-cli /usr/local/bin/step /usr/local/bin/step
COPY volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
RUN /usr/local/bin/step certificate install /usr/local/share/ca-certificates/root_ca.crt
