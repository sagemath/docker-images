# Images and their dependencies
IMAGES=sagemath sagemath-develop sagemath-jupyter sagemath-patchbot
.PHONY: all build push docker-clean sagemath-develop-test FORCE $(IMAGES)

SAGE_VERSION ?= 7.0

all: build

sagemath:

sagemath-develop:

sagemath-jupyter: sagemath

sagemath-patchbot: sagemath-develop

# Main rules

build: $(IMAGES)

push:
	for image in $(IMAGES); do docker push sagemath/$$image; done

# Refs:
# - https://www.calazan.com/docker-cleanup-commands/
# - http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers
docker-clean:
	@echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	@echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`

$(filter-out %-develop, $(IMAGES)): %: %/Dockerfile FORCE
	@echo Building sagemath/$@
	time docker build $(DOCKER_BUILD_FLAGS) --tag="sagemath/$@:$(SAGE_VERSION)" --build-arg SAGE_BRANCH=$(SAGE_VERSION) $@ 2>&1 | tee $@.log

$(filter %-develop, $(IMAGES)): %-develop: %/Dockerfile FORCE
	@echo Building sagemath/$@
	time docker build $(DOCKER_BUILD_FLAGS) --tag="sagemath/$@" --build-arg SAGE_BRANCH=develop $(@:-develop=) 2>&1 | tee $@.log

FORCE:

# Tests

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

# TODO: run ptestlong inside the docker image and report
