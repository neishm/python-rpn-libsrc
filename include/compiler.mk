
# Set default fortran compiler to gfortran.
ifeq ($(origin FC),default)
FC = gfortran
endif

# Extra flags required for gfortran.
ifneq (,$(findstring gfortran,$(FC)))
FFLAGS := $(FFLAGS) -fcray-pointer -ffree-line-length-none
GCC10CHECK=$(shell gcc -dumpversion | cut -c2)
ifneq (,$(GCC10CHECK))
FFLAGS := $(FFLAGS) -fallow-argument-mismatch -fallow-invalid-boz
CFLAGS := $(CFLAGS) -fcommon
endif
endif

