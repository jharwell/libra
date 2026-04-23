#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
file(WRITE ${CMAKE_BINARY_DIR}/a.cpp "int f(){return 0;}")
file(WRITE ${CMAKE_BINARY_DIR}/b.cpp "int g(){return 0;}")

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include)
file(WRITE ${CMAKE_BINARY_DIR}/include/test.h "#pragma once")

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/cmake)
file(WRITE ${CMAKE_BINARY_DIR}/cmake/foo.cmake "set(X 1)")

libra_add_library(NAME mylib ${CMAKE_BINARY_DIR}/a.cpp)
libra_add_executable(NAME myexe ${CMAKE_BINARY_DIR}/b.cpp)

libra_configure_exports(mylib)
libra_register_headers_for_install(${CMAKE_BINARY_DIR}/include)
libra_register_target_for_install(mylib)
libra_register_extra_configs_for_install(TARGET mylib FILES_OR_DIRS
                                         ${CMAKE_BINARY_DIR}/cmake/foo.cmake)
if(LIBRA_TEST_CPACK_LICENSE_TYPE)
  set(CPACK_RPM_PACKAGE_LICENSE ${LIBRA_TEST_CPACK_LICENSE_TYPE})
endif()

if(LIBRA_TEST_CPACK_GENERATORS)
  libra_configure_cpack(
    ${LIBRA_TEST_CPACK_GENERATORS}
    "Short summary"
    "Long description"
    "A sample vendor"
    "https://sample.com"
    "sample@sample.com")
else()
  libra_configure_cpack(
    "TGZ;DEB;RPM"
    "Short summary"
    "Long description"
    "A sample vendor"
    "https://sample.com"
    "sample@sample.com")

endif()

assert_target_exists(mylib)
assert_target_exists(myexe)

libra_target_count(COUNT)
assert_equal(${COUNT} 2)
