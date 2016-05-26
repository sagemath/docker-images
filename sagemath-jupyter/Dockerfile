FROM sagemath/sagemath

MAINTAINER Erik M. Bray <erik.bray@lri.fr>

ARG SAGE_BRANCH=master
EXPOSE 8888

ENTRYPOINT sage -n jupyter --no-browser --ip=$(grep `hostname` /etc/hosts | cut -f1) --port=8888
