FROM sagemath/sagemath-develop
MAINTAINER Sebastian Gutsche <sebastian.gutsche@gmail.com>

# By default, the patchbot starts by setting up a couple things and
# running all the tests once to check that the base installation is
# correct. Here we make sure to do this base check only once, at
# construction time (see --count=0 and --skip-base).

RUN sage -i patchbot && sage -patchbot --count=0

CMD [ "sage", "-patchbot", "--skip-base", "--count=1" ]
# CMD [ "sage -patchbot --count=1 --skip-base --owner=$OWNER" ]

