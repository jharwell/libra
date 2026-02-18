.. _design/cli:

==============
LIBRA CLI Tool
==============

.. DANGER:: This is an in-progress document/spec which may change at any time!

Top-level Interface
===================

::

  libra <command> [options] [args]

Global Flags (available on all commands)::

  --verbose, -v - Increase output verbosity (stackable: -vv, -vvv)
  --quiet, -q - Suppress non-error output
  --color={auto,always,never} - Control colored output
  --build-dir=<path> - Override default build directory (default: build/)
  --json - Output machine-readable JSON (for IDE integration)
  --dry-run - Show what would happen without executing
  --help, -h - Show help for command
  --version - Show libra CLI version and detected LIBRA framework version

1. Project Initialization
=========================

::

   libra init [project-name]

Purpose: Bootstrap a new LIBRA project with sensible defaults.
Behavior:

- Creates directory structure (src/, include/, tests/, cmake/)
- Generates minimal CMakeLists.txt (with find_package(libra))
- Creates cmake/project-local.cmake with template
- Initializes git repository (optional)
- Creates .gitignore with build artifacts
- Optionally generates CI/CD templates (GitHub Actions, GitLab CI)

Options::

  --language=<c|cxx|both> - Project language (default: cxx)
  --type=<executable|library|header-only> - Project type
  --conan - Add Conan integration (generates conanfile.py)
  --tests - Enable test discovery from start (default: true)
  --ci=<github|gitlab|jenkins|none> - Generate CI configuration
  --template=<minimal|full|quality> - Use predefined project template

  minimal: Just sources, no tests/docs
  full: Sources, tests, docs, analysis
  quality: Full + strict compiler warnings, sanitizers, coverage


  --no-git - Skip git initialization

Interactive Mode:
If no options provided, prompt user with questionnaire::

  Project name?
  Language? (C, C++, both)
  Type? (executable, library, header-only)
  Enable tests? (y/n)
  Enable documentation? (y/n)
  Enable static analysis? (y/n)
  Generate CI config? (GitHub Actions, GitLab CI, none)

Examples::

  libra init my_project
  libra init my_lib --type=library --language=cxx --conan
  libra init --template=quality --ci=github

Possible output::

  ✓ Created project structure
  ✓ Generated CMakeLists.txt
  ✓ Generated cmake/project-local.cmake
  ✓ Initialized git repository
  ✓ Created .gitignore
  ✓ Generated .github/workflows/ci.yml

  Next steps:
    1. cd my_project
    2. Edit src/main.cpp
    3. libra build
    4. libra test


2.Configuration Management
==========================

::

   libra config [action]

Purpose: Manage LIBRA configuration variables without raw CMake commands.

Sub-commands
------------

::

  libra config list

Show all LIBRA variables and their current values. Options::

  --available - Show all available variables with descriptions
  --filter=<pattern> - Filter by variable name (glob pattern)
  --category=<optimization|quality|testing|docs> - Filter by category

::

   libra config set <VAR>=<VALUE>

Set a LIBRA variable for current project
Supports multiple variables::

  libra config set LIBRA_TESTS=ON LIBRA_SAN=ASAN

Options::

  --profile=<debug|release|relwithdebinfo|minsizerel> - Apply to specific profile
  --persist - Write to cmake/project-local.cmake (not just current build)

::

   libra config get <VAR>

Show current value of a variable

::

   libra config reset

Reset configuration to defaults. Options::

  --all - Reset everything
  --profile=<name> - Reset specific profile

::

   libra config profile <name>

Manage configuration profiles (preset collections of variables)

Built-in profiles::

  dev - Fast iteration (no optimization, sanitizers enabled)
  ci - Continuous integration (coverage, analysis, all tests)
  release - Production build (optimized, LTO, no debug)
  performance - Maximum optimization (PGO, native tuning, LTO)
  debug - Heavy debugging (debug symbols, sanitizers, no optimization)


Examples::

  libra config list
  libra config list --category=quality
  libra config set LIBRA_CODE_COV=ON LIBRA_TESTS=ON
  libra config profile dev
  libra config set LIBRA_SAN="ASAN+UBSAN" --persist

3. Building
===========

::

   libra build [targets...]

Purpose: Build the project with smart defaults.
Behavior:

- Automatically configures if not already configured
- Detects compiler (GCC/Clang/Intel) from environment
- Builds specified targets or all targets if none specified
- Shows progress and compiler output
- Reports timing statistics

Options::

  --profile=<name> - Use configuration profile (dev/ci/release/performance/debug)
  --compiler=<gcc|clang|intel> - Force specific compiler
  --jobs=<N>, -j<N> - Parallel build jobs (default: auto-detect CPU cores)
  --clean - Clean before building
  --reconfigure - Force CMake reconfiguration
  --target=<name> - Build specific target (repeatable)
  --install - Build and install to prefix
  --prefix=<path> - Override install prefix

Common Presets::

  libra build - Build everything (default configuration)
  libra build --profile=dev - Fast development build
  libra build --profile=release - Optimized release build
  libra build --clean - Clean rebuild
  libra build my_lib - Build specific target

Examples::

  libra build
  libra build --profile=release --jobs=8
  libra build --compiler=clang --clean
  libra build my_lib my_test --profile=dev

Possible output::

  [1/42] Building CXX object CMakeFiles/my_lib.dir/src/core.cpp.o
  [2/42] Building CXX object CMakeFiles/my_lib.dir/src/utils.cpp.o
  ...
  [42/42] Linking CXX executable bin/my_app

  Build completed in 12.3s


4. Testing
==========

::

   libra test [test-pattern]

Purpose: Run tests with sensible defaults and clear output.

Behavior:

- Automatically builds tests if not already built
- Runs tests matching pattern (or all if no pattern)
- Shows pass/fail status per test
- Reports coverage if enabled
- Optionally runs under sanitizers/valgrind

Options::

  --filter=<pattern> - Run tests matching pattern (glob or regex)
  --type=<unit|integration|regression|all> - Filter by test type
  --coverage - Generate coverage report after tests
  --sanitizer=<asan|ubsan|tsan|msan> - Run tests under sanitizer
  --valgrind - Run tests under valgrind
  --repeat=<N> - Run tests N times (for flaky test detection)
  --parallel=<N> - Run N tests in parallel (default: auto)
  --stop-on-failure - Stop at first failure
  --shuffle - Randomize test execution order
  --list - List available tests without running

Examples::

  libra test
  libra test --filter="*math*"
  libra test --type=unit --coverage
  libra test --sanitizer=asan --stop-on-failure
  libra test --list

Possible Output::

  Running 15 tests...

  [PASS] core-utest (0.12s)
  [PASS] utils-utest (0.08s)
  [FAIL] network-utest (0.45s)
    Assertion failed: expected 200, got 404

  Summary: 14 passed, 1 failed, 0 skipped (2.3s total)

  [200~libra test
  libra test --filter="*math*"
  libra test --type=unit --coverage
  libra test --sanitizer=asan --stop-on-failure
  libra test --list

  Running 15 tests...

  [PASS] core-utest (0.12s)
  [PASS] utils-utest (0.08s)
  [FAIL] network-utest (0.45s)
    Assertion failed: expected 200, got 404

    Summary: 14 passed, 1 failed, 0 skipped (2.3s total)~```**``]

5. libra coverage
=================

::

  libra coverage --open
  libra coverage --format=terminal --threshold=80
  libra coverage --exclude="*test*" --exclude="*_generated*"
  libra coverage --upload=codecov  # In CI

Possible Output::

  Generating coverage report...

  File                    Lines    Functions    Branches
  ──────────────────────────────────────────────────────
  src/core.cpp           87.5%       90.0%       82.3%
  src/utils.cpp          92.1%       95.2%       88.7%
  src/network.cpp        45.2%       60.0%       38.9%
  ──────────────────────────────────────────────────────
  TOTAL                  78.3%       82.1%       73.6%

  HTML report: build/coverage/index.html

6. Static Analysis
==================

::

   libra analyze [tool]

Purpose: Run static analysis tools with minimal configuration.

Common Options (all analyzers)::

  --filter=<pattern> - Only analyze matching files
  --fail-on-error - Exit with error if issues found (CI mode)
  --json - Output results as JSON

Sub-commands
------------

::

  libra analyze all - Run all enabled analyzers
  libra analyze clang-tidy [options]

Options::

  --fix - Auto-fix issues
  --checks=<list> - Specify check categories
  --config=<file> - Use custom .clang-tidy config

::

   libra analyze cppcheck [options]

Options::

  --std=<standard> - C++ standard (c++11/14/17/20/23)

::

   libra analyze clang-check

Options::

  --fix - Auto-fix issues

::

   libra analyze format [--check]

Format code with clang-format::

  --check - Only verify formatting, don't change files


Examples::

  libra analyze all
  libra analyze clang-tidy --fix
  libra analyze format --check
  libra analyze cppcheck --fail-on-error

7. libra ci
===========

Purpose: One-command CI workflow.Behavior:

- Configure with CI profile
- Build with optimizations
- Run all tests with coverage
- Run all static analyzers
- Generate reports

Options::

  --no-coverage - Skip coverage generation
  --no-analyze - Skip static analysis
  --upload - Upload reports to services (codecov, etc.)

Examples::

  libra ci

Possible output::

  CI Mode
  [1/4] Building... ✓
  [2/4] Testing... ✓ (45/45 passed)
  [3/4] Coverage... ✓ (82.1%)
  [4/4] Analysis... ✓ (3 warnings)

  Reports:
    Coverage: build/coverage/index.html
    Analysis: build/analysis/report.txt

8. Diagnostics
==============

::

   libra doctor

Purpose: Diagnose environment and project issues.
Behavior::

- Check CMake version
- Check compiler availability and versions
- Check optional tools (lcov, cppcheck, etc.)
- Validate project structure
- Check for common configuration problems
- Suggest fixes

Options::

  --fix - Attempt automatic fixes for common issues
  --verbose - Show detailed diagnostic information

Example::

  libra doctor

Possible Output::

  Checking LIBRA environment...

  ✓ CMake 3.31 (required: >= 3.17)
  ✓ GCC 13.2 (required: >= 9)
  ✓ Clang 17.0 (required: >= 17)
  ✗ Intel icx not found
  ✓ lcov 1.16 (required: >= 1.14)
  ✓ gcovr 5.2 (required: >= 5.0)
  ⚠ cppcheck not found (optional)

  Project structure:
  ✓ CMakeLists.txt exists
  ✓ cmake/project-local.cmake exists
  ✗ src/ directory missing
    → Run: mkdir src

  2 issues found, 1 fixable with --fix


::

   libra info

Purpose: Display project configuration and status. Behavior::

- Show project name, version, language
- Show active LIBRA configuration
- Show detected compiler and tools
- Show build directory status
- Show available targets

Options::

  --targets - List all build targets
  --tests - List all discovered tests
  --vars - Show all CMake variables

Example::

  libra info

Possible output::

  Project: my_project (v1.2.3)
  Language: C++
  Compiler: GCC 13.2
  Build Type: Release
  Build Dir: build/

  LIBRA Configuration:
    LIBRA_TESTS: ON
    LIBRA_CODE_COV: ON
    LIBRA_ANALYSIS: ON
    LIBRA_SAN: ASAN+UBSAN
    LIBRA_LTO: ON

  Targets: 4 total
    Executables: my_app
    Libraries: my_lib
    Tests: 15 (unit: 10, integration: 5)

9. Profile-Guided Optimization
==============================

::

   libra pgo

Purpose: Simplified PGO workflow. Behavior:

- Phase 1 (generate): Build with instrumentation, run representative workload
- Phase 2 (use): Rebuild with profile data, optimize

Options::

  --workload=<command> - Command to run for profile generation
  --phase=<gen|use|auto> - Manual phase selection (default: auto)

Example::

  # Automatic two-phase build
  libra pgo --workload="./bin/my_app benchmark.dat"

  # Manual two-phase
  libra pgo --phase=gen
  ./bin/my_app benchmark.dat
  libra pgo --phase=use


Possible output::

  PGO Phase 1: Building with instrumentation...
  Running workload: ./bin/my_app benchmark.dat
  Profile data generated: 42MB

  PGO Phase 2: Rebuilding with profile optimization...
  Build complete. Binary optimized for profiled workload.

10. Configuration
=================

Project-level config: `.libra.toml`::

  [project]
  name = "my_project"
  version = "1.2.3"
  language = "cxx"

  [profiles.dev]
  LIBRA_TESTS = "ON"
  LIBRA_SAN = "ASAN+UBSAN"

  [profiles.release]
  LIBRA_LTO = "ON"
  LIBRA_NATIVE_OPT = "ON"

  [ci]
  upload_coverage = "codecov"
  fail_on_warnings = true

  [testing]
  default_filter = "*"
  parallel_jobs = 4

User level config `~/.libra/config.toml`::

  [defaults]
  compiler = "clang"
  build_dir = "build"
  jobs = 8
  color = "auto"

  [aliases]
  # Custom command aliases
  quick = "build --profile=dev --jobs=16"
  check = "analyze all && test"
