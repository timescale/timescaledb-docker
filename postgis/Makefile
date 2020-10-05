NAME=timescaledb-postgis
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg12
VERSION=$(shell awk -F ':' '/^FROM/ { print $$2 }' Dockerfile | sed "s/\(.*\)-.*/\1/")
# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=$(findstring -,$(VERSION))
TAG_VERSION=$(ORG)/$(NAME):$(VERSION)-$(PG_VER)
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))

default: image

.build_postgis_$(VERSION)_$(PG_VER): Dockerfile
	docker build --build-arg POSTGIS_VERSION=2.5.3 --build-arg PG_VERSION_TAG=$(PG_VER) $(TAG) .
	touch .build_postgis_$(VERSION)_$(PG_VER)

image: .build_postgis_$(VERSION)_$(PG_VER)

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(BETA)" ]; then \
		docker push $(TAG_LATEST); \
	fi


clean:
	rm -f *~ .build_postgis_*

.PHONY: default image push clean
