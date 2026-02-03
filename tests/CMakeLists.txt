cmake_minimum_required(VERSION 3.30 FATAL_ERROR)
project(LibraPackageTests NONE)

# Point to real libra
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
message("CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}")
enable_testing()

# Each function test is a separate CMake project
add_subdirectory(test1_package_configure_exports)
add_subdirectory(test2_package_register_target)
add_subdirectory(test3_package_register_headers)
add_subdirectory(test4_package_register_copyright)
add_subdirectory(test5_package_register_extra_configs)
add_subdirectory(test6_package_requested_components)

# LIBRA_SAN tests
add_test(NAME LIBRA_SAN-gnu COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_SAN-utest.sh
                                    gnu)
add_test(NAME LIBRA_SAN-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_SAN-utest.sh clang)
add_test(NAME LIBRA_SAN-intel
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_SAN-utest.sh intel)

# LIBRA_PGO tests
add_test(NAME LIBRA_PGO-gnu COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_PGO-utest.sh
                                    gnu)
add_test(NAME LIBRA_PGO-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_PGO-utest.sh clang)
add_test(NAME LIBRA_PGO-intel
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_PGO-utest.sh intel)

# LIBRA_CODE_COV tests
add_test(NAME LIBRA_CODE_COV-gnu
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_CODE_COV-utest.sh gnu)
add_test(NAME LIBRA_CODE_COV-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_CODE_COV-utest.sh clang)

# LIBRA_FORTIFY tests
add_test(NAME LIBRA_FORTIFY-gnu
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_FORTIFY-utest.sh gnu)
add_test(NAME LIBRA_FORTIFY-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_FORTIFY-utest.sh clang)

# LIBRA_BUILD_PROF tests
add_test(NAME LIBRA_BUILD_PROF-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_BUILD_PROF-utest.sh clang)

# LIBRA_LTO tests
add_test(NAME LIBRA_LTO-gnu COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_LTO-utest.sh
                                    gnu)
add_test(NAME LIBRA_LTO-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_LTO-utest.sh clang)
add_test(NAME LIBRA_LTO-intel
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_LTO-utest.sh intel)

# LIBRA_STDLIB tests
add_test(NAME LIBRA_STDLIB-gnu
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_STDLIB-utest.sh gnu)
add_test(NAME LIBRA_STDLIB-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_STDLIB-utest.sh clang)
add_test(NAME LIBRA_STDLIB-intel
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_STDLIB-utest.sh intel)

# LIBRA_OPT_LEVEL tests
add_test(NAME LIBRA_OPT_LEVEL-gnu
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_OPT_LEVEL-utest.sh gnu)
add_test(NAME LIBRA_OPT_LEVEL-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_OPT_LEVEL-utest.sh clang)
add_test(NAME LIBRA_OPT_LEVEL-intel
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_OPT_LEVEL-utest.sh intel)

# LIBRA_NATIVE_OPT tests
add_test(NAME LIBRA_NATIVE_OPT-gnu
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_NATIVE_OPT-utest.sh gnu)
add_test(NAME LIBRA_NATIVE_OPT-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_NATIVE_OPT-utest.sh clang)
add_test(NAME LIBRA_NATIVE_OPT-intel
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_NATIVE_OPT-utest.sh intel)

# LIBRA_OPT_REPORT tests
add_test(NAME LIBRA_OPT_REPORT-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_OPT_REPORT-utest.sh clang)
add_test(NAME LIBRA_OPT_REPORT-intel
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_OPT_REPORT-utest.sh intel)

# LIBRA_VALGRIND_COMPAT tests
add_test(NAME LIBRA_VALGRIND_COMPAT-gnu
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_VALGRIND_COMPAT-utest.sh gnu)
add_test(NAME LIBRA_VALGRIND_COMPAT-clang
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_VALGRIND_COMPAT-utest.sh clang)

# LIBRA_DOCS tests
add_test(NAME LIBRA_DOCS COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_DOCS-utest.sh)

# LIBRA_ERL tests
add_test(NAME LIBRA_ERL COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_ERL-utest.sh)

# LIBRA_FPC tests
add_test(NAME LIBRA_FPC COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_FPC-utest.sh)

# LIBRA_ERL_EXPORT tests
add_test(NAME LIBRA_ERL_EXPORT
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_ERL_EXPORT-utest.sh)

# LIBRA_FPC_EXPORT tests
add_test(NAME LIBRA_FPC_EXPORT
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_FPC_EXPORT-utest.sh)

# LIBRA_ANALYSIS tests
add_test(NAME LIBRA_ANALYSIS
         COMMAND ${CMAKE_CURRENT_LIST_DIR}/LIBRA_ANALYSIS-utest.sh)
