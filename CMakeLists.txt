cmake_minimum_required(VERSION 3.20)

project(opentyrian C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

option(WITH_NETWORK "Build with SDL2_net networking support" OFF)

file(GLOB OPENTYRIAN_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.c")

add_executable(opentyrian ${OPENTYRIAN_SOURCES})

set_target_properties(opentyrian PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

if(MSVC)
  target_compile_options(opentyrian PRIVATE /W4)
else()
  target_compile_options(opentyrian PRIVATE
    -pedantic
    -Wall
    -Wextra
    -Wno-format-truncation
    -Wno-missing-field-initializers
  )
endif()

if(CMAKE_BUILD_TYPE MATCHES "Debug")
  target_compile_options(opentyrian PRIVATE -O0 -g3)
else()
  target_compile_definitions(opentyrian PRIVATE NDEBUG)
  target_compile_options(opentyrian PRIVATE -O2)
endif()

if(WITH_NETWORK)
  target_compile_definitions(opentyrian PRIVATE WITH_NETWORK)
endif()

if(WIN32)
  target_compile_definitions(opentyrian PRIVATE TARGET_WIN32)
else()
  target_compile_definitions(opentyrian PRIVATE TARGET_UNIX)
endif()

if(EMSCRIPTEN)
  if(WITH_NETWORK)
    message(FATAL_ERROR "WITH_NETWORK=ON is not supported for wasm.")
  endif()

  target_compile_definitions(opentyrian PRIVATE TYRIAN_DIR=\"/data\")
  set_target_properties(opentyrian PROPERTIES SUFFIX ".html")
  target_compile_options(opentyrian PRIVATE -sUSE_SDL=2)

  if(CMAKE_BUILD_TYPE MATCHES "Debug")
    target_compile_options(opentyrian PRIVATE -O0 -gsource-map)
    target_link_options(opentyrian PRIVATE -O0 -gsource-map -sASSERTIONS=2 -sASYNCIFY)
  else()
    target_compile_options(opentyrian PRIVATE -O3)
    target_link_options(opentyrian PRIVATE -O3 -sASYNCIFY)
  endif()

  target_link_options(opentyrian PRIVATE
    -sUSE_SDL=2
    -sSTACK_SIZE=8388608
    -sALLOW_MEMORY_GROWTH=1
    -sEXIT_RUNTIME=1
    -sEXPORTED_RUNTIME_METHODS=['callMain']
    --shell-file ${CMAKE_SOURCE_DIR}/wasm/shell.html
    --preload-file ${CMAKE_SOURCE_DIR}/data@/data
  )
else()
  find_package(PkgConfig REQUIRED)

  if(WITH_NETWORK)
    pkg_check_modules(SDL2 REQUIRED sdl2 SDL2_net)
  else()
    pkg_check_modules(SDL2 REQUIRED sdl2)
  endif()

  target_compile_definitions(opentyrian PRIVATE TYRIAN_DIR=\"data\")
  target_include_directories(opentyrian PRIVATE ${SDL2_INCLUDE_DIRS})
  target_link_directories(opentyrian PRIVATE ${SDL2_LIBRARY_DIRS})
  target_link_libraries(opentyrian PRIVATE ${SDL2_LIBRARIES} m)
endif()
