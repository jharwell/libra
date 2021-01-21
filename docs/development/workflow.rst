General Development Workflow
----------------------------

#. Find an issue in one of the github repos to work on that looks
   interesting/doable, possibly discussing it with me before committing.

#. Mark said task as ``Status: In Progress`` so no one else starts working on it
   too, and assign it to yourself if it is not already assigned to you.

#. Branch off of the ``devel`` branch with a branch with the *SAME* name as the
   issue. This may seem pedantic, but when you have hundreds or thousands of
   issues and branches, any little thing you can do to increase the
   self-documenting nature of the development process is worth doing. I don't
   generally delete branches, so you should be able to see how they should be
   named/link to github issues by browsing the repo.

#. Work on the issue/task, committing as needed. You should:

   - Push your changes regularly, so people can see that the issue is being
     actively worked on. Commit messages should follow the
     :ref:`ln-git-commit-guide`.

   - Rebase your branch onto the ``devel`` periodicaly so that merge
     conflicts/headaches are minimized when you do eventually merge it into
     ``devel``.

#. If you create any new functions/classes that can be unit tested, then define
   appropriate unit tests for them, and prepare a report documenting code
   coverage, as described above.

   Unit tests can utilize whatever unit testing framework is desired, though
   ``gtest`` or ``catch`` are easy to setup/use. Unit tests should be structured
   as follows:

   - Each tested class should get its own ``-test.cpp`` file, unless there is a
     very good reason to do otherwise.

   - For each public member function in the class under test that is not a
     trivial getter/setter, at least 1 test case should be included for it, so
     that every code path through the function is evaluated as least once. For
     complex functions, multiple test cases may be necessary. If a function is
     not easy to test, chances are it should be refactored.

    - Documentation for the class should be updated in tandem with writing the
      unit tests, so that it is clear what the assumptions/requirements of class
      usage/function usage are.

#. Run static analysis on the code from the root of the repo (different
   repos/projects will have different rules/ways of doing this).

   Fix ANY and ALL errors that arise in code that *YOU* have written. Depending
   on the repo, their may be reported errors/warnings that are harmless and
   ignored. Generally speaking though, ech project repo should get a clean bill
   of health from the static checker(s).

#. Change status to ``Status: Needs Review`` and open a pull request, and
   someone will review the commits. If you created unit tests, attach a log/run
   showing they all pass, and/or the code coverage report from gcov.

#. Once the task has been reviewed and given the green light, it will be merged
   into devel and marked as ``Status: Completed``, and closed (you generally
   don't need to do this).
