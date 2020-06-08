NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg12
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)
# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=$(findstring beta,$(VERSION))
TAG_VERSION=$(ORG)/$(NAME):$(VERSION)-$(PG_VER)-bitnami
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)-bitnami
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))

default: image

.build_$(VERSION)_$(PG_VER): Dockerfile
	docker build -f ./Dockerfile --build-arg PG_VERSION=$(PG_VER_NUMBER) $(TAG) ..
	touch .build_$(VERSION)_$(PG_VER)-bitnami

image: .build_$(VERSION)_$(PG_VER)

push: image
	docker push $(TAG_VERSION)
	ifndef $(BETA)
		docker push $(TAG_LATEST)
	endif

clean:
	rm -f *~ .build_*

.PHONY: default image push clean
