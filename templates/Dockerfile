FROM docker.io/smallstep/step-cli:0.25.0 AS step-cli

FROM  IMAGE FOR {{app_name}} as {{app_name}}

USER root

COPY --from=step-cli /usr/local/bin/step /usr/local/bin/step
COPY volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
RUN /usr/local/bin/step certificate install /usr/local/share/ca-certificates/root_ca.crt

# perform any other build steps you might need
