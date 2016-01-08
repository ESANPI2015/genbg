cmake_minimum_required(VERSION 2.8)

project(genBG)

include_directories(src)
include_directories(include)

# they are rebuilt completely from scratch inside our build-tree
# each subdir is a "project", so some standard variables are defined therein (like protocol_SOURCE_DIR for example)
# but we ourself may be add_subdirectory'ed, with some of the targets already present. so check this!

# This is not possible without mars cmake file :/ So we have to compile this on our own
if(NOT TARGET c_bagel)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../ext/c_bagel c_bagel)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../ext/c_bagel/src)
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

set(SOURCES
    src/bg_generate_c.c
    src/template_engine.c
    src/bg_generate_vhdl.c
    src/float_to_std.c
    )
set(HEADERS
    include/bg_generate_vhdl.h
    include/bg_generate_c.h
    include/template_engine.h
    include/float_to_std.h
    )

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules/")
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_library(genBG STATIC ${SOURCES})
target_link_libraries(genBG
    ${genBG_PKGCONFIG_LIBRARIES}
    )

# pkg-config, to be installed:
configure_file(${PROJECT_NAME}.pc.in ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc DESTINATION lib/pkgconfig)
# pkg-config for use inside our buildtree
configure_file(${PROJECT_NAME}-uninstalled.pc.in ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-uninstalled.pc @ONLY)
