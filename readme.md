# Sandcastles

> Heavenly, she's so heavenly  
> When she smiles at you and she helps you build  
> Castles in the sand

The Letterbook Sandcastles project offers an integration and federation test sandbox for developers of fediverse software. The goal is to make it easy to set up local instances of most fediverse servers, which can all federate with each other, with minimal necessary configuration. This includes your own software, running on your local machine.

# How it Works
This is accomplished by running them all in a docker compose project, along with some supporting infrastructure.

## Smallstep Certificate Authority
This provides a root certificate authority which can issue SSL certificates to all of the other servers managed by the project. These servers are preconfigured to trust this CA, and the certificates will be renewed or re-issued as needed.

## Traefik Reverse Proxy
Traefik serves as a reverse proxy, handling *all* of the federated traffick between services. It does this so that it can also manage their SSL certificates and connections. Traefik will automatically provision these certificates.

# Getting Started