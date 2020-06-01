NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg12
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)

default: image

.build_$(VERSION)_$(PG_VER): Dockerfile
	docker build -f ./Dockerfile --build-arg PG_VERSION=$(PG_VER_NUMBER) -t $(ORG)/$(NAME):latest-$(PG_VER)-bitnami ..
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-bitnami $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-bitnami
	touch .build_$(VERSION)_$(PG_VER)-bitnami

image: .build_$(VERSION)_$(PG_VER)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-bitnami
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-bitnami

clean:
	rm -f *~ .build_*

.PHONY: default image push clean
