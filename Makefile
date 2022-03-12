PROJECT = xgrub-password

DEBNAME = xgrub-password

GIT_LAST_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null)

# ifdef GIT_LAST_TAG
# PROJECT_BASE_VERSION = $(GIT_LAST_TAG)
# else
PROJECT_BASE_VERSION = 1.0
# endif

# define system name (focal, jammy, ...)
# SYSTEM_NAME := $(shell lsb_release -c -s)

# define git branch
ifndef GIT_BRANCH
export GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
endif
ifndef GIT_BRANCH
export GIT_BRANCH := unknown
endif

# define git revision
ifndef GIT_REV
export GIT_REV := $(shell git rev-parse --verify HEAD --short 2>/dev/null)
endif
ifndef GIT_REV
export GIT_REV := unknown
endif

# define git revision count (incremental)
ifndef GIT_REV_COUNT
ifdef GIT_BRANCH
export GIT_REV_COUNT := $(shell git rev-list --count $(GIT_BRANCH) 2>/dev/null)
else
export GIT_REV_COUNT := $(shell git rev-list --count HEAD 2>/dev/null)
endif
endif
ifndef GIT_REV_COUNT
export GIT_REV_COUNT := 1
endif

#
# NOTE: get revision hash from revision count
#
# long
# git rev-list --reverse master|head -${GIT_REV_COUNT}|tail -1
# short
# git rev-list --reverse master|head -${GIT_REV_COUNT}|tail -1|cut -b 1-7
#

# see https://semver.org/
ifndef PROJECT_VERSION
# export PROJECT_VERSION ?= $(PROJECT_BASE_VERSION).$(GIT_REV_COUNT)+$(GIT_REV)+$(SYSTEM_NAME)
export PROJECT_VERSION ?= $(PROJECT_BASE_VERSION).$(GIT_REV_COUNT)+$(GIT_REV)
endif # PROJECT_VERSION


# debian package name info
# NOTE: no :=
# DEB_INFO = $(GIT_BRANCH)$(SQL_DRIVERS)-"$(SYSTEM_INFO)"_$(ARCH)

# DEB_VERSION = $(DEBNAME)_$(PROJECT_VERSION)-$(DEB_INFO).deb

ifndef DESTDIR
DESTDIR := output
endif

ifneq ($(V),0)
Q =
else
Q = @
endif

all:
	$(Q)echo "make deb | make clean"

info:
	$(Q)echo "      This makefile: $(firstword $(MAKEFILE_LIST))"
	$(Q)echo "         GIT branch: $(GIT_BRANCH)"
	$(Q)echo "       GIT revision: $(GIT_REV)"
	$(Q)echo " GIT revision count: $(GIT_REV_COUNT)"
	$(Q)echo "       GIT last tag: $(GIT_LAST_TAG)"
	$(Q)echo "            Project: $(PROJECT)"
	$(Q)echo "    Project version: $(PROJECT_VERSION)"
	${Q}echo "   DEB Package name: $(DEBNAME)_$(PROJECT_VERSION)_all.deb"

version:
	@echo "$(PROJECT_VERSION)"

clean:
	$(Q)echo clean
	$(RM) -r debian/$(DEBNAME)/
	$(RM) -r output/

install:
	$(Q)echo "install begin"
	install -m 0755 xgrub-password -D --target-directory="$(DESTDIR)/usr/bin"
	install -m 0755 xgrub-password-update -D --target-directory="$(DESTDIR)/usr/lib/$(DEBNAME)"
	install -m 0644 99xgrub-password -D --target-directory="$(DESTDIR)/etc/apt/apt.conf.d"
	$(Q)echo "install done"

#
# ---------- Git-buildpackage begin----------
#

GBP_OPTS = --git-ignore-new
# GBP_OPTS += --unsigned-source
# GBP_OPTS += --unsigned-changes
# GBP_OPTS += --unsigned-buildinfo
GBP_OPTS += --no-sign
GBP_OPTS += --post-clean
GBP_OPTS += --git-tag
GBP_OPTS += --git-retag

GBP_DCH_OPTS := --id-length=8
GBP_DCH_OPTS += --new-version=$(PROJECT_VERSION)
GBP_DCH_OPTS += --git-author
GBP_DCH_OPTS += --commit
GBP_DCH_OPTS += --release
# GBP_DCH_OPTS += -v

# source and binary packages
deb_all:
	gbp buildpackage ${GBP_OPTS} --build=source,binary

# binary package only
deb_binary:
	gbp buildpackage $(GBP_OPTS) --build=binary

deb: release deb_binary

# generate new changelog and release
gen_release:
	EMAIL=email@not-used gbp dch $(GBP_DCH_OPTS)

release: gen_release

#
# ---------- Git-buildpackage end ----------
#

