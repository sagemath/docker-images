FROM sagemath/sagemath-base

MAINTAINER Erik M. Bray <erik.bray@lri.fr>

ARG SAGE_SRC_TARGET=/opt
# Note: SAGE_BRANCH may also be a tag name
# Note: SAGE_COMMIT should be the sha1 hash of the actual commit we're
# building from--by passing in different values for this argument we
# can invalidate Docker's cache for this image (currently there is a slight
# race condition between this and the install_sage.sh script, but it is not
# terribly important for the purpose of cache invalidation)
ARG SAGE_BRANCH=master
ARG SAGE_COMMIT=HEAD
ARG N_CORES

USER root
COPY scripts/install_sage.sh /tmp/
# We do a few things as root in the sage install scripts, though the sage build
# itself is done by sudo-ing as the sage user
# make source checkout target, then run the install script
# see https://github.com/docker/docker/issues/9547 for the sync
RUN echo "Building Sage from $SAGE_BRANCH ($SAGE_COMMIT)" \
    && mkdir -p $SAGE_SRC_TARGET \
    && /tmp/install_sage.sh $SAGE_SRC_TARGET $SAGE_BRANCH \
    && sync

USER sage
ENV HOME /home/sage
WORKDIR /home/sage
COPY scripts/post_install_sage.sh /tmp/
RUN /tmp/post_install_sage.sh $SAGE_SRC_TARGET && sudo rm -rf /tmp/* && sync

ENTRYPOINT [ "sage-entrypoint" ]
CMD [ "sage" ]
