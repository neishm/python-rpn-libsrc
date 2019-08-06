# Top-level makefile for building the shared library dependencies.

BUILDDIR ?= $(PWD)
SHAREDLIB_DIR ?= $(PWD)

.PHONY: all sharedlibs clean

all: .patched sharedlibs

include include/libs.mk

sharedlibs: $(LIBRMN_SHARED) $(LIBDESCRIP_SHARED) $(LIBBURPC_SHARED)
	# Copy extra libraries needed for runtime
	[ -z "$(EXTRA_LIBS)" ] || cp -L $(EXTRA_LIBS) $(SHAREDLIB_DIR)

.patched:
	git submodule update --init
	cd librmn  && patch -p1 < $(PWD)/patches/librmn.patch
	cd vgrid   && patch -p1 < $(PWD)/patches/vgrid.patch
	cd libburp && patch -p1 < $(PWD)/patches/libburp.patch
	touch $@

clean:
	git submodule foreach git clean -xdf .
	git submodule foreach git reset --hard HEAD
	rm *.so .patched
