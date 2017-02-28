# Images and their dependencies
IMAGES=sagemath sagemath-develop sagemath-jupyter sagemath-patchbot
BUILD_IMAGES=$(addprefix build-,$(IMAGES))
TEST_IMAGES=$(addprefix test-,$(IMAGES))
PUSH_IMAGES=$(addprefix push-,$(IMAGES))
.PHONY: all build push docker-clean $(IMAGES) $(BUILD_IMAGES) $(TEST_IMAGES) $(PUSH_IMAGES)

SAGE_GIT_URL=git://git.sagemath.org/sage.git
# Rather than hard-coding a default, this variable should always be specified
# when building a non-develop version.
SAGE_VERSION ?=
check_defined = \
	$(if $(value $(strip $1)),,$(error Undefined $(strip $1)$(if $2, ($(strip $2)))))
get_git_hash = \
	$$(git ls-remote --heads $(SAGE_GIT_URL) $1 | \
	   grep 'refs/heads/$(strip $1)' | awk '{print $$1}')

TAG_LATEST ?= 0

all: $(IMAGES)

release: sagemath sagemath-jupyter

sagemath:

sagemath-develop:

sagemath-jupyter: sagemath

sagemath-patchbot: sagemath-develop

# Main rules

$(IMAGES): %: build-% test-% push-%

build: $(BUILD_IMAGES)
test: $(TEST_IMAGES)
push: $(PUSH_IMAGES)

# Refs:
# - https://www.calazan.com/docker-cleanup-commands/
# - http://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers
docker-clean:
	@echo "Remove all non running containers"
	-docker rm `docker ps -q -f status=exited`
	@echo "Delete all untagged/dangling (<none>) images"
	-docker rmi `docker images -q -f dangling=true`


$(filter-out build-%-develop, $(BUILD_IMAGES)): build-%: %/Dockerfile
	@echo Building sagemath/$*
	$(call check_defined, SAGE_VERSION, Sage version to build)
	time docker build $(DOCKER_BUILD_FLAGS) \
		--tag="sagemath/$*:$(SAGE_VERSION)" \
		--build-arg SAGE_BRANCH=$(SAGE_VERSION) $* 2>&1 | tee $*.log
ifeq ($(TAG_LATEST),1)
	docker tag "sagemath/$*:$(SAGE_VERSION)" "sagemath/$*:latest"
endif

$(filter build-%-develop, $(BUILD_IMAGES)): build-%-develop: %/Dockerfile
	@echo Building sagemath/$*-develop
	time docker build $(DOCKER_BUILD_FLAGS) \
		--tag="sagemath/$*-develop" \
		--build-arg SAGE_BRANCH=develop \
		--build-arg SAGE_COMMIT=$(call get_git_hash, develop) \
		$* 2>&1 | tee $*-develop.log

$(TEST_IMAGES): test-%: build-%
	@echo Testing $*
	$(if $(findstring -develop,$*), \
		docker run --rm sagemath/$* sage -t -p 0 -a --long, \
		$(call check_defined, SAGE_VERSION, Sage version to test) \
		docker run --rm sagemath/$*:$(SAGE_VERSION) sage -t -p 0 -a --long \
	)
	@echo "All tests passed"

$(PUSH_IMAGES): push-%: build-% test-%
	@echo Pushing $*
	$(if $(findstring -develop,$*),docker push "sagemath/$*",\
		$(call check_defined, SAGE_VERSION, Sage version to push) \
		docker push "sagemath/$*:$(SAGE_VERSION)")
ifeq ($(TAG_LATEST),1)
	$(if $(findstring -develop,$*),,docker push "sagemath/$*:latest")
endif
