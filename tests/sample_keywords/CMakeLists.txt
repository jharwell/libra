cmake_minimum_required(VERSION 3.16)
project(
  sample_keywords
  LANGUAGES CXX
  VERSION 1.0.0)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)
include(${CMAKE_SOURCE_DIR}/../common.cmake)
include(libra/project)
