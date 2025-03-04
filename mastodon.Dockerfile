FROM docker.io/smallstep/step-cli:0.25.0 AS step-cli

FROM ghcr.io/mastodon/mastodon:v4.3.4 as mastodon

USER root

COPY --from=step-cli /usr/local/bin/step /usr/local/bin/step
COPY volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
RUN /usr/local/bin/step certificate install /usr/local/share/ca-certificates/root_ca.crt

USER mastodon

FROM ghcr.io/mastodon/mastodon-streaming:v4.3.4 as mastodon-streaming

USER root

COPY --from=step-cli /usr/local/bin/step /usr/local/bin/step
COPY volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
RUN /usr/local/bin/step certificate install /usr/local/share/ca-certificates/root_ca.crt

USER mastodon
