NAME=timescaledb-postgis
ORG=timescale
VERSION=$(shell awk -F ':' '/^FROM/ { print $$2 }' Dockerfile)

default: image

.build_postgis_$(VERSION): Dockerfile
	docker build -t $(ORG)/$(NAME) .
	docker tag $(ORG)/$(NAME):latest $(ORG)/$(NAME):$(VERSION)
	touch .build_$(VERSION)

image: .build_postgis_$(VERSION)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)
	docker push $(ORG)/$(NAME):latest

clean:
	rm -f *~

.PHONY: default image push clean
