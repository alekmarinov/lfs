.PHONY: clean image minimal-distro update-scripts packages-continue \
	    build-package find-package-file install-package

SHELL=/bin/bash
LFS_VER=11.2
TARGET_TOOLS=lfs-tools-$(LFS_VER).tar.gz
TARGET_ROOTFS=lfs-rootfs-$(LFS_VER).tar.gz

include .env
export
export MAKEFLAGS="--jobs=$(JOB_COUNT)"

all:
	@echo -e "\
Welcome to LFS linux building tool!\n\n\
To build a bootable image run\n\n\
	sudo make image \n\n\
or pick up one of the available targets:\n\
clean      - Sets an initial state\n\
image      - Builds uefi bootable image\n\
min-distro - Creates rootfs partition with minimum set of packages.\n\
"

clean:
	@echo -n "Removing overlay tmp rootfs $(LFS_PACKAGES) [y/N] " \
		&& read ans && [ $${ans:-N} = y ]
	rm -rf overlay tmp rootfs $(LFS_PACKAGES) $(TARGET_TOOLS) $(TARGET_ROOTFS)

$(TARGET_TOOLS):
	mkdir -p $(LFS_BASE)
	cp -R scripts $(LFS_BASE)
	cp -R sources $(LFS_BASE)
	chmod -R +x $(LFS_BASE)/scripts
	docker build -t lfs\:$(LFS_VER) .
	docker run \
		--rm \
		-v $(shell pwd)/$(LFS_BASE)\:/$(LFS_BASE) \
		--env-file .env \
		lfs\:$(LFS_VER)
	@echo Packing $@...
	tar cfz $@ -C $(LFS_BASE)

$(TARGET_ROOTFS): $(TARGET_TOOLS)
	rm -rf    tmp overlay/work $(LFS) $(LFS_BASE) $(LFS_PACKAGE) $(LFS_PACKAGES) 
	mkdir -pv tmp overlay/work $(LFS) $(LFS_BASE) $(LFS_PACKAGE) $(LFS_PACKAGES) 
	@echo "Unpacking base..."
	tar xf $< -C $(LFS_BASE) .
	./scripts/packages/build-packages.sh
	@echo Packing $@...
	tar cfz --exclude='./sources' --exclude='./scripts' --exclude='./tools' $@ -C $(LFS_BASE) .
	@echo "Here you are $@"

packages-continue:
	./scripts/packages/build-packages.sh
	@echo Packing $@...
	tar cfz --exclude='./sources' --exclude='./scripts' --exclude='./tools' $@ -C $(LFS_BASE) .
	@echo "Here you are $@"


image: $(TARGET_ROOTFS)
	./scripts/image/build-image.sh $<

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
