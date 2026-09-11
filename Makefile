NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg17
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
PG_MAJOR_VERSION=$(shell echo $(PG_VER_NUMBER) | cut -d. -f1)
ifeq ($(shell test $(PG_MAJOR_VERSION) -ge 16; echo $$?),0)
  ALPINE_VERSION=3.23
	CLANG_VERSION=21
else
  ALPINE_VERSION=3.22
	CLANG_VERSION=19
endif

TS_VERSION=main
# Resolve TS_VERSION to a commit. BuildKit keys the clone layer on the build
# args. A branch that moves must change the arg, or the cache serves stale
# sources.
TS_COMMIT=$(or $(shell git ls-remote https://github.com/timescale/timescaledb $(TS_VERSION) | head -n1 | cut -f1),$(TS_VERSION))
PREV_TS_VERSION=$(shell wget --quiet -O - https://raw.githubusercontent.com/timescale/timescaledb/${TS_VERSION}/version.config | grep -P "(previous_version|update_from_version)" | sed -e 's!^[a-z_]\+_version = !!')
PREV_TS_IMAGE="timescale/timescaledb:$(PREV_TS_VERSION)-pg$(PG_VER_NUMBER)$(PREV_EXTRA)"
# manifest inspect checks the registry without a pull. The builder pulls the image.
PREV_IMAGE=$(shell if docker manifest inspect $(PREV_TS_IMAGE) >/dev/null 2>&1; then echo "$(PREV_TS_IMAGE)"; else echo "postgres:$(PG_VER_NUMBER)-alpine"; fi )
# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=1
PLATFORM=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64

TAG_VERSION=$(ORG)/$(NAME):$(TS_VERSION)-$(PG_VER)
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))
TAG_OSS=-t $(TAG_VERSION)-oss $(if $(BETA),,-t $(TAG_LATEST)-oss)

PGVECTOR_VERSION=v0.8.1

COMMON_BUILD_ARGS= --build-arg TS_VERSION=$(TS_VERSION) \
		--build-arg TS_COMMIT=$(TS_COMMIT) \
		--build-arg PREV_IMAGE=$(PREV_IMAGE) \
		--build-arg PG_VERSION=$(PG_VER_NUMBER) \
		--build-arg PG_MAJOR_VERSION=$(PG_MAJOR_VERSION) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg CLANG_VERSION=$(CLANG_VERSION) \
		--build-arg PGVECTOR_VERSION=$(PGVECTOR_VERSION)

default: image

.build_$(TS_VERSION)_$(PG_VER)_oss: Dockerfile
	docker build $(COMMON_BUILD_ARGS) --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" $(TAG_OSS) .
	touch .build_$(TS_VERSION)_$(PG_VER)_oss

.build_$(TS_VERSION)_$(PG_VER): Dockerfile
	docker build $(COMMON_BUILD_ARGS) $(TAG) .
	touch .build_$(TS_VERSION)_$(PG_VER)

image: .build_$(TS_VERSION)_$(PG_VER)

oss: .build_$(TS_VERSION)_$(PG_VER)_oss

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(BETA)" ]; then \
		docker push $(TAG_LATEST); \
	fi

push-oss: oss
	docker push $(TAG_VERSION)-oss
	if [ -z "$(BETA)" ]; then \
		docker push $(TAG_LATEST)-oss; \
	fi

# CI builds one platform per job, pushes it by digest and keeps the build
# metadata in $(DIGESTS_DIR). publish-manifest tags the digests of all
# platforms as one image. Both need a docker-container builder.
DIGESTS_DIR=digests

# BuildKit layer cache in the GitHub Actions cache. DOCKER_CACHE_SCOPE turns
# it on. The gha cache type needs the Actions runtime env, so CI only.
ifneq ($(DOCKER_CACHE_SCOPE),)
  DOCKER_CACHE=--cache-from type=gha,scope=$(DOCKER_CACHE_SCOPE) \
	--cache-to type=gha,mode=max,scope=$(DOCKER_CACHE_SCOPE)
endif

build-platform:
	test -n "$(TS_VERSION)"  # TS_VERSION
	test -n "$(PREV_TS_VERSION)"  # PREV_TS_VERSION
	test -n "$(PREV_IMAGE)"  # PREV_IMAGE
	test -n "$(ALPINE_VERSION)"  # ALPINE_VERSION
	mkdir -p $(DIGESTS_DIR)
	docker buildx build --platform $(PLATFORM) $(COMMON_BUILD_ARGS) $(OSS_BUILD_ARGS) $(DOCKER_CACHE) \
		--output type=image,name=$(ORG)/$(NAME),push-by-digest=true,name-canonical=true,push=true \
		--metadata-file $(DIGESTS_DIR)/$(subst /,-,$(PLATFORM)).json .

build-platform-oss: OSS_BUILD_ARGS=--build-arg OSS_ONLY=" -DAPACHE_ONLY=1"
build-platform-oss: build-platform

MANIFEST_TAGS=$(TAG)
publish-manifest:
	docker buildx imagetools create $(MANIFEST_TAGS) \
		$$(jq -r '"$(ORG)/$(NAME)@" + ."containerimage.digest"' $(DIGESTS_DIR)/*.json)

publish-manifest-oss: MANIFEST_TAGS=$(TAG_OSS)
publish-manifest-oss: publish-manifest

clean:
	rm -f *~ .build_*
	rm -rf $(DIGESTS_DIR)

.PHONY: default image push push-oss oss clean \
	build-platform build-platform-oss publish-manifest publish-manifest-oss
