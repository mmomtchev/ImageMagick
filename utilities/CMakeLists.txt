#   Licensed under the ImageMagick License (the "License"); you may not use
#   this file except in compliance with the License.  You may obtain a copy
#   of the License at
#
#     https://imagemagick.org/script/license.php
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
#   License for the specific language governing permissions and limitations
#   under the License.
#
#   CMake script file to build ImageMagick
#

project(Magick C)

set(MAGICK_SRC
  magick.c
)

add_executable(${MAGICK_BINARY_NAME} ${MAGICK_SRC} ${MAGICK_RESOURCE_FILE_PATH})

target_include_directories(${MAGICK_BINARY_NAME} PRIVATE ${IMAGEMAGICK_BASE_PATH})
target_compile_definitions(${MAGICK_BINARY_NAME} PRIVATE ${MAGICK_BUILD_DEFINES})
target_link_libraries(${MAGICK_BINARY_NAME} PRIVATE ${MAGICKWAND_BINARY_NAME})

# After installation utilities go to bin, while libs go to bin/../lib/
if(APPLE)
  set_target_properties(${MAGICK_BINARY_NAME} PROPERTIES INSTALL_RPATH "@loader_path/../lib/")
else()
  set_target_properties(${MAGICK_BINARY_NAME} PROPERTIES INSTALL_RPATH "$ORIGIN/../lib/")
endif()

if(MINGW)
  # Magick uses the new unicode wmain entrypoint and URLDownloadToFile
  # (MSVC gets them from pragmas inside the code)
  target_link_options(${MAGICK_BINARY_NAME} PRIVATE -lurlmon -municode)
endif()

install(TARGETS ${MAGICK_BINARY_NAME}
  RUNTIME DESTINATION bin
  BUNDLE DESTINATION bin
)
