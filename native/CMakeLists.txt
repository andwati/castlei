cmake_minimum_required(VERSION 3.22)
project(castlei_engine LANGUAGES CXX)
file(GLOB ENGINE_SOURCES CONFIGURE_DEPENDS stockfish/src/*.cpp stockfish/src/nnue/*.cpp stockfish/src/nnue/features/*.cpp stockfish/src/syzygy/*.cpp)
list(FILTER ENGINE_SOURCES EXCLUDE REGEX "/main.cpp$")
add_library(castlei_engine SHARED adapter.cpp ${ENGINE_SOURCES})
target_compile_features(castlei_engine PRIVATE cxx_std_17)
target_compile_options(castlei_engine PRIVATE -O3 -fexceptions -frtti)
target_compile_definitions(castlei_engine PRIVATE NDEBUG)
# What Stockfish's own Makefile sets for the 64-bit targets the app ships
# (arm64, x86-64): 128-bit hash indexing and the native bit count. Debug builds
# also compile a 32-bit ARM library, which has neither.
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  target_compile_definitions(castlei_engine PRIVATE IS_64BIT USE_POPCNT)
endif()
# NEON is part of the AArch64 baseline: always safe on 64-bit ARM phones.
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64" OR ANDROID_ABI STREQUAL "arm64-v8a")
  target_compile_definitions(castlei_engine PRIVATE USE_NEON=8)
endif()
target_include_directories(castlei_engine PRIVATE stockfish/src)
find_package(Threads REQUIRED)
target_link_libraries(castlei_engine PRIVATE Threads::Threads)
target_link_options(castlei_engine PRIVATE -Wl,-z,max-page-size=16384)
