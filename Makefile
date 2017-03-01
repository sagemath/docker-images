SHELL=/bin/bash

# Images and image-specific steps
DEVELOP_IMAGES=sagemath-develop sagemath-patchbot
RELEASE_IMAGES=sagemath sagemath-jupyter
IMAGES=$(DEVELOP_IMAGES) $(RELEASE_IMAGES)

BUILD_IMAGES=$(addprefix build-,$(IMAGES))
BUILD_RELEASE_IMAGES=$(addprefix build-,$(RELEASE_IMAGES))
BUILD_DEVELOP_IMAGES=$(addprefix build-,$(DEVELOP_IMAGES))
TEST_IMAGES=$(addprefix test-,$(IMAGES))
PUSH_IMAGES=$(addprefix push-,$(IMAGES))

.PHONY: all build push docker-clean $(IMAGES) $(BUILD_IMAGES) \
	$(BUILD_RELEASE_IMAGES) $(BUILD_DEVELOP_IMAGES) $(TEST_IMAGES) \
	$(PUSH_IMAGES)

# Stamp files
BUILD_RELEASE_IMAGES_S=$(addprefix stamps/,$(BUILD_RELEASE_IMAGES))
BUILD_DEVELOP_IMAGES_S=$(addprefix stamps/,$(BUILD_DEVELOP_IMAGES))
TEST_IMAGES_S=$(addprefix stamps/,$(TEST_IMAGES))
PUSH_IMAGES_S=$(addprefix stamps/,$(PUSH_IMAGES))
STAMPS=$(BUILD_RELEASE_IMAGES_S) $(BUILD_DEVELOP_IMAGES_S) $(TEST_IMAGES_S) \
	   $(PUSH_IMAGES_S)

SAGE_GIT_URL=git://git.sagemath.org/sage.git
# Rather than hard-coding a default, this variable should always be specified
# when building a non-develop version.
SAGE_VERSION ?=
TAG_LATEST ?= 0

################################ Subroutines ##################################

check_defined = \
	$(if $(value $(strip $1)),,$(error Undefined $(strip $1)$(if $2, ($(strip $2)))))
get_git_hash = \
	$$(git ls-remote --heads $(SAGE_GIT_URL) $1 | \
	   grep 'refs/heads/$(strip $1)' | awk '{print $$1}')

# Run the tests for sage--the first argument is the image name
# This runs the tests up to two times: Once normally, and then if there
# are failures once more with the --failed flag.
# This is because there are some tests that tend to fail the first time the
# test suite is run. These tests should probably be fixed, but in the meantime
# this is a reasonable workaround.
sage_run = \
	$(if $(findstring -develop,$1),,\
		$(call check_defined, SAGE_VERSION, Sage version to test)) \
	docker run --rm \
		sagemath/$(strip $1)$(if $(findstring -develop,$1),,:$(SAGE_VERSION)) \
		$2

sage_test = \
	$(call sage_run, $1, sage -t -p 0 -a --long) || \
	$(call sage_run, $1, sage -t -p 0 -a --long --failed)

# Write command stdout/err to a logfile in logs/
# $1: The command to run
# $2: The base name of the logfile
log = $1 2>&1 | tee logs/$(strip $2).log ; test $${PIPESTATUS[0]} -eq 0

############################## Top-level Targets ##############################

all: $(IMAGES)

release: sagemath sagemath-jupyter

sagemath:

sagemath-develop:

sagemath-jupyter: sagemath

sagemath-patchbot: sagemath-develop

build: $(BUILD_IMAGES)

test: $(TEST_IMAGES)

push: $(PUSH_IMAGES)

############################### Cleanup Targets ###############################

docker-clean:
	@echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	@echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`

################################# Main Rules ##################################

$(IMAGES): %: stamps/push-%
$(BUILD_IMAGES) $(TEST_IMAGES) $(PUSH_IMAGES): %: stamps/%

$(STAMPS): | stamps logs

# Refs:
# - https://www.calazan.com/docker-cleanup-commands/
# - http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers

# Build all release images
$(BUILD_RELEASE_IMAGES_S): stamps/build-%: %/Dockerfile
	@echo Building sagemath/$*
	$(call check_defined, SAGE_VERSION, Sage version to build)
	$(call log, time docker build $(DOCKER_BUILD_FLAGS) \
		--tag="sagemath/$*:$(SAGE_VERSION)" \
		--build-arg SAGE_BRANCH=$(SAGE_VERSION) $*,
		build-$*)
ifeq ($(TAG_LATEST),1)
	docker tag "sagemath/$*:$(SAGE_VERSION)" "sagemath/$*:latest"
endif
	touch $@

# Builds the sagemath-develop and sagemath-patchbot images
$(BUILD_DEVELOP_IMAGES_S): stamps/build-%: %/Dockerfile
	@echo Building sagemath/$*
	$(call log, time docker build $(DOCKER_BUILD_FLAGS) \
		--tag="sagemath/$*" \
		--build-arg SAGE_BRANCH=develop \
		--build-arg SAGE_COMMIT=$(call get_git_hash, develop) $*,\
		build-$*)
	touch $@

$(TEST_IMAGES_S): stamps/test-%: stamps/build-%
	@echo Testing $*
	$(call log, $(call sage_test, $*), test-$*)
	@echo "All tests passed"
	touch $@

$(PUSH_IMAGES_S): stamps/push-%: stamps/build-% stamps/test-%
	@echo Pushing $*
	$(if $(findstring -develop,$*),docker push "sagemath/$*",\
		$(call check_defined, SAGE_VERSION, Sage version to push) \
		docker push "sagemath/$*:$(SAGE_VERSION)")
ifeq ($(TAG_LATEST),1)
	$(if $(findstring -develop,$*),,docker push "sagemath/$*:latest")
endif
	touch $@

stamps logs:
	mkdir $@
