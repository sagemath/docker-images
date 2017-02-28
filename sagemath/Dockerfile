FROM sagemath/sagemath-base

MAINTAINER Erik M. Bray <erik.bray@lri.fr>

ARG SAGE_SRC_TARGET=/opt
# Note: SAGE_BRANCH may also be a tag name
ARG SAGE_BRANCH=master

COPY scripts/ /tmp/scripts
RUN chmod -R +x /tmp/scripts
# We do a few things as root in the sage install scripts, though the sage build
# itself is done by sudo-ing as the sage user
USER root
# make source checkout target, then run the install script
# see https://github.com/docker/docker/issues/9547 for the sync
RUN    mkdir -p $SAGE_SRC_TARGET \
    && /tmp/scripts/install_sage.sh $SAGE_SRC_TARGET $SAGE_BRANCH \
    && sync

RUN /tmp/scripts/post_install_sage.sh && rm -rf /tmp/* && sync

USER sage
ENV HOME /home/sage

WORKDIR /home/sage

CMD [ "sage" ]
