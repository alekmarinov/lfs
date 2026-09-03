.PHONY: all clean packages packages-continue distro check docker image qemu \
	    distro-packages deps why closure deps-check deps-declared deps-order deps-verify file-index \
	    packages-lint packages-meta abi repo repo-verify base-gap test test-boot \
	    update-scripts build-package find-package-file install-package

SHELL=/bin/bash
TARGET_TOOLS=lfs-tools-$(LFS_VER).tar.gz

# .env is read as a makefile, so everything in it has file origin, which beats
# the environment. That makes 'IMAGE_SIZE=2000 make image' look like it works
# while the .env value is used instead - the setting is ignored and nothing is
# said about it. The names .env defines are saved here when they came from the
# environment and put back after the include, so the environment wins. A
# variable given on the command line still beats both, make keeps those.
#
# NOTE .env has to stay plain KEY=VALUE lines: docker reads it with --env-file
# and build-package.sh with 'cat .env | xargs', neither of which parses make
# syntax, so '?=' cannot be used there instead of this.
ENV_NAMES := $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)
$(foreach v,$(ENV_NAMES),\
    $(if $(filter environment,$(origin $(v))),$(eval __ENV_$(v) := $($(v)))))

include .env

$(foreach v,$(ENV_NAMES),\
    $(if $(filter-out undefined,$(origin __ENV_$(v))),$(eval $(v) := $(__ENV_$(v)))))

export
export MAKEFLAGS="--jobs=$(JOB_COUNT)"

PACKAGES_STAMP=$(LFS_PACKAGES)/.built

# the distro to assemble: a name under distros/, or a path to one anywhere
DISTRO?=minimal

# Where its rootfs and image are written - one directory per distro, so two
# can be built side by side. Every image-side script derives this the same way
# from the same DISTRO; it is computed here only so the help text can show it.
# A client building its own distro passes its own OUT and keeps its output in
# its own tree.
OUT ?= $(shell ./scripts/resolve-distro.sh -o $(DISTRO) 2>/dev/null)
export OUT
# the tag the assembled distro is archived under
TAG?=$(shell date +%Y%m%d)

all:
	@echo -e "\
Welcome to LFS linux building tool!\n\n\
A distro is built in four steps:\n\n\
\tsudo make packages              - builds every package from source, once\n\
\tmake distro DISTRO=$(DISTRO)    - assembles it into $(OUT)/rootfs\n\
\tmake image                      - turns $(OUT)/rootfs into a bootable image\n\
\tmake qemu                       - boots $(OUT)/image.img\n\n\
A distro which brings recipes of its own builds them between the first two:\n\n\
\tsudo make distro-packages DISTRO=$(DISTRO)\n\n\
and the assembled rootfs can be checked and archived with:\n\n\
\tmake check                      - resolves every program against $(OUT)/rootfs\n\
\tmake docker TAG=$(TAG)      - archives $(OUT)/rootfs as a docker image\n\n\
Available distros: $(shell ls -m distros | sed 's/core, //')\n\
"

clean:
	@echo -n "Removing overlay tmp build $(LFS_PACKAGES) $(TARGET_TOOLS) [y/N] " \
		&& read ans && [ $${ans:-N} = y ]
	sudo rm -rf overlay tmp build $(LFS_PACKAGES) $(TARGET_TOOLS)

$(TARGET_TOOLS):
	mkdir -p $(LFS_BASE)
	cp -R scripts $(LFS_BASE)
	cp -R sources $(LFS_BASE)
	chmod -R +x $(LFS_BASE)/scripts
	docker build -t lfs\:$(LFS_VER) .
	docker run \
		--rm \
		--network host \
		-v $(shell pwd)/$(LFS_BASE)\:/$(LFS_BASE) \
		--env-file .env \
		lfs\:$(LFS_VER)
	@echo Packing $@...
	tar cfz $@ -C $(LFS_BASE) .

# Builds every package from source into $(LFS_PACKAGES)
packages: $(PACKAGES_STAMP)

$(PACKAGES_STAMP): $(TARGET_TOOLS)
	rm -rf    tmp overlay/work $(LFS) $(LFS_BASE) $(LFS_PACKAGE) $(LFS_PACKAGES)
	mkdir -pv tmp overlay/work $(LFS) $(LFS_BASE) $(LFS_PACKAGE) $(LFS_PACKAGES)
	@echo "Unpacking base..."
	tar xf $< -C $(LFS_BASE) .
	./scripts/packages/build-packages.sh
	touch $@

# Resumes an interrupted package build without starting over
packages-continue:
	./scripts/packages/build-packages.sh
	touch $(PACKAGES_STAMP)

# Builds the recipes $(DISTRO) brings of its own into the shared package cache.
# 'make packages' stays distro agnostic and expensive; this is the small
# incremental build on top of it, and a distro with no recipes of its own needs
# it not at all.
distro-packages:
	./scripts/packages/build-distro-packages.sh $(DISTRO)

# Assembles $(DISTRO) into $(OUT)/rootfs
distro:
	./scripts/image/build-distro.sh $(DISTRO)

# Resolves every program of $(OUT)/rootfs against its own libraries
check:
	./scripts/image/check-distro.sh $(DISTRO)

# Archives rootfs/ as the docker image <distro id>:$(TAG)
docker:
	EXPECT_DISTRO=$(if $(filter command line,$(origin DISTRO)),$(DISTRO)) \
		./scripts/image/build-docker.sh $(DISTRO) $(TAG)

# Turns $(OUT)/rootfs into the bootable $(OUT)/image.img
#
# It takes the same DISTRO as 'make distro', because that is what says which
# output directory to read. EXPECT_DISTRO stays as a cheap assertion that the
# rootfs found there really is the one named - it used to be the only guard
# against imaging the wrong tree, when every distro shared one rootfs/.
image:
	EXPECT_DISTRO=$(if $(filter command line,$(origin DISTRO)),$(DISTRO)) \
		./scripts/image/build-image.sh $(DISTRO)

# Checks what every recipe declares about the package it builds
#
# Worth running before 'make packages': an unpinned source glob resolves to
# two tarballs and fails hours into the build, and a missing version is not
# visible until a package is published.
packages-lint:
	@./scripts/packages/lint-packages.sh

# Collects what every built package says about itself into one index
#
# Packages built since build-package.sh started recording it carry their own
# provides and requires; older ones are scanned once and cached. Nothing has
# to be rebuilt for this.
packages-meta:
	./scripts/packages/build-meta.sh

# The fingerprint of the core the packages were compiled against
#
# It keys the package repository and is stamped into /etc/os-release, so a
# system can tell whether a published package matches the glibc it has.
# 'make abi ARGS=-v' also lists what went into it.
abi:
	@./scripts/packages/abi-id.sh $(ARGS)

# Publishes the built packages as a signed repository under repo/<abi>/<arch>
#
# Hardlinks the packages out of the cache, so it costs no disk when repo/ is
# on the same filesystem. ARGS passes options through - --no-sign to skip
# signing, --force-stale to publish a recipe whose text changed without a
# RELEASE bump, -o to publish somewhere else.
repo:
	./scripts/packages/build-repo.sh $(ARGS)

# Checks a published channel the way a system installing from it would
#
# Signature, then every package's size and hash, then whether every soname the
# channel requires is provided within it. ARGS=--quick skips the hashes;
# ARGS="--pub <key>" verifies against the key an image actually trusts.
repo-verify:
	@./scripts/packages/verify-repo.sh $(ARGS)

# What is in the build base and in no package
#
# The tools build installs directly into the base, so those files belong to no
# recipe. Assembly makes the few that matter by hand; anything reconstructing a
# root out of packages alone - 'lpkg --root' and 'lpkg build' - does not.
base-gap:
	@./scripts/packages/base-gap.sh $(ARGS)

# Derives the dependency graph from the built packages
#
# Reads the metadata index rather than the packages, so it is cheap enough to
# run after anything is rebuilt. It refreshes the index first.
deps:
	./scripts/packages/build-deps.sh

# Lists the files under /etc and /var which several packages ship
file-index:
	./scripts/packages/build-file-index.sh

# What a package needs, and what needs it
why:
	@./scripts/packages/query-deps.sh why $(PACKAGE)

# Everything the named packages pull in
closure:
	@./scripts/packages/query-deps.sh closure $(PACKAGES)

# Whether each distro's package list holds everything its libraries need
deps-check:
	@./scripts/packages/query-deps.sh check $(DISTROS)

# Declared build dependencies against the derived graph
deps-declared:
	@./scripts/packages/query-deps.sh declared

# An order satisfying the declared build dependencies, rebuilds included
deps-order:
	@./scripts/packages/order-deps.sh order

# Whether build-packages.sh already satisfies the declarations
deps-verify:
	@./scripts/packages/order-deps.sh verify

# Exercises lpkg against the assembled rootfs, in a container
#
# The scratch trees lpkg is developed against are not a system - no /proc, no
# /dev, no FHS symlinks - and every one of those gaps has hidden a real bug.
# This runs it on what build-distro.sh actually produced. Needs 'make distro'
# and 'make repo' first.
test:
	./scripts/test-lpkg.sh $(DISTRO)

# Boots the image under qemu and checks lpkg on the running system
#
# The level above 'make test': same rootfs, but with firmware, a kernel, init
# and a network. Works on a copy of the image and serves repo/ over http to
# the guest, so it needs 'make image' and 'make repo' first.
test-boot:
	./scripts/test-boot.sh $(DISTRO)

# Boots $(OUT)/image.img
qemu:
	./scripts/image/qemu.sh $(DISTRO) $(QEMU_ARGS)

update-scripts:
	cp -R scripts $(LFS_BASE)
	chmod -R +x $(LFS_BASE)/scripts

build-package:
	./scripts/packages/build-package.sh -f $(shell find scripts/packages -name $(PACKAGE))

find-package-file:
	./scripts/packages/find-package-file.sh $(FILE)

install-package:
	./scripts/packages/install-package.sh $(PACKAGE)
