FROM python:3.11-alpine

RUN pip install ipython
RUN pip install bovine

RUN pip install fediverse_pasture

ADD https://codeberg.org/helge/funfedidev/archive/cd14bd038b3733f8efa343c2157dfd8768e641f9.zip /var/source.zip 

RUN unzip /var/source.zip -d /var/source/
RUN mkdir /work
RUN cp /var/source/funfedidev/fediverse-pasture/work / -r
WORKDIR /opt

COPY volumes/root-ca/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt

RUN cat /usr/local/share/ca-certificates/root_ca.crt >> /etc/ssl/certs/ca-certificates.crt