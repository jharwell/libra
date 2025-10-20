#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
add_executable(${PROJECT_NAME} ${${PROJECT_NAME}_CXX_SRC})

add_executable(${PROJECT_NAME}-other-++ ${${PROJECT_NAME}_CXX_SRC})

add_executable(${PROJECT_NAME}-other-c ${${PROJECT_NAME}_C_SRC})

# If CXX_STANDARD is not set, ti returns -NOTFOUND
if(${LIBRA_GLOBAL_CXX_STANDARD})
  get_target_property(TARGET_CXX_STANDARD ${PROJECT_NAME}-other-c++
                      CXX_STANDARD)
  if(NOT TARGET_CXX_STANDARD OR TARGET_CXX_STANDARD LESS 14)
    message(
      FATAL_ERROR
        "Target ${PROJECT_NAME}-other-c++ requires C++14 or higher, but is configured with C++${TARGET_CXX_STANDARD}"
    )
  endif()
endif()

if(${LIBRA_GLOBAL_C_STANDARD})
  get_target_property(TARGET_C_STANDARD ${PROJECT_NAME}-other-c C_STANDARD)
  if(NOT TARGET_C_STANDARD OR TARGET_C_STANDARD LESS 11)
    message(
      FATAL_ERROR
        "Target ${PROJECT_NAME}-other-c requires C11 or higher, but is configured with C${TARGET_C_STANDARD}"
    )
  endif()
endif()
