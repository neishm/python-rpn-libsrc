# Helper functions for interfacing these shared libraries with a Python
# package.

# Determine the shared library suffix for this platform.
import os
import platform
if 'SHAREDLIB_SUFFIX' in os.environ:
  sharedlib_suffix = os.environ['SHAREDLIB_SUFFIX']
else:
  sharedlib_suffix = {
  'Linux': 'so',
  'Windows': 'dll',
  'Darwin': 'dylib',
}[platform.system()]


# Define extra arguments to pass to setuptools in order to use these
# shared libraries in a Python package.
def get_extra_setup_args (*path):
  from setuptools import setup, Distribution, find_packages
  from distutils.command.build import build
  import sys
  from glob import glob
  import os

  cmdclass = {}

  # Need to force Python to treat this as a binary distribution.
  # We don't have any binary extension modules, but we do have shared
  # libraries that are architecture-specific.
  # http://stackoverflow.com/questions/24071491/how-can-i-make-a-python-wheel-from-an-existing-native-library
  class BinaryDistribution(Distribution):
    def has_ext_modules(self):
      return True
    def is_pure(self):
      return False

  # Need to invoke the Makefile from the src/ directory to build the shared
  # libraries.
  class BuildSharedLibs(build):
    def run(self):
      import os
      from subprocess import check_call

      build.run(self)
      builddir = os.path.abspath(self.build_temp)
      srcdir = os.path.dirname(os.path.abspath(__file__))
      libdir = os.path.join(*path)
      libdir = os.path.join(self.build_lib, libdir)
      libdir = os.path.abspath(libdir)
      self.copy_tree(srcdir,builddir,preserve_symlinks=1)

      check_call(['make', 'PWD='+builddir, 'BUILDDIR='+builddir, 'SHAREDLIB_DIR='+libdir, 'SHAREDLIB_SUFFIX='+sharedlib_suffix], cwd=builddir)
  cmdclass['build'] = BuildSharedLibs

  # Force the impl and abi tags.
  # We have no extension modules, so can support any Python ABI.
  try:
    from wheel.bdist_wheel import bdist_wheel
    class ForcedTag(bdist_wheel):
      def get_tag(self):
        plat_name = self.plat_name
        return ('py2.py3','none',plat_name)
    cmdclass['bdist_wheel'] = ForcedTag
  # If wheel functionality is not available, then no need to augment the
  # bdist_wheel behaviour.
  except ImportError:
    pass

  return dict(
    package_data = {
      '.'.join(path): ['*.'+sharedlib_suffix, '*.'+sharedlib_suffix+'.*'],
    },
    distclass = BinaryDistribution,
    cmdclass = cmdclass,
  )
