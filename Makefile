# Images and their dependencies
IMAGES=sagemath sagemath-develop sagemath-jupyter sagemath-patchbot
BUILD_IMAGES=$(addprefix build-,$(IMAGES))
TEST_IMAGES=$(addprefix test-,$(IMAGES))
PUSH_IMAGES=$(addprefix push-,$(IMAGES))
.PHONY: all build push docker-clean $(IMAGES) $(BUILD_IMAGES) $(TEST_IMAGES) $(PUSH_IMAGES)

SAGE_VERSION ?= 7.4
TAG_LATEST ?= 1

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
	time docker build $(DOCKER_BUILD_FLAGS) --tag="sagemath/$*:$(SAGE_VERSION)" --build-arg SAGE_BRANCH=$(SAGE_VERSION) $* 2>&1 | tee $*.log
ifeq ($(TAG_LATEST),1)
	docker tag "sagemath/$*:$(SAGE_VERSION)" "sagemath/$*:latest"
endif

$(filter build-%-develop, $(BUILD_IMAGES)): build-%-develop: %/Dockerfile
	@echo Building sagemath/$*-develop
	time docker build $(DOCKER_BUILD_FLAGS) --tag="sagemath/$*-develop" --build-arg SAGE_BRANCH=develop $* 2>&1 | tee $*-develop.log

$(TEST_IMAGES): test-%: build-%
	@echo Testing $*
	docker run sagemath/$* sage -t -a --long
	@echo "All tests passed"

$(PUSH_IMAGES): push-%: build-% test-%
	@echo Pushing $*
	$(if $(findstring -develop,$*),docker push "sagemath/$*",docker push "sagemath/$*:$(SAGE_VERSION)")
ifeq ($(TAG_LATEST),1)
	$(if $(findstring -develop,$*),,docker push "sagemath/$*:latest")
endif

# TODO: run ptestlong inside the docker image and report
