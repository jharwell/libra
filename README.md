# Reusable cmake Configuration

This is a repository containing 100% reusable cmake scaffolding that
can be used for nested/flat C/C++ projects (even mixing the two).

## Motivation

I've found myself frequently copying and pasting CmakeLists.txt
between projects, and when I find a new flag I want to add, or a new
static analysis checker, etc., I would have to go and add it to EVERY
project individually. By using this repository as a submodule, that
can be avoided.

## Platform Requirements

- A recent version of Linux.

- cppcheck >= 1.72.

- clang-check >= 4.0. Higher versions recommended (better warnings).

- clang-format >= 6.0. Versions older than 6.0 will not work, as they
  do not nest namespace forward declarations appropriately (well, what
  I consider to be appropriate).

- clang-tidy >= 4.0. Higher versions recommended (better warnings).

- gcc/g++ >= 5.4.0. Only required if you want to use the GNU
  compilers. If you want to use another compiler, this is not required.

- clang/clang++ >= 4.0. Only required if you want to use the LLVM
  compilers. If you want to use another compiler, this is not
  required.

- icpc/icc >= 18.0. Only required if you want to use the Intel
  compilers. If you want to use another compiler, this is not required.

## Source Requirements

- All C++ source files end in `.cpp`, and all C++ header files end in
  `.hpp`.

- All C source files end in `.c` and all C header files end in `.h`.

- All source files for a repository must live under `src/` in the
  root.

- All include files for a repository must live under
  `include/<repo_name>` in the root.

- All tests (either C or C++) for a project/submodule must live under
  the `tests/` directory in the root of the project/submodule.

- If a C++ file lives under `src/my_module/my_file.cpp` then its
  corresponding include file is found under
  `include/<repo_name>/my_module/my_file.hpp` (same idea for C, but
  with the corresponding extensions).

- All projects must include THIS repository as a submodule under
  `cmake/` in the project root, and link a `CmakeLists.txt` in the
  root of the repository to the `cmake/project.cmake` file in this
  repository.

- All projects must include a `project-local.cmake` in the root of the
  repository containing any project specific bits (i.e. adding
  subdirectories, what libraries to create, etc.).

- All projects can be organized as "flat", an not utilize modules, in
  which there are no subdirectories/submodules under `src/` or
  `include/`. For these projects, all source files are always
  built/analyzed/etc. as a single unit.

  Projects can also be organized hierarchically, with any depth of
  nested submodules which are themselves projects (and must therefore
  adhere to all the same requirements).

  This is configurable per-project with the `project-local.cmake`
  file.

## project-local.cmake


The `project-local.cmake` file that each repository uses has all
project-specific bits in it, so that the rest of the cmake framework can be
reused as is. Within it, the following variables can be set to affect
configuration:

- `set(${target}_CHECK_LANGUAGE "value")`

  This should be specified BEFORE any subdirectories, external projects,
  etc. are specified. `${target}` is a variable handed to the project local file
  specifying the name of the executable/library to create.

  - `"value"` can be either "C" or "C++", and defines the language that the
    different checkers will use for checking the project.

- `set(${target}_HAS_RECURSIVE_DIRS VALUE)`

  Controls whether or not the project has smaller modules/sub projects within
  it, that each have their own CMakeLists.txt and can be compiled/checked/etc
  independently of each other and the main project.

  - `VALUE` can be either YES or NO.

## Capabilities

- The cmake config supports the following compilers: `g++, clang++,
  icpc`; any one can be selected as the `CMAKE_CXX_COMPILER`, and the
  correct compile options will be populated (as in the ones defined in
  the corresponding .cmake files in this repository). Same for the C
  compilers for each of the 3 vendors. Note that the C and CXX
  compiler vendors should almost always match, in order to avoid
  strange build issues.

- Build in run-time checking of code using any compiler via the cmake
  option 'WITH_CHECKS' [Default=NO]. When passed, the value should be
  a command-separated list of checks to enable:

  - `MEM` - Memory checking/sanitization.
  - `ADDR` - Address sanitization.
  - `STACK` - Agressive stack checking.
  - `MISC` - Other potentially helpful checks.

  Not all compilerconfigurations use all categories, and not all
  combinations of checkers are compatible, so use with care.

- Enable building of unit tests via cmake option `WITH_TESTS`. [Default=NO]

- Enable OpenMP code via cmake option `WITH_OPENMP` [Default=NO].

- Enable MPI code via cmake option `WITH_MPI` [Defaut=NO].

- Enable function precondition checking (mostly used in C) via cmake
  option `WITH_FPC`. This is very helpful for debugging. Possible
  values are:

    - `FPC_RETURN` - Return without executing a function, but do not
      assert().

    - `FPC_ABORT` - Abort the program whenever a function precondition
             fails

    [Default=`FPC_ABORT`].

- `ER_NDEBUG` - Disable printing of assertion failures when `NDEBUG` is defined
  (as for optimized builds). [Default=undefined].

- `ER_NREPORT` - Disable reporting entirely (both debug printing and
  logging). [Default=undefined].


In addition to being able to actually build the software, this project
enables the following additional capabilities via makefile targets.

- `format-all` - Run the clang formatter on the repository, using the
  `.clang-format` in the root of the repo.

- `check-all` - Run ALL enabled static checkers on the repository. If the
      repository using modules/cmake subprojects, you can also run it on a
      per-module basis. This runs the following sub-targets, which can also be
      run individually:

    - `cppcheck-all` - Runs cppcheck on the repository.

    - `cppcheck-<module_name>` - Runs cppcheck on the specified module within
      the repository, if applicable.

    - `static-check-all` - Runs the clang static checker on the repository.

    - `static-check-<module_name>` - Runs the clang static checker on the
      specified module within the repository, if applicable.

    - `tidy-check-all` - Runs the clang-tidy checker on the
      repository, using the `.clang-format` in the root of the repo.

    - `tidy-check-<module>` - Runs the clang-tidy checker on the
      specified module with the repository, using the `.clang-format`
      in the root of the repo.

# License
This project is licensed under GPL 2.0. See [LICENSE](LICENSE.md).

# Donate
If you've found this project helpful, please consider donating somewhere between
a cup of coffe and a nice meal:

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/jharwell1406)
