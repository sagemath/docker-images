FROM sagemath/sagemath

MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

EXPOSE 8888

ENTRYPOINT sage -n jupyter --no-browser --ip=$(grep `hostname` /etc/hosts | cut -f1) --port=8888
