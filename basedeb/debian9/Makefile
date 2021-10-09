IMAGE:=cnlubo/basedeb
all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build       - build the image"
	@echo "   2. make view        - view  the image"

build:
	@docker build --no-cache --tag=$(IMAGE) -f Dockerfile .

release:
	@docker build --no-cache --tag=$(IMAGE):$(shell cat VERSION)  \
	-f Dockerfile .
view:
	@docker run --rm -it  $(IMAGE):$(shell cat VERSION)
