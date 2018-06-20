FROM ubuntu:bionic

MAINTAINER Erik M. Bray <erik.bray@lri.fr>

RUN    apt-get update -qq \
    && apt-get install -y wget build-essential gfortran automake m4 dpkg-dev sudo python libssl-dev git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# We *have* to add a non-root user since sage cannot be built as root
# However, we do allow the 'sage' user to use sudo without a password
RUN    adduser --quiet --shell /bin/bash --gecos "Sage user,101,," --disabled-password sage \
    && chown -R sage:sage /home/sage/ \
    && echo "sage ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/01-sage \
    && chmod 0440 /etc/sudoers.d/01-sage

ENV SHELL /bin/bash

# The unicode sage banner crashes Docker :(
# see https://github.com/docker/docker/issues/21323
# The "bare" banner is ASCII only
ENV SAGE_BANNER bare

EXPOSE 8080
USER sage
