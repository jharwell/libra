cmake_minimum_required(VERSION 3.23)
project(sample_cli C CXX)

# Wire up LIBRA according to the consumption mode selected by the test harness.
# LIBRA_CONSUME_MODE and companion variables are injected as -D arguments by
# run_libra_cmake_test() in test_helpers.bash.  When not set the module falls
# back to the in_situ relative path so samples still work when invoked directly.
include(${LIBRA_TESTS_DIR}/consume/libra_consume.cmake)
include(libra/project)
