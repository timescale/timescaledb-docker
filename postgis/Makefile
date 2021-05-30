NAME=timescaledb-postgis
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg12
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
VERSION=$(shell awk -F ':' '/^FROM/ { print $$2 }' Dockerfile | sed "s/\(.*\)-.*/\1/")
# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=$(findstring rc,$(VERSION))
PLATFORM=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64
# PUSH_MULTI can be set to nothing for dry-run without pushing during multi-arch build
PUSH_MUTLI=--push
TAG_VERSION=$(ORG)/$(NAME):$(VERSION)-$(PG_VER)
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))

default: image

.multi_postgis_$(VERSION)_$(PG_VER): Dockerfile
	docker buildx create --platform $(PLATFORM) --name multibuild --use
	docker buildx inspect multibuild --bootstrap
	docker buildx build --platform $(PLATFORM) --build-arg PG_VERSION=$(PG_VER_NUMBER) \
		$(TAG) $(PUSH_MUTLI) .
	touch .multi_$(VERSION)_$(PG_VER)
	docker buildx rm multibuild

.build_postgis_$(VERSION)_$(PG_VER): Dockerfile
	docker build --build-arg POSTGIS_VERSION=2.5.5 --build-arg PG_VERSION_TAG=$(PG_VER) $(TAG) .
	touch .build_postgis_$(VERSION)_$(PG_VER)

image: .build_postgis_$(VERSION)_$(PG_VER)

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(BETA)" ]; then \
		docker push $(TAG_LATEST); \
	fi

multi: .multi_postgis_$(VERSION)_$(PG_VER)


clean:
	rm -f *~ .build_postgis_* .multi_*
	docker buildx rm multibuild

.PHONY: default image push multi clean
