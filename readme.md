# Sandcastles

> Heavenly, she's so heavenly  
> When she smiles at you and she helps you build  
> Castles in the sand

The Letterbook Sandcastles project offers an integration and federation test sandbox for developers of fediverse software. The goal is to make it easy to set up local instances of most fediverse servers, which can all federate with each other, with minimal necessary configuration. This includes your own software, running on your local machine.

# How it Works
This is accomplished by running them all in a docker compose project, along with some supporting infrastructure to provision and use SSL certificates.

## Smallstep Certificate Authority
This provides a root certificate authority which can issue SSL certificates to all of the other servers managed by the project. These servers are preconfigured to trust this CA, and the certificates will be provisioned as needed.

## Traefik Reverse Proxy
Traefik serves as a reverse proxy, handling *all* of the federated traffick between services. It does this so that it can also manage their SSL certificates and connections. Traefik will automatically request or renew the certificates from Smallstep.

# Getting Started

## Prerequisites

You will need a docker run time and a docker client that supports docker compose. The easiest way to do that is to just install docker desktop. It's also confirmed to work with (rootless) podman compose. If you want to use a rootless container runtime, podman seems to work better than docker.

You may also want to [install the `step cli`](https://smallstep.com/docs/step-cli/installation/). This isn't strictly necessary, but it will make it a lot easier to manage your certificates, and to add your new internal root CA as a trusted CA on your local computer.

## Steps

### 1. Clone this repo
```shell
git clone https://github.com/Letterbook/Sandcastles.git
cd Sandcastles
```

### 2. Bootstrap the project

You can use the provided `castle` script to perform most actions with the project. It should work with most common shells, but was made in `bash`.
The `bootstrap` command normally only needs to be run once, unless you need to regenerate your private keys for the internal sandcastles CA.
```shell
./castle bootstrap
```

You may need to rebuild your container images periodically, to receive updates or perform testing.
```shell
./castle build mastodon --required
```

Then you can run and interact with the apps.
```shell
./castle up mastodon
# do stuff
./castle down --all
```

Check the help for more details.

<details>
  <summary>
      <h3>Bootstrap and run without using the `castle` script</h3>
  </summary>

### 2b. Initialize the internal root CA
```shell
docker compose -f bootstrap.yml up root-ca -d
export ROOT_CA_CASTLE=$(docker compose -f bootstrap.yml ps -q)
sleep 1
docker cp $ROOT_CA_CASTLE:/home/step/templates volumes/root-ca/
docker cp $ROOT_CA_CASTLE:/home/step/secrets volumes/root-ca/
docker cp $ROOT_CA_CASTLE:/home/step/db volumes/root-ca/
docker cp $ROOT_CA_CASTLE:/home/step/config volumes/root-ca/
docker cp $ROOT_CA_CASTLE:/home/step/certs volumes/root-ca/
docker compose -f bootstrap.yml down
cp volumes/ca.json volumes/root-ca/config/ca.json -f
```

And on *nix, set the file permissions so containers can access them:
```shell
find volumes/root-ca -type d -exec chmod 755 {} +
find volumes/root-ca -type f -exec chmod 644 {} +
```

This will configure the internal Smallstep CA, and will generate a number of secrets that you should maintain. If you need to regenerate any of these secrets, you can delete everything in the `./volumes/root-ca/` except the `.gitignore` file.

### 3. Prepare your host system

#### Provide docker compose env vars

Create a local env file for docker compose

```shell
./env.bash
```

### 4. Run everything

#### Using Podman

This step will build new images that are configured to trust the root certificate authority you just created. Podman can build and run these images just fine, but podman compose doesn't set the right options to build the images. So, to use podman, you should build the images yourself, instead of relying on podman compose to do it. That can be done with the following commands.

```shell
podman build . -f proxy.Dockerfile -t localhost/traefik-sandcastle:latest
podman build . -f mastodon.Dockerfile -t localhost/mastodon-sandcastle:latest --target mastodon
podman build . -f mastodon.Dockerfile -t localhost/mastodon-sandcastle:latest --target mastodon-streaming
```

#### Compose

This will re-build the service images with built-in trust for your new internal root CA. This allows all of the services to federate with each other with no additional modifications. The re-build is only necessary once, or whenever a service is updated. You can run only the services you want by specifying their overlay files as extra `-f` args to `docker compose up`
```shell
# add other *.castle.yml as needed
docker compose -f docker-compose.yml -f mastodon.castle.yml -f sharkey.castle.yml \
    up -d
```

If you need to rebuild these images because you regenerated the root CA secrets, you can do so by adding the `--build` and `--force-recreate` flags to the compose command.
```shell
# add other *.castle.yml as needed
docker compose -f docker-compose.yml -f mastodon.castle.yml -f sharkey.castle.yml \
    up --build --force-recreate -d
```

At this point, you have a functioning sandbox full of fedi services that can all federate with each other. To make this maximally useful to you for local development of your own fedi service, continue on to the following optional steps.
</details>

### Add .castle domains to your local hosts file (Optional)  
Each of the castles provided by this project is configured to serve from it's own .castle domain (ie. mastodon.castle, letterbook.castle, etc). To interact (and federate) with them from your host (outside of any docker container) you should add these to your system's hosts file.
```ini
# C:\Windows\System32\drivers\etc\hosts
# OR
# /etc/hosts
127.0.0.1   proxy.castle
127.0.0.1   mastodon.castle
127.0.0.1   letterbook.castle 
#etc
```

### Add your internal CA as a trusted CA on your host (Optional)  
This requires having the [`step` cli](https://smallstep.com/docs/step-cli/reference/certificate/) installed on your host machine. After this step, your computer will trust SSL certificates issued by your internal sandcastles CA, just like it was a well known certificate authority like Verisign or Let's Encrypt. This is a mild security risk. In step 1, you generated a private key to be used by this CA to sign those SSL certificates. Anyone with access to that key can issue certificates that your computer will trust, even if they're fraudulent. Keep that key safe.
```shell
step certificate install --all volumes/root-ca/certs/root_ca.crt
```

#### Alternatively
You might not have to configure system-wide trust for the sandcastle internal CA. Many stacks have a way to provide a custom CA bundle that can be used to validate certificates on HTTP requests. For example:

- Nodejs        
  `export NODE_EXTRA_CA_CERTS=/path/to/volumes/root-ca/certs/root_ca.crt`
 

### Revoke the internal CA (Optional)
If you need to revoke trust in the Sandcastles CA, you can use [`step` cli](https://smallstep.com/docs/step-cli/reference/certificate/uninstall/) again.

```shell
step certificate uninstall --all volumes/root-ca/certs/root_ca.crt
```

# Contributing

Please contribute! There's so much fedi software out there! If you build or host some sort of fedi server, it would be so helpful for you to share some configurations that make it easy to spin up a test instance of that software in the sandbox. In the absence of a reference implementation or a test suite, this kind of integration sandbox might be our best resource for building new apps and improving cross-app federation support.

I no longer have ready access to a Windows machine. I'll do what I can to maintain Windows compatibility, but help is appreciated.
