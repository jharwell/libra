#
# Copyright 2022 John Harwell, All rights reserved.
#
# SPDX-License Identifier:  MIT
#
include(libra/test/negative)

#[[.rst:
.. cmake:command:: set_policy

  Set a CMake policy if that policy exists in the running CMake version.
  Silently does nothing if the policy is unknown, making it safe to use
  forward-compatibility guards without version checks at the call site.

  :param POL: The policy identifier, e.g. ``CMP0077``.
  :param VAL: The value to set: ``NEW`` or ``OLD``.
]]
function(set_policy POL VAL)

  if(POLICY ${POL})
    cmake_policy(SET ${POL} ${VAL})
  endif()

endfunction(set_policy)

#[[.rst:
.. cmake:command:: _libra_list_extract

  Extract elements from a list that match a given regular expression.

  :param OUTPUT: Name of the variable in the caller's scope that receives the
   list of matching elements. Existing contents are preserved; matches are
   appended.
  :param REGEX: Regular expression passed to CMake's ``MATCHES`` operator.
  :param ARGN: The list of elements to filter (passed as additional positional
   arguments).

  Example::

    _libra_list_extract(MY_HEADERS "\\.hpp$" ${ALL_FILES})
]]
function(_libra_list_extract OUTPUT REGEX)
  foreach(FILENAME ${ARGN})
    if(${FILENAME} MATCHES "${REGEX}")
      list(APPEND ${OUTPUT} ${FILENAME})
    endif()
  endforeach()

  set(${OUTPUT}
      ${${OUTPUT}}
      PARENT_SCOPE)

endfunction(_libra_list_extract)

#[[.rst:
.. cmake:command:: dual_scope_set

  Set a variable to the same value in both the current scope and the immediate
  parent scope. Useful inside macros (which share scope with the caller) when
  you also need the variable to be visible after the macro returns into a
  function's parent.

  :param name: Name of the variable to set.
  :param value: Value to assign.
]]
macro(dual_scope_set name value)
  set(${name}
      "${value}"
      PARENT_SCOPE)
  set(${name} "${value}")
endmacro()

#[[.rst:
.. cmake:command:: _libra_get_project_language

  Detect the primary language of the current project and store it in ``OUT``.
  C++ is preferred over C when both are enabled.  The result is one of
  ``CXX`` or ``C``; ``OUT`` is left unset if neither compiler is loaded.

  :param OUT: Name of the variable that receives the language string
   (``CXX`` or ``C``).
]]
macro(_libra_get_project_language OUT)
  if(CMAKE_CXX_COMPILER_LOADED)
    set(${OUT} CXX)
  elseif(CMAKE_C_COMPILER_LOADED)
    set(${OUT} C)
  endif()

endmacro()

#[[.rst:
.. cmake:command:: _libra_calculate_srcs

  Populate source and header lists for a given build purpose by inspecting the
  project's language and the well-known ``${PROJECT_NAME}_<LANG>_SRC`` /
  ``${PROJECT_NAME}_<LANG>_HEADERS`` variables.  Files whose extension matches
  any entry in ``_LIBRA_NEGATIVE_EXTENSIONS`` are silently excluded (they are
  intentional negative-compilation tests and must not be analysed or built
  normally).

  The macro sets ``SRCS_RET`` and ``HEADERS_RET`` in the caller's scope.

  :param SOURCE: Purpose token that controls which sources are included.
   Pass ``APIDOC`` to restrict to non-test sources; any other value includes
   test sources as well.

  :param SRCS_RET: Name of the variable that receives the filtered source list.

  :param HEADERS_RET: Name of the variable that receives the header list.
]]
macro(_libra_calculate_srcs SOURCE SRCS_RET HEADERS_RET)
  libra_message(STATUS "Calculating sources for ${SOURCE}")
  _libra_get_project_language(_LANGUAGE)
  list(APPEND CMAKE_MESSAGE_INDENT " ")

  if("${_LANGUAGE}" MATCHES "CXX")
    libra_message(STATUS "Detected language C++ for project")
  elseif("${_LANGUAGE}" MATCHES "C")
    libra_message(STATUS "Detected language C project")
  endif()

  if(NOT _LANGUAGE)
    libra_message(WARNING "Unable to autodetect language--assuming CXX.")
    set(_LANGUAGE CXX)
  endif()

  if("${_LANGUAGE}" STREQUAL "C")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_C_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_C_HEADERS})
    else()
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_C_SRC}
                         ${${PROJECT_NAME}_C_TESTS_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_C_HEADERS})
    endif()
  elseif("${_LANGUAGE}" STREQUAL "CXX")
    if("${SOURCE}" STREQUAL "APIDOC")
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_CXX_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_CXX_HEADERS})
    else()
      set(CANDIDATE_SRCS ${${PROJECT_NAME}_CXX_SRC}
                         ${${PROJECT_NAME}_CXX_TESTS_SRC})
      set(CANDIDATE_HEADERS ${${PROJECT_NAME}_CXX_HEADERS})
    endif()
  else()
    libra_error("Bad language '${_LANGUAGE}' for project: must be {C,CXX}")
  endif()

  set(SELECTED_HEADERS ${CANDIDATE_HEADERS})
  set(SELECTED_SRCS)
  foreach(file ${CANDIDATE_SRCS})
    get_filename_component(_fname ${file} NAME)

    set(_SKIP_NEG_TEST)
    foreach(neg_ext ${_LIBRA_NEGATIVE_EXTENSIONS})
      if(_fname MATCHES "\\.${neg_ext}$")
        libra_message(STATUS "Skipping negative compilation test ${file}")
        set(_SKIP_NEG_TEST YES)
        continue()
      endif()
    endforeach()
    if(_SKIP_NEG_TEST)
      continue()
    endif()
    list(APPEND SELECTED_SRCS ${file})
  endforeach()

  set(${SRCS_RET} ${SELECTED_SRCS})
  set(${HEADERS_RET} ${SELECTED_HEADERS})
  list(POP_BACK CMAKE_MESSAGE_INDENT)
endmacro()

#[[.rst:
.. cmake:command:: _libra_register_custom_target

  Record a LIBRA custom target and its gating options in
  ``${CMAKE_BINARY_DIR}/libra_targets.cmake`` so that
  :cmake:command:`_libra_create_targets_json` can later serialise availability
  state into ``libra_targets.json``.

  Each call appends a 3-element record to the ``_LIBRA_SUMMARY_TARGETS`` list
  stored in the ``.cmake`` file::

    [NAME, OPTIONS_SERIALIZED, TOOL]

  ``OPTIONS_SERIALIZED`` is the semicolon-separated option list. The current
  ON/OFF value of every option and the resolved tool path are also written so
  the file is self-contained after ``include()``.

  Registration is skipped for subprojects pulled in via ``add_subdirectory()``
  or CPM to avoid duplicate entries; only the top-level source directory
  registers targets.

  :param NAME: The CMake target name, e.g. ``analyze-clang-tidy-bugprone``.

  :param OPTIONS: A CMake list of one or more LIBRA option variable names that
   must **all** be ``ON`` for the target to be available, e.g.
   ``"LIBRA_ANALYSIS;LIBRA_CLANG_TIDY_CATEGORY_TARGETS"``.  A single option
   may be passed as a plain string.

  :param TOOL: The CMake variable name whose value is the path to the required
   tool executable (e.g. ``CLANG_TIDY_EXECUTABLE``).  Pass ``NONE`` for
   targets that are not gated on a tool being present.
]]
function(_libra_register_custom_target NAME OPTIONS TOOL)
  if(NOT NAME)
    libra_error("_libra_register_custom_target: NAME is required")
  endif()
  if(NOT OPTIONS)
    libra_error("_libra_register_custom_target: OPTIONS is required")
  endif()
  if(NOT TOOL)
    libra_error(
      "_libra_register_custom_target: TOOL is required (pass NONE if tool-agnostic)"
    )
  endif()

  # Don't register for subprojects included via add_subdirectory() or CPM. We
  # can't use the cache trick here because none of that stuff exists yet; this
  # function is called on initial file import for custom targets LIBRA creates.
  # This SEEMS to work well enough.
  if(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    return()
  endif()

  set(_targets_file "${CMAKE_BINARY_DIR}/libra_targets.cmake")

  if(NOT TOOL STREQUAL "NONE")
    set(_tool_val "${${TOOL}}")
  else()
    set(_tool_val "")
  endif()

  # Serialize the options list with \; so CMake list separators survive the
  # file(APPEND) round-trip inside [[ ]] brackets.
  string(REPLACE ";" "\\;" _opts_serialized "${OPTIONS}")
  file(
    APPEND "${_targets_file}"
    "list(APPEND _LIBRA_SUMMARY_TARGETS [[${NAME}]] [[${_opts_serialized}]] [[${TOOL}]])\n"
  )

  # Write each option's current value so _libra_create_targets_json can
  # re-evaluate them after include()ing the .cmake file.
  foreach(_opt IN LISTS OPTIONS)
    if(${_opt})
      file(APPEND "${_targets_file}" "set([[${_opt}]] ON)\n")
    else()
      file(APPEND "${_targets_file}" "set([[${_opt}]] OFF)\n")
    endif()
  endforeach()

  if(NOT TOOL STREQUAL "NONE")
    file(APPEND "${_targets_file}" "set([[${TOOL}]] [[${_tool_val}]])\n")
  endif()
endfunction()
