all: check_postinstall

IMAGES=sagemath sagemath-develop sagemath-jupyter sagemath-patchbot

build: $(IMAGES)

push:
	for image in $(IMAGES); do docker push $$image; done

check_postinstall: postinstall_sage.sh
	cp postinstall_sage.sh sagemath/postinstall_sage.sh
	cp postinstall_sage.sh sagemath-develop/postinstall_sage.sh

sagemath: sagemath/Dockerfile sagemath/install_sage.sh check_postinstall
	time docker build --tag="sagemath/sagemath" sagemath

sagemath-develop: sagemath-develop/Dockerfile sagemath-develop/install_sage.sh check_postinstall
	time docker build --tag="sagemath/sagemath-develop" sagemath-develop

sagemath-jupyter: sagemath sagemath-jupyter/Dockerfile
	time docker build --tag="sagemath/sagemath-jupyter" sagemath-jupyter

sagemath-patchbot: sagemath-develop sagemath-patchbot/Dockerfile
	time docker build --tag="sagemath/sagemath-patchbot" sagemath-patchbot

sagemath-develop-test:
	echo "1+1;" | docker run sagemath/sagemath-develop gap
	echo "1+1;" | docker run sagemath/sagemath-develop gp
	echo "1+1;" | docker run sagemath/sagemath-develop ipython
	echo "1+1;" | docker run sagemath/sagemath-develop maxima
	echo ""     | docker run sagemath/sagemath-develop mwrank
	echo "1+1;" | docker run sagemath/sagemath-develop R --no-save
	echo "1+1;" | docker run sagemath/sagemath-develop sage
	echo "1+1;" | docker run sagemath/sagemath-develop sagemath
	echo "1+1;" | docker run sagemath/sagemath-develop singular
	echo "All tests passed"

# Refs:
# - https://www.calazan.com/docker-cleanup-commands/
# - http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers
docker-clean:
	echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`
