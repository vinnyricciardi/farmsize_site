
from distutils.core import setup
from Cython.Build import cythonize

setup(
     ext_modules = cythonize("feed_food_other.pyx")
)
