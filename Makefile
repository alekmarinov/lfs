all: tools

cleanup:
	rm -rf overlay tmp
	mkdir -pv tmp overlay/base overlay/package overlay/work overlay/lfs
	cp -R scripts overlay/base/
	cp -R sources overlay/base/
	chmod -R +x overlay/base/scripts

docker: cleanup
	docker build -t lfs\:11.2 .

tools: docker
	docker run --rm -v $(shell pwd)/overlay/base\:/mnt/base lfs\:11.2

packages: tools
	./scripts/packages/build-packages.sh 
	mkdir -pv packages
	mv -f tmp/*.tar.gz ./packages

image: packages
	LFS="overlay/base" ./scripts/image/build-image.sh

update-scripts:
	cp -R scripts overlay/base/
