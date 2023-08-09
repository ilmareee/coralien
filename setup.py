from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext
from Cython.Build import cythonize
from Cython.Compiler import Options
import os
import numpy

Options.language_level = 3
copt: dict[str, list[str]] = {# 'unix': ['-std=c2x', '-g', '-Og', '-pthread', '-ffast-math','-fopenmp'],
                              'unix': ['-std=c2x','-O3','-pthread','-ffast-math','-fopenmp']  ,
                              'mingw32': ['-std=c2x', '-O3', '-pthread', '-ffast-math','-fopenmp'],
                              'mingw64': ['-std=c2x', '-O3', '-pthread', '-ffast-math','-fopenmp'],
                              'msvc': ['/std:c20', '/cgthreads8', '/O2', '/GL','/openmp'],
                              # 'cygiwin' : []
                              }
sourcesfiles: list[str] = []
for folder, folders, files in os.walk("lib"):
    for file in files:
        if file.split(".")[-1] in ("pyx", "c"):  # ,"pxd"
            if file not in ("cy_sim.c"):
                sourcesfiles.append(folder + "/" + file)

cppgravilib: list[Extension] = [Extension("Coralien.cy_sim", sources=sourcesfiles, include_dirs=[
                                          './lib/',numpy.get_include()],define_macros=[("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")],
                                          language="C++")]


class build_ext_subclass(build_ext):
    def build_extensions(self) -> None:
        compiler = self.compiler.compiler_type
        print("using compiler:", compiler,end="")
        if compiler in copt.keys():
            print("which is a known compiler, applying extra args:\n",
                  copt[compiler])
            for e in self.extensions:
                e.extra_compile_args = copt[compiler]
                e.extra_link_args = copt[compiler]
            build_ext.build_extensions(self)
        else:
            print("ERROR:", compiler, "is NOT a known compiler, you should add relevant compiler specific args to copt and/or report to devs")
            exit(1)


setup(
    ext_modules=cythonize(cppgravilib),
    cmdclass={'build_ext': build_ext_subclass}
)
