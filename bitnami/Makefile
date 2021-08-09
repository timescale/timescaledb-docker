NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev
PG_VER=pg12
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)

TS_VERSION=master
PREV_TS_VERSION=$(shell wget --quiet -O - https://raw.githubusercontent.com/timescale/timescaledb/${TS_VERSION}/version.config | grep update_from_version | sed -e 's!update_from_version = !!')

# Beta releases should not be tagged as latest, so BETA is used to track.
BETA=$(findstring rc,$(TS_VERSION))
TAG_VERSION=$(ORG)/$(NAME):$(TS_VERSION)-$(PG_VER)-bitnami
TAG_LATEST=$(ORG)/$(NAME):latest-$(PG_VER)-bitnami
TAG=-t $(TAG_VERSION) $(if $(BETA),,-t $(TAG_LATEST))

default: image

.build_$(TS_VERSION)_$(PG_VER): Dockerfile
	test -n "$(TS_VERSION)"  # TS_VERSION
	test -n "$(PREV_TS_VERSION)"  # PREV_TS_VERSION
	docker build -f ./Dockerfile --build-arg PG_VERSION=$(PG_VER_NUMBER) --build-arg TS_VERSION=$(TS_VERSION) --build-arg PREV_TS_VERSION=$(PREV_TS_VERSION) $(TAG) ..
	touch .build_$(TS_VERSION)_$(PG_VER)-bitnami

image: .build_$(TS_VERSION)_$(PG_VER)

push: image
	docker push $(TAG_VERSION)
	if [ -z "$(BETA)" ]; then \
		docker push $(TAG_LATEST); \
	fi

clean:
	rm -f *~ .build_*

.PHONY: default image push clean
