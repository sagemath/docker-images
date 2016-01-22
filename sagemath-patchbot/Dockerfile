FROM sagemath/sagemath-devel
MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

RUN sage -i patchbot

CMD [ "/bin/bash -c", "sage -patchbot --count 1" ]
# CMD [ "sage -patchbot --count 1 --owner=$OWNER" ]

