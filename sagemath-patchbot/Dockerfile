FROM sagemath/sagemath-develop
MAINTAINER Erik M. Bray <erik.bray@lri.fr>

ARG SAGE_BRANCH=develop
# Not used, but included for compatibility with the sagemath-develop
# Dockerfile
ARG SAGE_COMMIT

ARG PATCHBOT_URL=https://github.com/sagemath/sage-patchbot.git
ARG PATCHBOT_REF=2.6.7

USER root

RUN    apt-get update -qq \
    && apt-get install -y python-pip \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install git+$PATCHBOT_URL@$PATCHBOT_REF

USER sage

# Run through the entire test suite once so as to produce an initial test
# timings log. This should at least reduce the incidence of non-deterministic
# test failures.  Ignore any test failures for now.
RUN sage -t -a -p 0 --long; exit 0

# By default, the patchbot starts by setting up a couple things and
# running all the tests once to check that the base installation is
# correct. Here we make sure to do this base check only once, at
# construction time (see --count=0 and --skip-base).
RUN patchbot --count=0 --sage-root=$(sage --root)

ENTRYPOINT patchbot --sage-root=$(sage --root) --skip-base
