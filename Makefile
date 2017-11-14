SHELL=/bin/bash

# Images and image-specific steps
BASE_IMAGES=sagemath-base
DEVELOP_IMAGES=sagemath-develop sagemath-patchbot
RELEASE_IMAGES=sagemath sagemath-jupyter
IMAGES=$(DEVELOP_IMAGES) $(RELEASE_IMAGES)

TESTED_IMAGES=sagemath sagemath-develop
NON_TESTED_IMAGES=sagemath-patchbot sagemath-jupyter

BUILD_IMAGES=$(addprefix build-,$(IMAGES))
BUILD_BASE_IMAGES=$(addprefix build-,$(BASE_IMAGES))
BUILD_RELEASE_IMAGES=$(addprefix build-,$(RELEASE_IMAGES))
BUILD_DEVELOP_IMAGES=$(addprefix build-,$(DEVELOP_IMAGES))
TEST_IMAGES=$(addprefix test-,$(TESTED_IMAGES))
PUSH_IMAGES=$(addprefix push-,$(IMAGES))

.PHONY: all build push docker-clean sagemath-base sagemath-local-develop \
	$(BASE_IMAGES) $(IMAGES) \
	$(BUILD_IMAGES) $(BUILD_RELEASE_IMAGES) $(BUILD_DEVELOP_IMAGES) \
	$(TEST_IMAGES) $(PUSH_IMAGES)

# Directories
STAMP_DIR=.stamps
LOG_DIR=.logs

# Stamp files
BUILD_BASE_IMAGES_S=$(addprefix $(STAMP_DIR)/,$(BUILD_BASE_IMAGES))
BUILD_RELEASE_IMAGES_S=$(addprefix $(STAMP_DIR)/,$(BUILD_RELEASE_IMAGES))
BUILD_DEVELOP_IMAGES_S=$(addprefix $(STAMP_DIR)/,$(BUILD_DEVELOP_IMAGES))
TEST_IMAGES_S=$(addprefix $(STAMP_DIR)/,$(TEST_IMAGES))
NON_TEST_IMAGES_S=$(addprefix $(STAMP_DIR)/test-,$(NON_TESTED_IMAGES))
PUSH_IMAGES_S=$(addprefix $(STAMP_DIR)/,$(PUSH_IMAGES))
STAMPS=$(BUILD_BASE_IMAGES_S) $(BUILD_RELEASE_IMAGES_S) \
	   $(BUILD_DEVELOP_IMAGES_S) $(TEST_IMAGES_S) $(PUSH_IMAGES_S)

SAGE_GIT_URL=git://git.sagemath.org/sage.git
# Rather than hard-coding a default, this variable should always be specified
# when building a non-develop version.
SAGE_VERSION ?=
TAG_LATEST ?= 0

# Additional configuration
# Supplies the number of CPUs on the build machine, but no more than 8
N_CORES ?= $(shell N=$$(cat /proc/cpuinfo | grep '^processor' | wc -l); \
		           [ $$N -gt 8 ] && echo 8 || echo $$N)

################################ Subroutines ##################################

check_defined = \
	$(if $(value $(strip $1)),,$(error Undefined $(strip $1)$(if $2, ($(strip $2)))))

get_git_hash = \
	$$(git ls-remote --heads $(SAGE_GIT_URL) $1 | \
	   grep 'refs/heads/$(strip $1)' | awk '{print $$1}')

get_image_hash = \
	$$(docker images -q --no-trunc $1)

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
	$(call sage_run, $1, bash -c 'sage -t -p 0 -a --long || sage -t -p 0 -a --long --failed') 

# Write command stdout/err to a logfile in $(LOG_DIR)/
# $1: The command to run
# $2: The base name of the logfile
log = $1 2>&1 | tee $(LOG_DIR)/$(strip $2).log ; test $${PIPESTATUS[0]} -eq 0

############################## Top-level Targets ##############################

all: $(IMAGES)

release: sagemath sagemath-jupyter

sagemath: sagemath-base

sagemath-develop: sagemath-base

sagemath-jupyter: sagemath

sagemath-patchbot: sagemath-develop

build: $(BUILD_IMAGES)

test: $(TEST_IMAGES)

push: $(PUSH_IMAGES)

############################### Cleanup Targets ###############################

# Refs:
# - https://www.calazan.com/docker-cleanup-commands/
# - http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers

docker-clean:
	@echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	@echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`

$(addprefix clean-,$(BASE_IMAGES) $(IMAGES)):
	rm -f $(STAMP_DIR)/*-$(subst clean-,,$@)

clean-all: $(addprefix clean-,$(BASE_IMAGES) $(IMAGES))

################################# Main Rules ##################################

$(BASE_IMAGES): %: $(STAMP_DIR)/build-%
$(IMAGES): %: $(STAMP_DIR)/push-%
$(BUILD_BASE_IMAGES) $(BUILD_IMAGES) $(TEST_IMAGES) $(PUSH_IMAGES): %: $(STAMP_DIR)/%

$(STAMPS): | $(STAMP_DIR) $(LOG_DIR)

$(BUILD_BASE_IMAGES_S): $(STAMP_DIR)/build-%: %/Dockerfile
	@echo Building $@ image
	$(call log, time docker build $(DOCKER_BUILD_FLAGS) \
		--tag=sagemath/$* $*, \
	    build-$*)
	echo $(call get_image_hash,sagemath/$*) > $@

# Build all release images
$(BUILD_RELEASE_IMAGES_S): $(STAMP_DIR)/build-%: %/Dockerfile
	@echo Building sagemath/$*
	$(call check_defined, SAGE_VERSION, Sage version to build)
	$(call log, time docker build $(DOCKER_BUILD_FLAGS) \
		--tag="sagemath/$*:$(SAGE_VERSION)" \
		--build-arg SAGE_BRANCH=$(SAGE_VERSION) $*, \
		build-$*)
ifeq ($(TAG_LATEST),1)
	docker tag "sagemath/$*:$(SAGE_VERSION)" "sagemath/$*:latest"
endif
	echo $(call get_image_hash,sagemath/$*:$(SAGE_VERSION)) > $@

# Builds the sagemath-develop and sagemath-patchbot images
$(BUILD_DEVELOP_IMAGES_S): $(STAMP_DIR)/build-%: %/Dockerfile
	@echo Building sagemath/$*
	$(call log, time docker build $(DOCKER_BUILD_FLAGS) \
		--tag="sagemath/$*" \
		--build-arg N_CORES=$(N_CORES) \
		--build-arg SAGE_BRANCH=develop \
		--build-arg SAGE_COMMIT=$(call get_git_hash, develop) $*,\
		build-$*)
	echo $(call get_image_hash,sagemath/$*) > $@

# Note: Don't test patchbot images since running the tests is part of building
# the image itself.
$(TEST_IMAGES_S): $(STAMP_DIR)/test-%: $(STAMP_DIR)/build-%
	@echo "Testing $*"
	$(call log, $(call sage_test, $*), test-$*)
	@echo "All tests passed"
	touch $@

$(NON_TEST_IMAGES_S): $(STAMP_DIR)/test-%: $(STAMP_DIR)/build-%
	touch $@

$(PUSH_IMAGES_S): $(STAMP_DIR)/push-%: $(STAMP_DIR)/build-% $(STAMP_DIR)/test-%
	@echo Pushing $*
	$(if $(or $(findstring -develop,$*),$(findstring -patchbot,$*)),\
		docker push "sagemath/$*",\
		$(call check_defined, SAGE_VERSION, Sage version to push) \
		docker push "sagemath/$*:$(SAGE_VERSION)")
ifeq ($(TAG_LATEST),1)
	$(if $(findstring -develop,$*),,docker push "sagemath/$*:latest")
endif
	touch $@

sagemath-local-develop: %: %/Dockerfile
	@echo Building $@ image
	time docker build $(DOCKER_BUILD_FLAGS) --tag=sagemath/$@ $(dir $<) 2>&1 | tee $<.log


$(STAMP_DIR) $(LOG_DIR):
	mkdir $@
