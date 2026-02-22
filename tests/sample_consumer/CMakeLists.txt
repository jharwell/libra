cmake_minimum_required(VERSION 3.16)
project(sample_consumer LANGUAGES CXX)

project(
  sample_keywords
  LANGUAGES CXX
  VERSION 1.0.0)

# Wire up LIBRA according to the consumption mode selected by the test harness.
# LIBRA_CONSUME_MODE and companion variables are injected as -D arguments by
# run_libra_cmake_test() in test_helpers.bash.  When not set the module falls
# back to the in_situ relative path so samples still work when invoked directly.
include(${CMAKE_CURRENT_SOURCE_DIR}/../consume/libra_consume.cmake)
include(${CMAKE_SOURCE_DIR}/../common.cmake)
include(libra/project)
