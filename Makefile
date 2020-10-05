NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev 
PG_VER=pg12
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)
# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=$(findstring -,$(VERSION))
PLATFORM=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64
# PUSH_MULTI can be set to nothing for dry-run without pushing during multi-arch build
PUSH_MUTLI=--push
TAG_VERSION=$(ORG)/$(NAME):$(VERSION)-$(PG_VER)
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))
TAG_OSS=-t $(TAG_VERSION)-oss $(if $(BETA),,-t $(TAG_LATEST)-oss)

default: image

.multi_$(VERSION)_$(PG_VER)_oss: Dockerfile
	docker buildx create --platform $(PLATFORM) --name multibuild --use
	docker buildx inspect multibuild --bootstrap
	docker buildx build --platform $(PLATFORM) --build-arg PREV_EXTRA="-oss" --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" --build-arg PG_VERSION=$(PG_VER_NUMBER) \
		$(TAG_OSS) $(PUSH_MUTLI) .
	touch .multi_$(VERSION)_$(PG_VER)_oss
	docker buildx rm multibuild

.multi_$(VERSION)_$(PG_VER): Dockerfile
	docker buildx create --platform $(PLATFORM) --name multibuild --use
	docker buildx inspect multibuild --bootstrap
	docker buildx build --platform $(PLATFORM) --build-arg PG_VERSION=$(PG_VER_NUMBER) \
		$(TAG) $(PUSH_MUTLI) .
	touch .multi_$(VERSION)_$(PG_VER)
	docker buildx rm multibuild

.build_$(VERSION)_$(PG_VER)_oss: Dockerfile
	docker build --build-arg PREV_EXTRA="-oss" --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" --build-arg PG_VERSION=$(PG_VER_NUMBER) $(TAG_OSS) .
	touch .build_$(VERSION)_$(PG_VER)_oss

.build_$(VERSION)_$(PG_VER): Dockerfile
	docker build --build-arg PG_VERSION=$(PG_VER_NUMBER) $(TAG) .
	touch .build_$(VERSION)_$(PG_VER)

image: .build_$(VERSION)_$(PG_VER)

oss: .build_$(VERSION)_$(PG_VER)_oss

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

multi: .multi_$(VERSION)_$(PG_VER)

multi-oss: .multi_$(VERSION)_$(PG_VER)_oss

all: multi multi-oss

clean:
	rm -f *~ .build_* .multi_*
	docker buildx rm multibuild

.PHONY: default image push push-oss oss multi multi-oss clean all
