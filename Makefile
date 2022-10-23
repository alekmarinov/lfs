.PHONY: cleanup docker tools image minimal-distro  update-scripts
SHELL := /bin/bash

include .env
export

all:
	@echo -e "\
Welcome to LFS making tool!\n\n\
To build a bootable image run\n\n\
	sudo make image \n\n\
or pick up one of the available targets:\n\
tools      - Build tools needed to build packages. The result goes into 'overlay/base' directory.\n\
cleanup    - Clears 'overlay' and 'tmp' directories for clean build of the packages.\n\
packages   - Builds packages, depends on tools.\n\
image      - Builds uefi bootable image, by running grub-install in chroot-ed overlay/base.\n\
             grub and all dependent packages must be already built, depends on packages.\n\
min-distro - Prepares a linux partition image with minimum set of packages.\n\
update-scripts - Copy the scripts from git location under 'overlay/base'. Development only.\
"

cleanup:
	rm -rf overlay tmp rootfs
	mkdir -pv tmp $(LFS_BASE) $(LFS_PACKAGE) overlay/work $(LFS)
	cp -R scripts $(LFS_BASE)
	cp -R sources $(LFS_BASE)
	chmod -R +x $(LFS_BASE)/scripts

tools: cleanup
	docker build -t lfs\:11.2 .
	docker run \
		--rm \
		-v $(shell pwd)/$(LFS_BASE)\:/$(LFS_BASE) \
		--env-file .env \
		lfs\:11.2

packages: tools
	./scripts/packages/build-packages.sh
	mkdir -pv packages
	mv -f tmp/*.tar.gz ./packages

image: packages
	.scripts/image/build-image.sh

min-distro:
	./scripts/image/build-distro.sh minimal

update-scripts:
	cp -R scripts $(LFS_BASE)
	chmod -R +x $(LFS_BASE)/scripts

build-package:
	./scripts/packages/build-package.sh $(shell find scripts/packages -name $(PACKAGE))

find-package-file:
	./scripts/packages/find-package-file.sh $(FILE)

install-package:
	./scripts/packages/install-package.sh $(PACKAGE)
