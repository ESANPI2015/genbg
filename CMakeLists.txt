cmake_minimum_required(VERSION 2.8)

project(genBG)

include_directories(src)
include_directories(include)

# they are rebuilt completely from scratch inside our build-tree
# each subdir is a "project", so some standard variables are defined therein (like protocol_SOURCE_DIR for example)
# but we ourself may be add_subdirectory'ed, with some of the targets already present. so check this!

# This is not possible without mars cmake file :/ So we have to compile this on our own
if(NOT TARGET c_bagel)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../ext/bagle/learning/bagel/c_bagel c_bagel)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../ext/bagle/learning/bagel/c_bagel/src)
endif(NOT TARGET c_bagel)

SET(ENV{PKG_CONFIG_PATH}
    ${CMAKE_BINARY_DIR}:$ENV{PKG_CONFIG_PATH}
    )

find_package(PkgConfig)
pkg_check_modules(genBG_PKGCONFIG REQUIRED
    c_bagel
    )

include_directories(${genBG_PKGCONFIG_INCLUDE_DIRS})
message(${genBG_PKGCONFIG_INCLUDE_DIRS})
link_directories(${genBG_PKGCONFIG_LIBRARY_DIRS})
add_definitions(${genBG_PKGCONFIG_CFLAGS_OTHER} -ggdb)

set(SOURCES_C
    src/bg_generate_c.c
    src/template_engine.c
    )
set(SOURCES_VHDL
    src/bg_generate_vhdl.c
    src/template_engine.c
    src/float_to_std.c
    )
set(HEADERS
    include/bg_generate_vhdl.h
    include/bg_generate_c.h
    include/template_engine.h
    include/float_to_std.h
    include/bg_transformation.h
    )

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules/")
include_directories(${CMAKE_CURRENT_BINARY_DIR})

# at first we have a minimal cmdline app, which exports simply everything into plaintext files
add_executable(bg2dict_c ${SOURCES_C}
    src/generateBG.c
    )
add_executable(bg2dict_vhdl ${SOURCES_VHDL}
    src/generateBG_vhdl.c
    )
target_link_libraries(bg2dict_c
    ${genBG_PKGCONFIG_STATIC_LIBRARIES}
    )
target_link_libraries(bg2dict_vhdl
    ${genBG_PKGCONFIG_STATIC_LIBRARIES}
    )
add_dependencies(bg2dict_c
    c_bagel
    )
add_dependencies(bg2dict_vhdl
    c_bagel
    )
add_executable(dict2src
    src/template_engine.c
    src/generateFromTemplate.c
    )
add_executable(clusterbg
    src/bg_transformation.c
    src/clusterBG.c
    )
target_link_libraries(clusterbg
    ${genBG_PKGCONFIG_STATIC_LIBRARIES}
    )

# creating a convenience target, so a user can easily execute ileggui, without cd'ing into the builddir
add_custom_target(clusterbg-lazy-symlink ALL
    ln --force -s ${CMAKE_CURRENT_BINARY_DIR}/clusterbg ${CMAKE_SOURCE_DIR}/clusterbg
    DEPENDS clusterbg)
add_custom_target(bg2dict_c-lazy-symlink ALL
    ln --force -s ${CMAKE_CURRENT_BINARY_DIR}/bg2dict_c ${CMAKE_SOURCE_DIR}/bg2dict_c
    DEPENDS bg2dict_c)
add_custom_target(bg2dict_vhdl-lazy-symlink ALL
    ln --force -s ${CMAKE_CURRENT_BINARY_DIR}/bg2dict_vhdl ${CMAKE_SOURCE_DIR}/bg2dict_vhdl
    DEPENDS bg2dict_vhdl)
add_custom_target(dict2src-lazy-symlink ALL
    ln --force -s ${CMAKE_CURRENT_BINARY_DIR}/dict2src ${CMAKE_SOURCE_DIR}/dict2src
    DEPENDS dict2src)
# and clean this up if someone asks us to do so
set_directory_properties(PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES "${CMAKE_SOURCE_DIR}/clusterbg")
set_directory_properties(PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES "${CMAKE_SOURCE_DIR}/bg2dict_c")
set_directory_properties(PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES "${CMAKE_SOURCE_DIR}/bg2dict_vhdl")
set_directory_properties(PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES "${CMAKE_SOURCE_DIR}/dict2src")
