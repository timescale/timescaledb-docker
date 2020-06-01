NAME=timescaledb
# Default is to timescaledev to avoid unexpected push to the main repo
# Set ORG to timescale in the caller
ORG=timescaledev 
PG_VER=pg12
PG_VER_NUMBER=$(shell echo $(PG_VER) | cut -c3-)
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)
PLATFORM=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64

default: image

.multi_$(VERSION)_$(PG_VER)_oss: Dockerfile
	docker buildx create --platform $(PLATFORM) --name multibuild --use
	docker buildx inspect multibuild --bootstrap
	docker buildx build --platform $(PLATFORM) --build-arg PREV_EXTRA="-oss" --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" --build-arg PG_VERSION=$(PG_VER_NUMBER) \
		-t $(ORG)/$(NAME):latest-$(PG_VER)-oss -t $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-oss --push .
	touch .multi_$(VERSION)_$(PG_VER)_oss
	docker buildx rm multibuild

.multi_$(VERSION)_$(PG_VER): Dockerfile
	docker buildx create --platform $(PLATFORM) --name multibuild --use
	docker buildx inspect multibuild --bootstrap
	docker buildx build --platform $(PLATFORM) --build-arg PG_VERSION=$(PG_VER_NUMBER) \
		-t $(ORG)/$(NAME):latest-$(PG_VER) -t $(ORG)/$(NAME):$(VERSION)-$(PG_VER) --push .
	touch .multi_$(VERSION)_$(PG_VER)
	docker buildx rm multibuild

.build_$(VERSION)_$(PG_VER)_oss: Dockerfile
	docker build --build-arg PREV_EXTRA="-oss" --build-arg OSS_ONLY=" -DAPACHE_ONLY=1" --build-arg PG_VERSION=$(PG_VER_NUMBER) -t $(ORG)/$(NAME):latest-$(PG_VER)-oss .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER)-oss $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-oss
	touch .build_$(VERSION)_$(PG_VER)_oss

.build_$(VERSION)_$(PG_VER): Dockerfile
	docker build --build-arg PG_VERSION=$(PG_VER_NUMBER) -t $(ORG)/$(NAME):latest-$(PG_VER) .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	touch .build_$(VERSION)_$(PG_VER)

image: .build_$(VERSION)_$(PG_VER)

oss: .build_$(VERSION)_$(PG_VER)_oss

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)

push-oss: oss
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)-oss
	docker push $(ORG)/$(NAME):latest-$(PG_VER)-oss

multi: .multi_$(VERSION)_$(PG_VER)

multi-oss: .multi_$(VERSION)_$(PG_VER)_oss

all: multi multi-oss

clean:
	rm -f *~ .build_* .multi_*
	docker buildx rm multibuild

.PHONY: default image push push-oss oss multi multi-oss clean all
