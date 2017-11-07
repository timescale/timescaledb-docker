NAME=timescaledb
ORG=timescale
VERSION=$(shell awk '/^ENV TIMESCALEDB_VERSION/ {print $$3}' Dockerfile)

default: image

.build_$(VERSION): Dockerfile backup_init.sh
	docker build -t $(ORG)/$(NAME) .
	docker tag $(ORG)/$(NAME):latest $(ORG)/$(NAME):$(VERSION)
	touch .build_$(VERSION)

image: .build_$(VERSION)

push: image
	docker push $(ORG)/$(NAME):$(VERSION)
	docker push $(ORG)/$(NAME):latest

clean:
	rm -f *~

.PHONY: default image push clean
