#
# Common Makefile for building RPMs
#

NAME := xen
SPECFILE := xen.spec

WORKDIR := $(shell pwd)
SPECDIR ?= $(WORKDIR)
SRCRPMDIR ?= $(WORKDIR)/srpm
BUILDDIR ?= $(WORKDIR)
RPMDIR ?= $(WORKDIR)/rpm
SOURCEDIR := $(WORKDIR)
VERSION := $(shell cat version)

NO_OF_CPUS := $(shell grep -c ^processor /proc/cpuinfo)

RPM_DEFINES := --define "_sourcedir $(SOURCEDIR)" \
		--define "_specdir $(SPECDIR)" \
		--define "_builddir $(BUILDDIR)" \
		--define "_srcrpmdir $(SRCRPMDIR)" \
		--define "_rpmdir $(RPMDIR)" \
		--define "version $(VERSION)" \
		--define "jobs $(NO_OF_CPUS)"

VER_REL := $(shell rpm $(RPM_DEFINES) -q --qf "%{VERSION} %{RELEASE}\n" --specfile $(SPECFILE)| head -1)

ifndef NAME
$(error "You can not run this Makefile without having NAME defined")
endif
ifndef VERSION
$(error "You can not run this Makefile without having VERSION defined")
endif
ifndef RELEASE
RELEASE := $(word 2, $(VER_REL))
endif

all: help

SRC_BASEURL := http://bits.xensource.com/oss-xen/release/${VERSION}/
SRC_FILE := xen-${VERSION}.tar.gz
SIGN_FILE := xen-${VERSION}.tar.gz.sig

GRUB_FILE := grub-0.97.tar.gz
GRUB_URL := ftp://alpha.gnu.org/gnu/grub/$(GRUB_FILE)
GRUB_SIGN_SUFF := .sig

LWIP_FILE := lwip-1.3.0.tar.gz
LWIP_URL := http://download.savannah.gnu.org/releases/lwip/$(LWIP_FILE)
LWIP_SIGN_SUFF := .sig

NEWLIB_FILE := newlib-1.16.0.tar.gz
NEWLIB_URL := ftp://sources.redhat.com/pub/newlib/$(NEWLIB_FILE)

PCIUTILS_FILE := pciutils-2.2.9.tar.bz2
PCIUTILS_URL := http://www.kernel.org/pub/software/utils/pciutils/$(PCIUTILS_FILE)
PCIUTILS_SIGN_SUFF := .sign

ZLIB_FILE := zlib-1.2.3.tar.gz
ZLIB_URL := http://downloads.sourceforge.net/project/libpng/zlib/1.2.3/$(ZLIB_FILE)

URL := $(SRC_BASEURL)/$(SRC_FILE)
URL_SIGN := $(SRC_BASEURL)/$(SIGN_FILE)

get-sources: $(SRC_FILE) $(SIGN_FILE) $(GRUB_FILE) $(GRUB_FILE)$(GRUB_SIGN_SUFF) $(LWIP_FILE) $(LWIP_FILE)$(LWIP_SIGN_SUFF) $(NEWLIB_FILE) $(PCIUTILS_FILE) $(PCIUTILS_FILE)$(PCIUTILS_SIGN_SUFF) $(ZLIB_FILE)

$(SRC_FILE) $(SIGN_FILE) $(GRUB_FILE) $(GRUB_FILE)$(GRUB_SIGN_SUFF) $(LWIP_FILE) $(LWIP_FILE)$(LWIP_SIGN_SUFF) $(NEWLIB_FILE) $(PCIUTILS_FILE) $(PCIUTILS_FILE)$(PCIUTILS_SIGN_SUFF) $(ZLIB_FILE):
	@echo -n "Downloading sources... "
	@wget -c $(URL) $(URL_SIGN) $(GRUB_URL) $(GRUB_URL)$(GRUB_SIGN_SUFF) $(LWIP_URL) $(LWIP_URL)$(LWIP_SIGN_SUFF) $(NEWLIB_URL) $(PCIUTILS_URL) $(PCIUTILS_URL)$(PCIUTILS_SIGN_SUFF) $(ZLIB_URL)
	@echo "OK."

verify-sources: verify-sources-sig verify-sources-sign verify-sources-sum

verify-sources-sig: $(SRC_FILE) $(GRUB_FILE) $(LWIP_FILE)
	@for f in $^; do gpg --verify $$f.sig $$f; done

verify-sources-sign: $(PCIUTILS_FILE)
	@for f in $^; do gpg --verify $$f.sign $$f; done

verify-sources-sum: $(NEWLIB_FILE) $(ZLIB_FILE)
	@for f in $^; do md5sum -c $$f.md5sum; done
	@for f in $^; do sha1sum -c $$f.sha1sum; done


.PHONY: clean-sources
clean-sources:
ifneq ($(SRC_FILE), None)
	-rm $(SRC_FILE)
endif


#RPM := rpmbuild --buildroot=/dev/shm/buildroot/
RPM := rpmbuild 

RPM_WITH_DIRS = $(RPM) $(RPM_DEFINES)

rpms: get-sources $(SPECFILE)
	$(RPM_WITH_DIRS) -bb $(SPECFILE)
	rpm --addsign $(RPMDIR)/x86_64/*.rpm

rpms-nobuild:
	$(RPM_WITH_DIRS) --nobuild -bb $(SPECFILE)

rpms-just-build: 
	$(RPM_WITH_DIRS) --short-circuit -bc $(SPECFILE)

rpms-install: 
	$(RPM_WITH_DIRS) -bi $(SPECFILE)

prep: get-sources $(SPECFILE)
	$(RPM_WITH_DIRS) -bp $(SPECFILE)

srpm: get-sources $(SPECFILE)
	$(RPM_WITH_DIRS) -bs $(SPECFILE)

verrel:
	@echo $(NAME)-$(VERSION)-$(RELEASE)

# mop up, printing out exactly what was mopped.

.PHONY : clean
clean ::
	@echo "Running the %clean script of the rpmbuild..."
	$(RPM_WITH_DIRS) --clean --nodeps $(SPECFILE)

help:
	@echo "Usage: make <target>"
	@echo
	@echo "get-sources      Download kernel sources from kernel.org"
	@echo "verify-sources"
	@echo
	@echo "prep             Just do the prep"	
	@echo "rpms             Build rpms"
	@echo "rpms-nobuild     Skip the build stage (for testing)"
	@echo "rpms-just-build  Skip packaging (just test compilation)"
	@echo "srpm             Create an srpm"
	@echo
