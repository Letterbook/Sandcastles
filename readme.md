# Sandcastles

> Heavenly, she's so heavenly  
> When she smiles at you and she helps you build  
> Castles in the sand

The Letterbook Sandcastles project offers an integration and federation test sandbox for developers of fediverse software. The goal is to make it easy to set up local instances of most fediverse servers, which can all federate with each other, with minimal necessary configuration. The whole environment is meant to be entirely local and self-contained. It doesn't require you to buy a domain name, or host any services exposed to the internet. You can also run your own under-development software without much difficulty, as long as you can run it in a docker container.

# How it Works
This is accomplished by running them all in a docker compose project, along with some supporting infrastructure to provision and use SSL certificates.

## Smallstep Certificate Authority
This provides a root certificate authority which can issue SSL certificates to all of the other servers managed by the project. These servers are preconfigured to trust this CA, and the certificates will be provisioned as needed.

## Traefik Reverse Proxy
Traefik serves as a reverse proxy, handling *all* of the federated traffick between services. It does this so that it can also manage their SSL certificates and connections. Traefik will automatically request or renew the certificates from Smallstep.

# Available Services

- [x] Mastodon (v4.3.4)
- [x] Letterbook (development source build)
- [ ] GoToSocial (#9)
- [ ] Sharkey (#8)
- [ ] Akkoma
- [ ] Iceshrimp.NET
- [ ] NodeBB

# Getting Started

## Prerequisites

You will need a docker run time and a docker client that supports docker compose. The easiest way to do that is to just install docker desktop. It's also confirmed to work with (rootless) podman compose. If you want to use a rootless container runtime, podman seems to work better than docker.

You may also want to [install the `step cli`](https://smallstep.com/docs/step-cli/installation/). This isn't strictly necessary, but it will make it a lot easier to manage your certificates, and to add your new internal root CA as a trusted CA on your local computer.

## Quickstart

If you just want to get up and running as quickly as possible, this is the process:

```shell
git clone https://github.com/Letterbook/Sandcastles.git
cd Sandcastles
./castle bootstrap
./castle build --all
./castle up --all
# At this point, all of the available services should be running. Or, at
# least initializing, and they'll be up soon. You can interact with them
# and exchange federated messages, check their logs, and do any other
# testing you want.
```

And when you're done, shut it all down:
```shell
./castle down --all
```

## Steps

Read on for a more detailed discussion of using sandcastles, what the scripts are doing, and how it works.

### 1. Clone this repo
```shell
git clone https://github.com/Letterbook/Sandcastles.git
cd Sandcastles
```

### 2. Bootstrap and run the project

You can use the provided `castle` script to perform most actions with the project. It _should_ work with most common shells, but was made in `bash`. It also _should_ work in linux, mac, and windows (under WSL). But, it was made in a linux environment. If you want to inspect what `castle` will do before you execute it, there is a `--dry-run` flag you can use for that.

One of the core functions of the Sandcastles project is to automatically provision trusted TLS certificates and https endpoints for all the fediverse services the project manages. To accomplish this offline, we need to run our own internal certificate authority, so that we can issue certificates to our services for their internal hostnames. Bootstrapping initializes that internal CA, and makes it's root certificate available so other services can be set up to trust it. The `bootstrap` command normally only needs to be run once, unless you need to regenerate your private keys for the internal sandcastles CA. 
```shell
./castle bootstrap
```

> [!Tip]
> For all commands other than bootstrap, you can specify individual services to manage, or use the `--all` flag to cover all of them.

We have to build our own container images so that we can add our own trusted certificate authority. In most cases, that's the only modification we need to make to the container images that projects provide. You should build the container images before first use. This is necessary if you're running on `podman`. If you're using `docker`, it's still a good idea. You may need to rebuild your container images periodically, to receive updates or test your changes.
```shell
./castle build --all
```

Then you can run and interact with the apps.
```shell
./castle up mastodon
# do stuff
./castle down --all
```

Check the help for more details.

```shell
./castle help
./castle up --help
# etc
```

### Alternative, bootstrap and run manually
<details>
  <summary>
      Steps
  </summary>

If for some reason you can't use the `castle` CLI, you can run all of the necessary steps yourself.

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

Create a local env file for docker compose. This allows the traefik proxy to read labels on the containers, and route to them accordingly.

```shell
DOCKER_PATH=$(sed -e 's|^.*://||' <<< $DOCKER_HOST)
echo "DOCKER_PATH=${DOCKER_PATH}" > .env
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
Each of the components provided by this project is configured to serve from it's own .castle domain (ie. mastodon.castle, letterbook.castle, etc). To interact with them from your host (outside of any docker container) you should add these to your system's hosts file.
```ini
# C:\Windows\System32\drivers\etc\hosts
# OR
# /etc/hosts
127.0.0.1   proxy.castle
127.0.0.1   mastodon.castle
127.0.0.1   letterbook.castle 
#etc
```

They'll all be available on port `8443`

### Add your internal CA as a trusted CA on your host (Optional)  

> [!Warning]
> This is a security risk, if your CA's private key is ever compromised

This requires having the [`step` cli](https://smallstep.com/docs/step-cli/reference/certificate/) installed on your host machine. After this step, your computer will trust TLS certificates issued by your internal sandcastles CA, just like it was a well known certificate authority like Verisign or Let's Encrypt. In the bootstrapping step, you generated a private key to be used by this CA to sign those TLS certificates. Anyone with access to that key can issue certificates that your computer will trust, even if they're fraudulent. This means another server with access to that key could impersonate other services, like gmail or banks. Keep that key safe.
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

## Adding New Backends

There's usually two components to adding a new backend component to the sandcastle environment: a dockerfile, and a docker compose file. They must be named with the same prefix, because the `castle` CLI will naively search for and use them by file name. If a project requires multiple images to send messages to peer services, they will each need a dockerfile, so that they can be configured to trust the internal CA. In that case, you can append a suffix to the names of other necessary dockerfiles, like `my_service.Dockerfile` and `my_service-worker.Dockerfile`.

The docker compose file must provide additional configuration to the central Traefik proxy, in order to make the server accessible to peer services. This comes in the form of container labels that will configure routing, and a network alias that will configure internal DNS.

The `castle` CLI includes a `new` command that will scaffold these necessary files. For example:

```shell
./castle new my_serice
```

From there, you can customize the generated Dockerfile and compose.yml files. If you think any new components you add would be generally useful to other developers, please consider submitting them in a PR!

### Contributing New Components

One of the goals for this project to have as close to zero required configuration as possible. The intent is to let developers interact with federated peer software. We don't want to force them to become experts in each of those project's operational quirks. So, new backend components should self-initialize as much as possible. If the app requires any migrations, secrets, or configuration, that should be included, with useful defaults. If at all possible, you should also provide a default user and password, so that developers can quickly log in and start generating test federated messages to examine.
