NAME=timescaledb-postgis
ORG=timescale
PG_VER=pg11
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
VERSION=$(shell awk -F ':' '/^FROM/ { print $$2 }' Dockerfile | sed "s/\(.*\)-.*/\1/")

default: image

.build_postgis_$(VERSION)_$(PG_VER)-bitnami: Dockerfile
	docker build --build-arg POSTGIS_VERSION=2.5.2 --build-arg PG_VERSION=$(PG_VER_NUMBER) --build-arg PG_VERSION_TAG=$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER)-bitnami .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-bitnami $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	touch .build_postgis_$(VERSION)_$(PG_VER)-bitnami

image: .build_postgis_$(VERSION)_$(PG_VER)-bitnami

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)


clean:
	rm -f *~ .build_postgis_*

.PHONY: default image push clean
