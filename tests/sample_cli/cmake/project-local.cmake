#
# Copyright 2026 John Harwell, All rights reserved.
#
# SPDX-License-Identifier: MIT
#

libra_add_executable(sample_cli ${${PROJECT_NAME}_C_SRC})
libra_register_target_for_install(sample_cli)
