# Luigi Build Reusable Automation (LIBRA)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This is a repository containing 100% reusable cmake scaffolding that can be used
for nested/flat C/C++ projects (even mixing the two), and provides resuable
build "plumbing" that can be transferred without modification between projects.

Also contains some generally useful guides:

- [C++ Development Guide](cxx-devel-guide.md)
- [Git Commit Guide](git-commit-guide.md)
- [Issue Usage Guide](git-issue-guide.md)

## Motivation

I've found myself frequently copying and pasting CmakeLists.txt between
projects, and when I find a new flag I want to add, or a new static analysis
checker, etc., I would have to go and add it to EVERY project individually. By
using this repository as a submodule, that can be avoided.

## Platform Requirements

- A recent version of Linux.

- cmake >= 3.9 (`cmake` on ubuntu)

- make >= 3.2 (`make` on ubuntu)

- cppcheck >= 1.72. (`cppcheck` on ubuntu)

- graphviz (`graphviz` on ubuntu)

- doxygen (`doxygen` on ubuntu)

- gcc/g++ >= 8.0 (`gcc-8` on ubuntu). Only required if you want to use the GNU
  compilers. If you want to use another compiler, this is not required.

- icpc/icc >= 18.0. Only required if you want to use the Intel
  compilers. If you want to use another compiler, this is not required.

- clang/clang++ >= 6.0. Only required if you want to use the LLVM
  compilers. If you want to use another compiler, this is not
  required.

### Clang Tooling

Everything should have version >= 6.0 for best results. However, if that version
of the tools is not in the package repositories, you can replace it with 5.0 or
4.0, and things should still work.

- Base tooling and clang-check (`libclang-6.0-dev` and `clang-tools-6.0`).

- clang-format >= 6.0 (`clang-format-6.0`).

- clang-tidy >= 4.0 (`clang-tidy-6.0`).


## Source Requirements

- All C++ source files end in `.cpp`, and all C++ header files end in `.hpp`.

- All C source files end in `.c` and all C header files end in `.h`.

- All source files for a repository must live under `src/` in the root.

- All include files for a repository must live under `include/<repo_name>` in
  the root.

- All tests (either C or C++) for a project/submodule must live under the
  `tests/` directory in the root of the project, and should end in `-test.cpp`
  so it is clear they are not source files.

- If a C++ file lives under `src/my_module/my_file.cpp` then its corresponding
  include file is found under `include/<repo_name>/my_module/my_file.hpp` (same
  idea for C, but with the corresponding extensions).

- All projects must include THIS repository as a submodule under `libra/` in the
  project root, and link a `CmakeLists.txt` in the root of the repository to the
  `libra/cmake/project.cmake` file in this repository.

- All projects must include a `project-local.cmake` in the root of the
  repository containing any project specific bits (i.e. adding subdirectories,
  what libraries to create, etc.).

## Build Modes

There are 3 build modes that I use, which are different from the default ones
that cmake uses, because they did not do what I wanted.

- `DEV` - Development mode. Turns on all compiler warnings and NO optimizations.

- `DEVOPT` - Development mode + light optimizations. Turns on all compiler
             warnings + `-Og` + parallelization (if configured). Does not define
             `NDEBUG`.

- `OPT` - Optimized mode. Turns on all compiler warnings and maximum
          optimizations (`O2`), which is separate from enabled automatic/OpenMP
          based paralellization. Defines `NDEBUG`.

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


## Capabilities

### Compiler Support `g++, clang++, icpc`/`gcc, clangc, icc`

A recent version of any supported compiler can be selected as the
`CMAKE_CXX_COMPILER` via command line [Default=`g++`]. The correct compile
options will be populated (as in the ones defined in the corresponding .cmake
files in this repository). Same for `CMAKE_C_COMPILER`. Note that the C and CXX
compiler vendors should almost always match, in order to avoid strange build
issues.

### Compiler Runtime Checking
Build in run-time checking of code using any compiler via the cmake option
`WITH_CHECKS` [Default=NO]. When passed, the value should be a command-separated
list of checks to enable:

- `MEM` - Memory checking/sanitization.
- `ADDR` - Address sanitization.
- `STACK` - Agressive stack checking.
- `MISC` - Other potentially helpful checks.

Not all compilerconfigurations use all categories, and not all combinations of
checkers are compatible, so use with care.

### Variables

Uses the following variables for fine-tuning the build process

| Variable          | Description                                                                                           | Default     |
|-------------------|-------------------------------------------------------------------------------------------------------|-------------|
| `WITH_TESTS`      | Enable building of unit tests via `make unit_tests`                                                   | NO          |
| `WITH_OPENMP`     | Enable OpenMP code                                                                                    | NO          |
| `WITH_MPI`        | Enable MPI code                                                                                       | NO          |
| `WITH_FPC`        | Enable function precondition checking (mostly used in C) This is very helpful for debugging. Possible | `FPC_ABORT` |
|                   | values are:                                                                                           |             |
|                   | `FPC_RETURN` - Return without executing a function, but do not assert().                              |             |
|                   | `FPC_ABORT` - Abort the program whenever a function precondition.                                     |             |
| `WITH_ER_NREPORT` | Disable event reporting entirely, and do not link with log4cxx.                                       | NO          |

## Automation via Make Targets

In addition to being able to actually build the software, this project enables
the following additional capabilities via makefile targets.

- `format-all` - Run the clang formatter on the repository, using the
  `.clang-format` in the root of the repo.

- `check-all` - Run ALL enabled static checkers on the repository. If the
                repository using modules/cmake subprojects, you can also run it
                on a per-module basis. This runs the following sub-targets,
                which can also be run individually:

    - `cppcheck-all` - Runs cppcheck on the repository.

    - `static-check-all` - Runs the clang static checker on the repository.

    - `tidy-check-all` - Runs the clang-tidy checker on the repository, using
                         the `.clang-format` in the root of the repo.

- `unit_tests` - Build all of the unit tests for the project. If you want to
                 just build a single unit test, you can do `make <project
                 name>-<class name>-test`. For example: `make rcppsw-hfsm-test`
                 for a single unit test named `hfsm-test.cpp` that lives under
                 `tests/` in the `rcppsw` project.

- `test` - Run all of the tests for the project.

## Unit Tests

Unit tests can utilize whatever unit testing framework is desired, though
`gtest` or `catch` are easy to setup/use. Unit tests should be structured as
follows:

- Each tested class should get its own `-test.cpp` file, unless there is a very
  good reason to do otherwise.

- For each public member function in the class under test that is not a trivial
  getter/setter, at least 1 test case should be included for it, so that every
  code path through the function is evaluated as least once. For complex
  functions, multiple test cases may be necessary. If a function is not easy to
  test, chances are it should be refactored.

- Documentation for the class should be updated in tandem with writing the unit
  tests, so that it is clear what the assumptions/requirements of class
  usage/function usage are.


# License
This project is licensed under GPL 3.0. See [LICENSE](LICENSE.md).

# Donate
If you've found this project helpful, please consider donating somewhere between
a cup of coffe and a nice meal:

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/jharwell1406)
