NAME=timescaledb
ORG=timescale
PG_VER=pg10
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile-$(PG_VER))

default: image

.build_$(VERSION)_$(PG_VER): Dockerfile-$(PG_VER) backup_init.sh
	docker build -f Dockerfile-$(PG_VER) -t $(ORG)/$(NAME):latest-$(PG_VER) .
	docker tag $(ORG)/$(NAME):latest-$(PG_VER) $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	touch .build_$(VERSION)

image: .build_$(VERSION)_$(PG_VER)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)-$(PG_VER)
	docker push $(ORG)/$(NAME):latest-$(PG_VER)

clean:
	rm -f *~ .build_*

.PHONY: default image push clean
