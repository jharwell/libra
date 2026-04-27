#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include)
file(WRITE ${CMAKE_BINARY_DIR}/include/a.hpp "int a(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/include/b.hpp "int b(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/a.cpp "int f(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/b.cpp "int g(){return 0;} int main(){return 0;}")

file(WRITE ${CMAKE_BINARY_DIR}/include/test.h "#pragma once")

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/cmake)
file(WRITE ${CMAKE_BINARY_DIR}/cmake/foo.cmake "set(X 1)")

libra_add_library(NAME mylib ${CMAKE_BINARY_DIR}/a.cpp)
libra_add_executable(NAME myexe ${CMAKE_BINARY_DIR}/b.cpp)

libra_configure_exports(mylib)
libra_install_headers(${CMAKE_BINARY_DIR}/include)
libra_install_target(mylib)
libra_install_cmake_modules(TARGET mylib FILES_OR_DIRS
                            ${CMAKE_BINARY_DIR}/cmake/foo.cmake)

libra_configure_cpack(
  "DEB;RPM;TGZ"
  "Short summary"
  "Long description"
  "A sample vendor"
  "https://sample.com"
  "sample@sample.com")

assert_target_exists(mylib)
assert_target_exists(myexe)

libra_target_count(COUNT)
assert_equal(${COUNT} 2)
