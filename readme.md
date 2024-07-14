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

You will need a docker run time and a docker client that supports docker compose. The easiest way to do that is to just install docker desktop. It's *probably* also possible to use podman, and podman compose, but for now that is untested. Let us know if you have success with it.

You may also want to [install the `step cli`](https://smallstep.com/docs/step-cli/installation/). This isn't strictly necessary, but it will make it a lot easier to manage your certificates, and to add your new internal root CA as a trusted CA on your local computer.

## Steps

### 1. Clone this repo
```shell
git clone https://github.com/Letterbook/Sandcastles.git
cd Sandcastles
```

### 2. Initialize the internal root CA
```shell
docker compose -f bootstrap.yml up root-ca -d
docker compose -f bootstrap.yml cp root-ca:/home/step/templates volumes/root-ca/
docker compose -f bootstrap.yml cp root-ca:/home/step/secrets volumes/root-ca/
docker compose -f bootstrap.yml cp root-ca:/home/step/db volumes/root-ca/
docker compose -f bootstrap.yml cp root-ca:/home/step/config volumes/root-ca/
docker compose -f bootstrap.yml cp root-ca:/home/step/certs volumes/root-ca/
docker compose -f bootstrap.yml down
```

And on *nix, set the file permissions so containers can access them:
```shell
find volumes/root-ca -type d -exec chmod 755 {} +
chmod ugo+rw volumes/root-ca/* -R
```

This will configure the internal Smallstep CA, and will generate a number of secrets that you should maintain. If you need to regenerate any of these secrets, you can delete everything in the `./volumes/root-ca/` except the `.gitignore` file.

### 3.0. Redirect ports (*nix only)
To have host names (and thus ActivityPub IDs) that are the same on the host as in docker, you need to get to the exposed proxy service on default ports (80 and 443). These are privileged ports, and ideally Docker can't bind to them. It's possible to give Docker permissions to do that. Or you can redirect localhost -> localhost TCP traffic to different ports. To do that, first, install `redir`:

```shell
sudo dnf install redir
# OR
sudo apt install redir
```

Then install the provided systemd unit files:

```shell
sudo cp units/* /etc/systemd/system/
```

And start them:

```shell
sudo systemctl start redir80 redir443 
```

And stop them when you're done testing:

```shell
sudo systemctl stop redir80 redir443
```

### 3.1 Env file

Create a local env file for docker-compose

```shell
./env.bash
```

### 3.2. Run everything  
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

#### Windows

On Windows, also include the `windows.yml` overlay file.

```shell
docker compose -f docker-compose.yml -f windows.yml -f mastodon.castle.yml -f sharkey.castle.yml \
  up -d
# etc
```

At this point, you have a functioning sandbox full of fedi services that can all federate with each other. To make this maximally useful to you for local development of your own fedi service, continue on to the following optional steps.

### 4. Add .castle domains to your local hosts file (Optional)  
Each of the castles provided by this project is configured to serve from it's own .castle domain (ie. mastodon.castle, letterbook.castle, etc). To interact (and federate) with them from your host (outside of any docker container) you should add these to your system's hosts file.
```ini
# C:\Windows\System32\drivers\etc\hosts
# OR
# /etc/hosts
127.0.0.1   root-ca.castle
127.0.0.1   dashboard.castle
127.0.0.1   host.castle
127.0.0.1   mastodon.castle
127.0.0.1   letterbook.castle 
#etc
```

### 5. Add your internal CA as a trusted CA on your host (Optional)  
This requires having the `step` cli installed on your host machine. After this step, your computer will trust SSL certificates issued by your internal sandcastles CA, just like it was a well known certificate authority like Verisign or Let's Encrypt. This is a mild security risk. In step 1, you generated a private key to be used by this CA to sign those SSL certificates. Anyone with access to that key can issue certificates that your computer will trust, even if they're fraudulent. Keep that key safe.
```shell
./trust.bash
```

### 6. Remove the trusted CA (Optional)  
If you need to revoke trust in the Sandcastles CA, you can use [Certificate Manager](https://learn.microsoft.com/en-us/dotnet/framework/tools/certmgr-exe-certificate-manager-tool) on Windows.  
The linux process is distro specific, try [update-ca-certificates on debian based](https://manpages.ubuntu.com/manpages/xenial/man8/update-ca-certificates.8.html), and [update-ca-trust on red hat based](https://www.redhat.com/sysadmin/configure-ca-trust-list) distributions.

# Contributing

Please contribute! There's so much fedi software out there! If you build or host some sort of fedi server, it would be so helpful for you to share some configurations that make it easy to spin up a test instance of that software in the sandbox. In the absence of a reference implementation or a test suite, this kind of integration sandbox might be our best resource for building new apps and improving cross-app federation support.

I no longer have ready access to a Windows machine. I'll do what I can to maintain Windows compatibility, but help is appreciated.