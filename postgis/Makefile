NAME=timescaledb-postgis
ORG=timescale
PG_VER=pg10
VERSION=$(shell awk -F ':' '/^FROM/ { print $$2 }' Dockerfile | sed "s/\(.*\)-.*/\1/")

default: image

.build_postgis_$(VERSION)_$(PG_VER): Dockerfile
ifeq ($(PG_VER),pg9.6)
	docker build --build-arg POSTGIS_VERSION=2.3.6 --build-arg PG_VERSION_TAG=$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER) .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):latest
else
	docker build --build-arg POSTGIS_VERSION=2.4.3 --build-arg PG_VERSION_TAG=$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER) .
endif
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	touch .build_postgis_$(VERSION)_$(PG_VER)

image: .build_postgis_$(VERSION)_$(PG_VER)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)
ifeq ($(PG_VER),pg9.6)
	docker push $(ORG)/$(NAME):latest
endif


clean:
	rm -f *~ .build_postgis_*

.PHONY: default image push clean
