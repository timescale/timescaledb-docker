NAME?=timescaledb
ORG?=timescale
PG_VER?=pg10
VERSION?=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)

default: image

.build_$(VERSION)_$(PG_VER): Dockerfile
ifeq ($(PG_VER),pg9.6)
	docker build --build-arg PG_VERSION=9.6.10 -t $(ORG)/$(NAME):latest-$(PG_VER) .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):latest
else ifeq ($(PG_VER),pg10)
	docker build --build-arg PG_VERSION=10.5 -t $(ORG)/$(NAME):latest-$(PG_VER) .
else
	docker build --build-arg PG_VERSION=11.1 -t $(ORG)/$(NAME):latest-$(PG_VER) .
endif
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	touch .build_$(VERSION)_$(PG_VER)

image: .build_$(VERSION)_$(PG_VER)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)
ifeq ($(PG_VER),pg9.6)
	docker push $(ORG)/$(NAME):latest
endif

clean:
	rm -f *~ .build_*

.PHONY: default image push clean
