FROM ubuntu:wily

MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

ARG SAGE_SRC_TARGET=/opt
# Note: SAGE_BRANCH may also be a tag name
ARG SAGE_BRANCH=7.0

RUN    apt-get update -qq \
    && apt-get install -y wget build-essential gfortran automake m4 dpkg-dev sudo python libssl-dev git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN    adduser --quiet --shell /bin/bash --gecos "Sage user,101,," --disabled-password sage \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && adduser sage sudo \
    && chown -R sage:sage /home/sage/

COPY scripts/ /tmp/scripts
RUN chmod -R +x /tmp/scripts
# make source checkout target, then run the install script
# see https://github.com/docker/docker/issues/9547 for the sync
RUN    mkdir -p $SAGE_SRC_TARGET \
    && /tmp/scripts/install_sage.sh $SAGE_SRC_TARGET $SAGE_BRANCH \
    && sync \
    && rm -rf /tmp/scripts

USER sage
ENV HOME /home/sage
WORKDIR /home/sage

EXPOSE 8080

CMD [ "sage" ]
