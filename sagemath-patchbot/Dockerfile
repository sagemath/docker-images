FROM sagemath/sagemath-develop
MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

RUN sage -i patchbot

CMD [ "sage", "-patchbot", "--count 1" ]
# CMD [ "sage -patchbot --count 1 --owner=$OWNER" ]

