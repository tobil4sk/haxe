cmake_minimum_required(VERSION 2.8.12)

include(GNUInstallDirs)
project(Haxe C)

# put output in ${CMAKE_BINARY_DIR}

set(OUTPUT_DIR ${CMAKE_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_DIR})

# avoid the extra "Debug", "Release" directories
# http://stackoverflow.com/questions/7747857/in-cmake-how-do-i-work-around-the-debug-and-release-directories-visual-studio-2
foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
	string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
	set( CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${OUTPUT_DIR} )
	set( CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${OUTPUT_DIR} )
	set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${OUTPUT_DIR} )
endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )

# find Haxe and Hashlink directories

find_program(HAXE_COMPILER haxe)

find_path(HASHLINK_INCLUDE_DIR
	hlc.h
	HINTS $ENV{HASHLINK}/src
)
find_path(HASHLINK_LIBRARY_DIR
	NAMES hl.lib libhl.so
	HINTS $ENV{HASHLINK}
)
# find_library(HASHLINK_LIBRARIES hl)
set(HASHLINK_LIBRARIES hl libhl ssl fmt CACHE STRING "Libraries to include in compilation")

message(STATUS "HAXE_COMPILER: ${HAXE_COMPILER}")
message(STATUS "HASHLINK_INCLUDE_DIR: ${HASHLINK_INCLUDE_DIR}")
message(STATUS "HASHLINK_LIBRARY_DIR: ${HASHLINK_LIBRARY_DIR}")
message(STATUS "HASHLINK_LIBRARIES: ${HASHLINK_LIBRARIES}")

include_directories(${HASHLINK_INCLUDE_DIR} ${CMAKE_SOURCE_DIR}/bin/hlc/)
link_directories(${HASHLINK_LIBRARY_DIR})

add_custom_command(
	OUTPUT ${CMAKE_SOURCE_DIR}/bin/hlc/main.c
	DEPENDS build_source
)

add_custom_target(build_source
    COMMAND ${HAXE_COMPILER} build.hxml
    VERBATIM
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

add_executable(haxe
    ${CMAKE_SOURCE_DIR}/bin/hlc/main.c
)

target_link_libraries(haxe ${HASHLINK_LIBRARIES})
