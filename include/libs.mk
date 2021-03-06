include include/compiler.mk

LIBRMN_VERSION = 19.7.0
VGRID_VERSION = 6.4.2
LIBBURPC_VERSION = 1.9

# Set default shared library extension.
SHAREDLIB_SUFFIX ?= so

# Locations to build static / shared libraries.
LIBRMN_BUILDDIR = $(BUILDDIR)/librmn
LIBRMN_STATIC = $(LIBRMN_BUILDDIR)/librmn_$(LIBRMN_VERSION).a
LIBRMN_SHARED_NAME = rmnshared_$(LIBRMN_VERSION)-rpnpy
LIBRMN_SHARED = $(SHAREDLIB_DIR)/lib$(LIBRMN_SHARED_NAME).$(SHAREDLIB_SUFFIX)
LIBVGRID_BUILDDIR = $(BUILDDIR)/vgrid
LIBVGRID_STATIC = $(LIBVGRID_BUILDDIR)/src/libvgrid.a
LIBVGRID_SHARED = $(SHAREDLIB_DIR)/libvgridshared_$(VGRID_VERSION).$(SHAREDLIB_SUFFIX)
LIBBURPC_BUILDDIR = $(BUILDDIR)/libburp
LIBBURPC_STATIC = $(LIBBURPC_BUILDDIR)/src/burp_api.a
LIBBURPC_SHARED = $(SHAREDLIB_DIR)/libburp_c_shared_$(LIBBURPC_VERSION).$(SHAREDLIB_SUFFIX)

.PRECIOUS: $(SHAREDLIB_DIR) $(LIBRMN_BUILDDIR) $(LIBRMN_STATIC) $(LIBVGRID_BUILDDIR) $(LIBVGRID_STATIC) $(LIBBURPC_BUILDDIR) $(LIBBURPC_STATIC)

.SUFFIXES:

######################################################################
# Rules for building the required shared libraries.

# Linux shared libraries need to be explicitly told to look in their current path for dependencies.
%.so: FFLAGS := $(FFLAGS) -Wl,-rpath,'$$ORIGIN' -Wl,-z,origin

# Mac shared ("dynamic") libraries need a similar thing, plus additional
# modifications to install_names and load paths.  This will be done after
# compilation (see __init__.py).
%.dylib: FFLAGS := $(FFLAGS) -dynamiclib

$(LIBRMN_SHARED): $(LIBRMN_STATIC)
	rm -f *.o
	ar -x $<
	$(FC) -shared -o $@ *.o $(FFLAGS)
	rm -f *.o

$(LIBVGRID_SHARED): $(LIBVGRID_STATIC) $(LIBRMN_SHARED)
	rm -f *.o
	ar -x $<
	$(FC) -shared -o $@ *.o $(FFLAGS) -l$(LIBRMN_SHARED_NAME) -L$(dir $@)
	rm -f *.o

$(LIBBURPC_SHARED): $(LIBBURPC_STATIC) $(LIBRMN_SHARED)
	rm -f *.o
	ar -x $<
	$(FC) -shared -o $@ *.o $(FFLAGS) -l$(LIBRMN_SHARED_NAME) -L$(dir $@)
	rm -f *.o

######################################################################
# Rules for building the static libraries from source.

$(LIBRMN_STATIC): $(LIBRMN_BUILDDIR)
	cd $< && \
	env PROJECT_ROOT=$(BUILDDIR) $(MAKE)
	touch $@

$(LIBVGRID_STATIC): $(LIBVGRID_BUILDDIR)
	cd $</src && \
	env PROJECT_ROOT=$(BUILDDIR) $(MAKE) genlib
	touch $@

$(LIBBURPC_STATIC): $(LIBBURPC_BUILDDIR)
	cd $</src && \
	env PROJECT_ROOT=$(BUILDDIR) $(MAKE)
	touch $@

