NAME=timescaledb
ORG=timescale
PG_VER=pg10
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)

default: image

.build_$(VERSION)_$(PG_VER): Dockerfile
ifeq ($(PG_VER),pg9.6)
	docker build -f ./Dockerfile --build-arg PG_VERSION=9.6.13 -t $(ORG)/$(NAME):latest-$(PG_VER)-bitnami ..
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-bitnami $(ORG)/$(NAME):latest-bitnami
else ifeq ($(PG_VER),pg10)
	docker build -f ./Dockerfile --build-arg PG_VERSION=10.8.0 -t $(ORG)/$(NAME):latest-$(PG_VER)-bitnami ..
else
	docker build -f ./Dockerfile --build-arg PG_VERSION=11.3.0 -t $(ORG)/$(NAME):latest-$(PG_VER)-bitnami ..
endif
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-bitnami $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-bitnami
	touch .build_$(VERSION)_$(PG_VER)-bitnami

image: .build_$(VERSION)_$(PG_VER)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-bitnami
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-bitnami

clean:
	rm -f *~ .build_*

.PHONY: default image push clean
