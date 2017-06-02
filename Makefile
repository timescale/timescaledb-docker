NAME=timescaledb
ORG=timescale
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)

default: image

.build_$(VERSION): Dockerfile
	docker build -t $(ORG)/$(NAME) .
	docker tag $(ORG)/$(NAME):latest $(ORG)/$(NAME):$(VERSION)
	touch .build_$(VERSION)

image: .build_$(VERSION)

push: image
	docker push $(ORG)/$(NAME):latest
	docker push $(ORG)/$(NAME):$(VERSION)

clean:
	rm -f *~

.PHONY: default image push clean
