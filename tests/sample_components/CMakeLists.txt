cmake_minimum_required(VERSION 3.31)
project(
  sample_components
  LANGUAGES CXX
  VERSION 1.0.0)

include(${CMAKE_CURRENT_SOURCE_DIR}/../consume/libra_consume.cmake)
include(${CMAKE_SOURCE_DIR}/../common.cmake)
include(libra/project)
