FROM sagemath/sagemath-develop
MAINTAINER Erik M. Bray <erik.bray@lri.fr>

ARG SAGE_BRANCH=develop
# Not used, but included for compatibility with the sagemath-develop
# Dockerfile
ARG SAGE_COMMIT

ARG PATCHBOT_URL=https://github.com/sagemath/sage-patchbot.git
ARG PATCHBOT_REF=master

USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN    apt-get update -qq \
    && apt-get install -y python-pip jo \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install git+$PATCHBOT_URL@$PATCHBOT_REF

USER sage

# Run through the entire test suite once so as to produce an initial test
# timings log. This should at least reduce the incidence of non-deterministic
# test failures.  Ignore any test failures for now.
RUN sage -t -a -p 0 --long; exit 0

ARG N_CORES=1
# Write a config file specifying the number of cores to use for the build
# (by default taken from the N_CORES on the image build machine itself) along
# with some other default config.
RUN jo -p sage_root=$(sage --root) parallelism=$N_CORES retries=2 \
    safe_only=false \
    plugins=$(jo -a pyflakes) > patchbot.conf

# By default, the patchbot starts by setting up a couple things and
# running all the tests once to check that the base installation is
# correct. Here we make sure to do this base check only once, at
# construction time (see --count=0 and --skip-base).
RUN patchbot --count=0 --config=patchbot.conf

ENTRYPOINT patchbot --skip-base --config=patchbot.conf
