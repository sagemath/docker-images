FROM ubuntu:wily

MAINTAINER Erik M. Bray <erik.bray@lri.fr>

RUN    apt-get update -qq \
    && apt-get install -y wget build-essential gfortran automake m4 dpkg-dev sudo python libssl-dev git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN    adduser --quiet --shell /bin/bash --gecos "Sage user,101,," --disabled-password sage \
    && chown -R sage:sage /home/sage/ \
    && echo "sage ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/01-sage \
    && chmod 0440 /etc/sudoers.d/01-sage

ARG SAGE_SRC_TARGET=/opt
# Note: SAGE_BRANCH may also be a tag name
# Note: SAGE_COMMIT should be the sha1 hash of the actual commit we're
# building from--by passing in different values for this argument we
# can invalidate Docker's cache for this image (currently there is a slight
# race condition between this and the install_sage.sh script, but it is not
# terribly important for the purpose of cache invalidation)
ARG SAGE_BRANCH=master
ARG SAGE_COMMIT=HEAD

COPY scripts/ /tmp/scripts
RUN chmod -R +x /tmp/scripts
# make source checkout target, then run the install script
# see https://github.com/docker/docker/issues/9547 for the sync
RUN echo "Building Sage from $SAGE_BRANCH ($SAGE_COMMIT)" \
    && mkdir -p $SAGE_SRC_TARGET \
    && /tmp/scripts/install_sage.sh $SAGE_SRC_TARGET $SAGE_BRANCH \
    && sync

RUN /tmp/scripts/post_install_sage.sh && rm -rf /tmp/* && sync

USER sage
ENV HOME /home/sage
ENV SHELL /bin/bash

# The unicode sage banner crashes Docker :(
# see https://github.com/docker/docker/issues/21323
# The "bare" banner is ASCII only
ENV SAGE_BANNER bare

WORKDIR /home/sage

EXPOSE 8080

CMD [ "sage" ]
