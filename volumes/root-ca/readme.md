# Warning

> [!WARNING]  
> After setup, this directory will contain secrets that should never be shared with anyone. Doing so could put your computer at risk.

In order to permit most fedi software to talk to each other with minimal modifications, they need to do it over HTTPS. Which means they all need to have SSL certificates, which all need to be issued by a certificate authority, which they need to trust. That likely includes Letterbook, or any other fediverse application that you're developing on your host machine. Which means you need to trust it as well.

When you use this project, you're going to create a root certificate authority, so that you can issue those certificates. Most of that happens automatically, and you don't need to be *too* concerned with how it works. But, in order to make full use of it, you will probably have to add that CA as a trusted root certificate authority on your own machine.

After you've set up the project, this directory will contain the private signing key for that CA, along with a variety of other secrets and configuration data. **Never reveal this data to anyone!** If the signing key of the local root CA you're about to create is ever compromised, it could be used to perform invisible man-in-the-middle attacks against any computer that trusts it. Which likely includes the computer you're using to read this right now.