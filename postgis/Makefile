NAME=timescaledb-postgis
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg12
VERSION=$(shell awk -F ':' '/^FROM/ { print $$2 }' Dockerfile | sed "s/\(.*\)-.*/\1/")

default: image

.build_postgis_$(VERSION)_$(PG_VER): Dockerfile
	docker build --build-arg POSTGIS_VERSION=2.5.3 --build-arg PG_VERSION_TAG=$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER) .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	touch .build_postgis_$(VERSION)_$(PG_VER)

image: .build_postgis_$(VERSION)_$(PG_VER)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)


clean:
	rm -f *~ .build_postgis_*

.PHONY: default image push clean
