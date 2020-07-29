IMAGE:=cnlubo/nginx
all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build       - build image"
	@echo "   2. make view        - view  image"
	@echo "   3. make quickstart  - quickstart nginx"
	@echo "   4. make logs        - view logs"
	@echo "   5. make stop        - stop container"
	@echo "   6. make purge       - stop and remove"

build:
	@docker build --tag=$(IMAGE) -f Dockerfile .
release:
	@docker build --tag=$(IMAGE):$(shell cat VERSION) -f Dockerfile .
view:
	@docker run --rm -it  $(IMAGE):$(shell cat VERSION) bash

quickstart:
	@docker run --name=nginx-demo -d -p 80:80 \
	        -v /var/run/docker.sock:/run/docker.sock \
	        -v $(shell which docker):/bin/docker \
			$(IMAGE):$(shell cat VERSION)>/dev/null

stop:
	@echo "Stopping NGINX..."
	@docker stop nginx-demo >/dev/null

purge: stop
	@echo "Removing stopped container..."
	@docker rm nginx-demo >/dev/null

logs:
	@docker logs -f nginx-demo
