.PHONY: all build clean docker-clean sagemath-develop-test

# Images and their dependencies
IMAGES=sagemath sagemath-develop sagemath-jupyter sagemath-patchbot

common_scripts:=$(wildcard common/*.sh)
common_script_copies:=$(addprefix %/scripts/, $(common_scripts))
scripts=$(common_script_copies)

all: build

sagemath: %: $(scripts)

sagemath-develop: %: $(scripts)

sagemath-jupyter: sagemath

sagemath-patchbot: sagemath-develop

# Main rules

build: $(IMAGES)

push:
	for image in $(IMAGES); do docker push sagemath/$$image; done

clean:
	for image in $(IMAGES); do rm -rf $(image)/scripts/common; done

# Refs:
# - https://www.calazan.com/docker-cleanup-commands/
# - http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers
docker-clean:
	echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`

# Utilities

# Takes care of common file that we need to duplicate in several subdirectories
# See https://github.com/docker/docker/issues/1676
$(common_script_copies): $(common_scripts)
	@echo "Copying $< > $@"
	mkdir -p $(@D)
	head -1 $< > $@
	echo "# !!! GENERATED FILE: DO NOT MODIFY! !!!" >> $@
	tail -n +2 $< >> $@

$(IMAGES): %: %/Dockerfile FORCE
	@echo Building sagemath/$@
	time docker build --tag="sagemath/$@" $@ 2>&1 | tee $@.log

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

