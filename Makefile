all: tools

clear-overlay:
	rm -rf overlay
	mkdir -pv tmp overlay/base
	mkdir -pv tmp overlay/package
	mkdir -pv tmp overlay/work
	mkdir -pv tmp overlay/lfs
	cp -R scripts overlay/base/
	cp -R sources overlay/base/
	chmod -R +x overlay/base/scripts

docker: clear-overlay
	docker build -t lfs\:11.2 .

tools: docker
	docker run --rm -v $(shell pwd)/overlay/base\:/mnt/base lfs\:11.2

packages: tools
	./scripts/packages/build-packages.sh 

image: packages
	LFS="overlay/base" ./scripts/image/build-image.sh

update-scripts:
	cp -R scripts overlay/base/
