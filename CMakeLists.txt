cmake_minimum_required(VERSION 3.16.3)

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

find_path(HL_INCLUDE_DIR
	hlc.h
	HINTS $ENV{HASHLINK}/src
)
find_path(HL_LIBRARY_DIR
    NAMES libhl.lib libhl.so
    HINTS $ENV{HASHLINK} /usr/local/lib
)

# locate hashlink libraries

if(WIN32)
	find_library(HL_LIBRARY libhl)
	set(LIB_EXT lib)
else()
	find_library(HL_LIBRARY hl)
	set(LIB_EXT hdll)
endif()

foreach(LIB ssl fmt)
    list(APPEND HL_EXTRA_LIBRARIES ${HL_LIBRARY_DIR}/${LIB}.${LIB_EXT})
endforeach()

set(HL_EXTRA_LIBRARIES ${HL_EXTRA_LIBRARIES} CACHE STRING "Libraries to include in compilation")

# show variable values

message(STATUS "HAXE_COMPILER: ${HAXE_COMPILER}")
message(STATUS "HL_INCLUDE_DIR: ${HL_INCLUDE_DIR}")
message(STATUS "HL_LIBRARY_DIR: ${HL_LIBRARY_DIR}")
message(STATUS "HL_LIBRARY: ${HL_LIBRARY}")
message(STATUS "HL_EXTRA_LIBRARIES: ${HL_EXTRA_LIBRARIES}")

# building commands

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

target_include_directories(haxe PRIVATE ${HL_INCLUDE_DIR} ${CMAKE_SOURCE_DIR}/bin/hlc/)
target_link_libraries(haxe ${HL_LIBRARY} ${HL_EXTRA_LIBRARIES})
