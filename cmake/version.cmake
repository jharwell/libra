#
# Copyright 2022 SIFT LLC, All rights reserved.
#
# RESTRICTED RIGHTS
#
# Contract No. 9700-1100-001-009
#
# Smart Information Flow Technologies
#
# 319 1st Ave N, Suite 400
# Minneapolis, MN 55401-1689
#
# The Government's rights to use, modify, reproduce, release, perform, display,
# or disclose this software are restricted by paragraph (b)(3) of the Rights in
# Noncommercial Computer Software and Noncommercial Computer Software
# Documentation clause contained in the above identified contract. Any
# reproduction of computer software or portions thereof marked with this legend
# must also reproduce the markings. Any person, other than the Government, who
# has been provided access to such software must promptly notify the above
# named Contractor.
#
function(libra_configure_version INFILE OUTFILE)
  execute_process(COMMAND git log --pretty=format:%H -n 1
    OUTPUT_VARIABLE GIT_REV
    ERROR_QUIET)

  # Check whether we got any revision (which isn't
  # always the case, e.g. when someone downloaded a zip
  # file from Github instead of a checkout)
  if ("${GIT_REV}" STREQUAL "")
    message(WARNING "Stubbing version information--no git revision")
    set(GIT_REV "N/A")
    set(GIT_DIFF "")
    set(GIT_TAG "N/A")
    set(GIT_BRANCH "N/A")
  else()
    execute_process(
      COMMAND bash -c "git diff --quiet --exit-code || echo +"
      OUTPUT_VARIABLE GIT_DIFF)
    execute_process(
      COMMAND git describe --exact-match --tags
      OUTPUT_VARIABLE GIT_TAG ERROR_QUIET)
    execute_process(
      COMMAND git rev-parse --abbrev-ref HEAD
      OUTPUT_VARIABLE GIT_BRANCH)

    string(STRIP "${GIT_REV}" GIT_REV)
    # string(SUBSTRING "${GIT_REV}" 1 7 GIT_REV)
    string(STRIP "${GIT_DIFF}" GIT_DIFF)
    string(STRIP "${GIT_TAG}" GIT_TAG)
    string(STRIP "${GIT_BRANCH}" GIT_BRANCH)
  endif()

  configure_file(${INFILE} ${OUTFILE})

  list(APPEND ${PROJECT_NAME}_SRC ${OUTFILE})
endfunction()
