.. _dev/bazel/analysis:

========================
Static Analysis In Bazel
========================

This page details how to use/interact with the static analysis functionality we
have in Bazel.

Supported Checkers
==================

The following checkers have been approved by IT for use at Satelles. Use cases
and pros/cons for each is below.

.. tabs::

   .. tab:: cppcheck

            To install: ``sudo apt-get install cppcheck``

            Configuration: None

            Use case: To catch simple/obvious things wrong with C++ code, such
            as undefined behaviors and dangerous coding constructs. Emphasis on
            very few false positives.

            Pros: Runs VERY fast, even on complex code.

            Cons: Relatively limited set of things it can flag/check for.

            See :ref:`here <dev/links/tools/cppcheck>` for full tool
            documentation.

   .. tab:: clang-tidy



            To install: ``sudo apt-get install clang-tidy``

            You can select the specific clang-tidy executable you want to use
            with::

              --@static_analysis//clang_tidy:executable=clang-tidy-X

            Valid values for ``X`` are 10,11,12,13,14.

            You can also configure the specific ``.clang-tidy`` used (though you
            shouldn't generally need to do this) with::

              --@static_analysis//clang_tidy:config=XXX


            ``XXX`` has to be a file in a bazel repository--it can't just be a
            file on the filesystem.

            Use case: Diagnosing and fixing typical programming errors, like
            style violations, interface misuse, etc., or other bugs which can be
            deduced via static analysis.

            Pros: Deep syntactical analysis of C, C++ code, with many checks
            which can be fine-tuned on a per-project basis.

            Cons: Takes a long time to run/superlinear runtime scaling as
            complexity of source code grows.

            See :ref:`here <dev/links/tools/clang-tidy>` for full tool
            documentation.

   .. tab:: clang-check


            To install: ``sudo apt-get install clang-check``


            You can select the specific clang-check executable you want to use
            with::

              --@static_analysis//clang_check:executable=clang-check-X

            Valid values for ``X`` are 10,11,12,13,14.

            Use case: Basic sanity checking/error checking by analyzing AST.

            Pros: Deep syntactical analysis of C, C++ code to find common
            issues.

            Cons: Takes a long time to run/superlinear runtime scaling as
            complexity of source code grows. Not as configurable as
            ``clang-tidy``.

            See :ref:`here <dev/links/tools/clang-check>` for full tool
            documentation.

Choosing A Checker To Run
=========================

If you are at the point of wanting to check over some code changes you've made,
you will want to eventually run your changes through *ALL* of the above
checkers, because that is what the CI/CD pipeline will ultimately do. But, in
terms of your development usage, a good order to run the checkers in--in terms of
bang-for-the-buck--is:

- clang-check -> catch things which are bugs/obvious problems

- cppcheck -> catch "easy" undefined behavior/bad coding style things

- clang-tidy -> Catch things which don't conform to selected coding style

Running a Checker
=================

Checkers use Bazel aspects to hook into the build dependency graph, so they only
run on things that Bazel is going to actually try to compile on a given
invocation. So, the recommended two-step approach to running a checker is::

  bazel clean
  bazel build --config={cppcheck,clang-tidy,clang-check} <targets>

to ensure that the checker actually runs on ALL the files on your targets of
interest.
