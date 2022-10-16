all: tools

clear-overlay:
	sudo rm -rf overlay
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

update-scripts:
	cp -R scripts overlay/base/

packages:
	./scripts/packages/build-packages.sh 

image:
	$(shell echo "Coming soon")
