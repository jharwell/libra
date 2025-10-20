#
# Copyright 2025 John Harwell, All rights reserved.
#
# SPDX-License Identifier: MIT
#
cmake_policy(SET CMP0028 NEW) # ENABLE CMP0028: Double colon in target name
# means ALIAS or IMPORTED target.
cmake_policy(SET CMP0054 NEW) # ENABLE CMP0054: Only interpret if() arguments as
# variables or keywords when unquoted.
cmake_policy(SET CMP0063 NEW) # ENABLE CMP0063: Honor visibility properties for
# all target types.
cmake_policy(SET CMP0074 NEW) # ENABLE CMP0074: find_package uses
# <PackageName>_ROOT variables.
cmake_policy(SET CMP0072 NEW) # Prefer modern OpenGL

cmake_policy(SET CMP0057 NEW) # Enable IN_LIST in if()
