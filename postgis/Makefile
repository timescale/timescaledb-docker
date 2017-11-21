NAME=timescaledb-postgis
ORG=timescale
PG_VER=pg10
VERSION=$(shell awk -F ':' '/^FROM/ { print $$2 }' Dockerfile-$(PG_VER))

default: image

.build_postgis_$(VERSION)_$(PG_VER): Dockerfile-$(PG_VER)
	docker build -f Dockerfile-$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER) .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):$(VERSION)
	touch .build_$(VERSION)

image: .build_postgis_$(VERSION)_$(PG_VER)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)

clean:
	rm -f *~ .build_postgis_*

.PHONY: default image push clean
