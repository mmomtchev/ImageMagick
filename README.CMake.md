# CMake Portable Build

Times change and ImageMagick has now a portable CMake build.

This build is targeted especially at portable software projects that include ImageMagick and are distributed as source.

It allows to build ImageMagick consistently on all platforms.

It is unit-tested with almost all delegates on Windows, Linux, macOS and WASM. It supports both static and shared builds - except on WASM where there are no shared libraries.

It supports using the system-provided libraries or `conan`-provided libraries. In conjunction with `conan`, the build is fully self-contained and fully reproducible on all platforms.


# Build Instructions

Unless explicitly stated, all the build instructions are valid for all three major OS. If something does not work as expected, you can always check the Github Action which has been tested to work: `.github/workflows/cmake-build.yml` or the `cmake_build.sh` shell script.

## Dependencies

The build process will automatically identify available dependencies. It will look, in this order, for:

* Manually provided `CMake` dependency with an environment variable (`<pkg>_ROOT`, refer to https://cmake.org/cmake/help/latest/command/find_package.html)
* User-provided CMake config file
  - `conan`-provided dependencies use this
* User-provided `pkg-config` dependency in `PKG_CONFIG_PATH`
* User-provided CMake find module
  - `conan`-provided dependencies that have alternatives such as `JPEG` being resolved to either `libjpeg` or `libjpeg-turbo` use this
* System-wide package-provided `CMake` support  (`<PKG>Config.cmake` usually somewhere in `/usr/lib/`)
* System-wide built-in `CMake` find module (`Find<PKG>.cmake` usually in `/usr/share/cmake`, part of the `CMake` installation)
* System-wide `pkg-config`

This is implemented in `magick_find_delegate()` in the main `CMakeLists.txt`.

## `conan`

`conan` is a source tarball repository with an unified build system fully integrated with `CMake`. Using `conan` is optional. It allows to easily retrieve specified versions of all the required dependencies and to automatically include them in the build.

* Install `conan` if you don't already have it:

      pip3 install conan
      conan profile detect

  Everything `conan` does, goes into `${HOME}/.conan2` which can grow to a very considerable size, since it will cache different builds for different compiler configurations.

* Use the provided configurable `conanfile.py` recipe to install all the dependencies (launch at the root of the project, and it will create a `build` directory):

      conan install . -of build --build=missing

* The `conan` recipe supports a `libtype` option that accepts `shared` or `static` (*default*) and a large number of options to enable/disable all of the optional delegate libraries. For example to make a shared library build, disabling font-related delegates, and with debug symbols, you can launch:

      conan install . -of build -o fonts=False -o libtype=shared --build=missing

  Check `conanfile.py` for a list of all supported options. You can customize this file.

* To enable debug symbols:

      conan install . -of build --settings=build_type=Debug --build=missing

* You can instruct `conan` to cross-compile by using a profile (`emscripten.profile` is already included):

      conan install . -of build -pr:b=default -pr:h=./emscripten.profile --build=missing

When using `conan`, all `conan` compiler options from the profile will be automatically transferred to `CMake`. This means that if use specified `emscripten` in `conan`, `CMake` will also use `emscripten`.

In order to use `emscripten` without `conan`, you will need to set up the environment variables `CC`, `CXX` and `LD`.

## `CMake`

You need to have `CMake` 3.20 or later installed.

* Unless `conan` has already created and populated a `build` directory for you, start by creating one:

    *Linux/macOS*

      mkdir -p build && cd build

    *Windows*

      if not exist build mkdir build
      cd build


* Then launch the configure step:

  *(without `conan`)*

      cmake .. -DCMAKE_BUILD_TYPE=Release

  *(with `conan`)*

      cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE="conan_toolchain.cmake"

  You must use the same type of build as `conan` - `Debug` or `Release`. On Windows, you must either be using a Visual Studio developer prompt, or if you are using `conan` you can launch `conanbuild.bat` to locate Visual Studio.


* The `CMake` build supports the usual ImageMagick build options (HDRI, quantum depth, static build...). The `CMake` static build works best with the `conan` static build:

      cmake .. -DCMAKE_BUILD_TYPE=Release                    \
              -DCMAKE_TOOLCHAIN_FILE="conan_toolchain.cmake" \
              -DBUILD_SHARED_LIBS=OFF                         \
              -DCMAKE_INSTALL_PREFIX=/opt/ImageMagick        \
              -DMAGICK_HDRI_ENABLE=ON                        \
              -DMAGICKCORE_QUANTUM_DEPTH=16

  It is also recommended to match the `static` or `shared` setting of `conan` - though not mandatory. **Please note that the default `conan` build is `static` while the default ImageMagick build is `shared`.**

* Launch the build

      cmake --build . --config Release

  As `CMake` generates platform-specific makefiles, at this point, you can also use the platform-specific make tool such as `make` or `MSBuild.exe`.

* Optionally, install the build

      cmake --install . --config Release

  If the build is installed, it will generate `pkg-config` and `Magick++-config` files with the build options - however these won't contain the `conan`-installed libraries which will have to be included separately. It will also export `CMake` config files.

Remember that when using `CMake`, on Linux and macOS `Release`/`Debug` is handled during the configure phase, while on Windows, it is handled during the build phase. UNIX makefiles contain only a single build, while Windows project files have both builds defined.

### Disabling and enabling delegates

Sometimes you need to disable including a delegate autodetected to be present on your system. Use the name of the `DELEGATE` argument to `magick_find_delegate` to explicitly disable it:

`cmake .. -DPNG_DELEGATE=OFF`

will build without `png` support.

Similarly,

`cmake .. -DHASJEMALLOC=ON`

will build with `jemalloc` support which is disabled by default.

### Produce universal binaries

A somewhat hackish option, `-DMAGICK_PREFER_STATIC_LIBS=ON`, allows to tweak the CMake `find_library()` detection mechanism in order to prefer static over shared libraries. This feature is not officially supported by CMake.

It tends to break many built-in find modules that search for the libraries in the system environment.

When used in an environment where all the delegates are provided via user-supplied CMake config files or `pkg-config` modules - such as when using `conan` - it allows to include statically the system libraries - and especially X11. It is used for the generation of the prebuilt universal binaries.

Disabling hard-coding of identified font directories can be configured with:

```
cmake .. -DCMAKE_BUILD_TYPE=Release       \
          -DMAGICK_APPLE_FONT_DIR=OFF     \
          -DMAGICK_DEJAVU_FONT_DIR=OFF    \
          -DGHOSTSCRIPT_FONT_DIR          \
          -DMAGICK_URW_FONT_DIR=OFF       \
          -DMAGICK_URW_TYPE1_FONT_DIR=OFF \
          -DMAGICK_TT_FONT_DIR=OFF
```

# Using the Library

For `CMake` projects, the build exports three targets - `ImageMagick::Magick++`, `ImageMagick::MagickCore` and `ImageMagick::MagickWand`.

If the project is installed, the best way to externally import it is by using `find_package(ImageMagick CONFIG)` - as recent versions of `CMake` include a built-in `FindImageMagick` module that must be bypassed. Point `ImageMagick_ROOT` at `${INSTALL_PREFIX}/lib/cmake`. If your project uses `conan` as well, this won't interfere with `conan`.

Example `CMake` for using the `Magick++` C++ API in Q16 HDRI configuration:

    find_package(ImageMagick CONFIG)
    target_include_directories(${PROJECT_NAME} PRIVATE ImageMagick::Magick++-7.Q16HDRI)
    target_link_libraries(${PROJECT_NAME} PRIVATE ImageMagick::Magick++-7.Q16HDRI)

Then set the environment variable `ImageMagick_ROOT` to `/opt/ImageMagick/lib/cmake` if you installed in `/opt/ImageMagick`.

If the project is included as a subproject into another larger project, the libraries can be used through the `CMake` targets directly from the build tree without installing.

`.github/workflows/cmake-build.yml` contains an example for building a `CMake` application using the library as the last step of the build process.

## Using in Embedded Environments (WASM)

Unless `-DZERO_CONFIGURATION_SUPPORT=ON` is used, the resulting library will expect to find its configuration files at the path specified by `-DCMAKE_INSTALL_PREFIX=`. In this case all of the installed files in `share`, `lib` and `etc` will have to be embedded with the library.


# Authors

The original author is [`@MarcoMartins86`](https://github.com/MarcoMartins86) who did most of the initial work.

[`@Cyriuz`](https://github.com/Cyriuz) maintained and improved it for a while.

The `conan` support, `pkg-config` support, installation targets, polishing, documenting and testing work is by [`@mmomtchev`](https://github.com/mmomtchev).

