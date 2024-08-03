#!/bin/bash

# Build and test the cmake build
#
# Before:
# rm -rf build && cd build 
#
# Usage examples:
# bash ../cmake_build.sh conan static Release
# bash ../cmake_build.sh pkg static Debug
# bash ../cmake_build.sh system shared Release
#
# Exports a CMake config file to ${HOME}/tmp/im
#
# This works on all OS but requires bash
#

CONAN=$1
STATIC=$2
RELEASE=$3

case ${STATIC} in
  static)
    CMAKE_STATIC=-DBUILD_SHARED_LIBS=OFF
    ;;
  shared)
    CMAKE_STATIC=-DBUILD_SHARED_LIBS=ON
    ;;
  *)
    echo "invalid lib type"
    exit 1
    ;;
esac

case ${RELEASE} in
  Debug | Release) ;;
  *)
    echo "invalid build type"
    exit 1
    ;;
esac

shift
shift
shift

case ${CONAN} in
  conan)
    conan install .. -of . --build=missing -o libtype=${STATIC} --settings=build_type=${RELEASE} $@
    CMAKE_CONAN=-DCMAKE_TOOLCHAIN_FILE="conan_toolchain.cmake"
    ;;
  pkg)
    CONAN_GENERATOR=PkgConfigDeps conan install .. -of . --build=missing -o libtype=${STATIC} --settings=build_type=${RELEASE} ${PROFILE}
    export PKG_CONFIG_PATH=$(pwd)
    ;;
  system)
    ;;
  *)
    echo "invalid build type"
    exit 1
    ;;
esac

# Main ImageMagick build
cmake .. -DCMAKE_BUILD_TYPE=${RELEASE} ${CMAKE_CONAN} ${CMAKE_STATIC} ${CMAKE_NOSYS} -DCMAKE_INSTALL_PREFIX=${HOME}/tmp/im/ -DZERO_CONFIGURATION_SUPPORT=ON
cmake --build . -j 4
cmake --install .

# Build a client program using the exported CMake config file
mkdir -p delegates
cd delegates
ImageMagick_ROOT=${HOME}/tmp/im/lib/cmake cmake ../../tests -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=../conan_toolchain.cmake
cmake --build .
./delegates
case `uname` in
	Darwin) otool -L delegates ;;
	Linux) ldd delegates ;;
esac
