.. SPDX-License-Identifier:  MIT

.. _dev/git-commit-guide:

================
Git Commit Guide
================

This pages details some high-level guidance on how to use git during
development.

TL; DR
======

::

   Short (72 chars or less) summary

   More detailed explanatory text. Wrap it to 72 characters. The blank line
   separating the summary from the body is critical (unless you omit the body
   entirely).

   Write your commit message in the imperative: "Fix bug" and not "Fixed bug" or
   "Fixes bug." This convention matches up with commit messages generated by
   commands like git merge and git revert.

   Further paragraphs come after blank lines.

   - Bullet points are okay, too.

   - Typically a hyphen or asterisk is used for the bullet, followed by a single
     space. Use a hanging indent.


Commit Messages
===============

.. IMPORTANT:: The format of commit messages is checked by the server when you
               push, so do not ignore this section.

General Formatting
------------------

- Separate subject from body with a blank line

- Do not end the subject line with a period

- Capitalize the subject line and each paragraph

- Use the imperative mood in the subject line

- Wrap lines at no more than 80 characters

- Use the body to explain what and why you have done something. In most cases,
  you can leave out details about *how* a change has been made.

Body
----

.. IMPORTANT:: The level of detail in the body should reflect the complexity and
               nuance of the changes made; not all of the below points are
               relevant for all commits.

- Why is/are the change(s) being made?

- How does it address the issue?

- How was it tested/verified?

- What effects does the patch have?

- Do not assume the reader understands what the original problem was

- Do not assume the code changes are self-evident/self-documenting

- Describe any limitations of the current code


Subject Line
------------

.. IMPORTANT:: A properly formed git commit subject line should always be able
               to complete the following sentence: "If applied, this commit will
               *\<your subject line here\>*".

Subject line should have the following form, and be 72 characters or less::

  <TYPE>(issue tracker ID): Subject

Where TYPE is one of:

- feature
- bugfix
- docs
- enh
- refactor
- chore
- revert
- tests

and matches the issue types it corresponds to in the issue tracker. The issue
tracker ID is whatever you need to use so that the git commit will be linked to
the issue in your preferred issue tracker. Some examples:

- Github: ``#N``, where N is the issue number

- Jira: ``XYZ-123``, where that is the issue identifier

Rationale:

- Using the issue tracker ID in the subject line ensures that all commits in the
  commit history are linked to relevant issues, so that PMs/POs can easily
  figure out what code has been changed for resolving an issue.

- Putting the issue tracker ID in the subject line makes it easier for
  developers to figure out what commits are associated with a particular issue,
  to help resolving merge conflicts, reverting changes, etc.

- Putting the TYPE in as part of the subject line helps to further contextualize
  the, well, type of changes being made, which is *very* helpful when looking
  back at old git history and trying to make some determination about it.

- Use the imparative tense ("Add feature" not "Added feature").

  Rationale: Lines up with commit messages generated by commands like ``git
  merge`` and ``git revert``.

Bad Commit Message Examples
===========================

Partially stolen from here:
`<https://wiki.openstack.org/wiki/GitCommitMessages#Information_in_commit_messages>`_.

Example 1
---------

::

   commit 451aff67b38a08558fb1cc8ed38b2dc775d6ee19
   Author: [removed]
   Date:   Tue Apr 25 10:34:58 2023 -0500

    Enable RMF

Problem: this does not mention what RMF is, why it is being enabled now. This
info was actually in the issue tracker, and should have been copied into the
commit message, so that it would provide a self-contained description.

Example 2
---------

::

   commit 2020fba6731634319a0d541168fbf45138825357
   Author: [removed]
   Date:   Fri Jun 15 11:12:45 2012 -0600

    Present correct ec2id format for volumes and snaps

    Fixes bug 1013765
    * Add template argument to ec2utils.id_to_ec2_id() calls


Problem: this does not mention what the current (broken) format is, nor what the
new fixed format is. Again this info was available in the bug tracker and should
have been included in the commit message. Furthermore, this bug was fixing a
regression caused by an earlier change, but there is no mention of what the
earlier change was. e.g.::

  Present correct ec2id format for volumes and snaps

  During the volume uuid migration, done by changeset XXXXXXX, ec2 id formats
  for volumes and snapshots was dropped and is now using the default instance
  format (i-xxxxx). These need to be changed back to vol-xxx and snap-xxxx.

  Adds a template argument to ec2utils.id_to_ec2_id() calls

Example 3
---------

::

   commit 06341a7bd2ba1c7c647d587edb906773588126b2
   Author: [removed]
   Date:   Thu Apr 6 08:33:08 2023 -0600

    Added more comments

Problem: This commit message is merely documenting what was done, and not *why*
it was done, *who* it was done for, nor links to the associated issue.

Good Commit Message Examples
============================

Largely stolen from here:
`<https://wiki.openstack.org/wiki/GitCommitMessages#Information_in_commit_messages>`_.

Example 1
---------

::

   commit a7aa9ffb4dce728e78d79384e0e27fca73ace337
   Author: [removed]
   Date:   Tue Apr 4 16:06:59 2023 -0500

    Fix burst measurement initialization and DBD handling

    The default InitializeBm() method needed an override to delay
    initialization of burst measurement. This fixes DBD processing.
    Update test script to enable DBD file test.
    Move sample rate configuration to common-bazel/bazelrc.
    Bring other aspects of RA up to date with standard receiver.


Some things to note about this example commit message:

- It describes what the original problem is (delaying initialization)
- It describes what the result of the change is (fixed DBD processing)
- It notes that the tests have been updated
- It does not link to the associated issue, which could be improved; have;
  overall still a decent, self-contained, readable commit.

Example 2
---------

::

   commit 96ab2c8c5f3649d5693e4c6e9861b53545fba965
   Author: [removed]
   Date:   Wed Mar 8 13:22:21 2023 -0700

    RDE-1637: Updated the documentation for PntBurstDataShadow to note that the
    extra 56 bytes of dataSignEst are reserved for future use.

Some things to note about this example commit message:

- It links to the associated issue which contains more information.
- It describes *what* was done and *why*.
- It does not have a subject line, which could be improved.

Example 3
---------

::

   commit 7e7c2d10e62f23219e2beb3b43b4abe7e3646437
   Author: [removed]
   Date:   Fri Jan 27 14:48:28 2023 -0700

    RDE-1482: Completed refactor of module_config.

    This creates default module_config files in common containing the most
    used default values, each of which is overrideable via preprocessor
    macros (except certain derived values). An application's module config
    now should contain only those values that should be overridden and a
    include of module_config_loader.hpp which loads and replaces the default
    values.

Some things to note about this example commit message:

- It links to the associated issue which contains more information.
- It describes *what* was done and *why*.
- It describes the scope of the impact of the changes and their limitations.


Example 4
---------

::

   commit 31336b35b4604f70150d0073d77dbf63b9bf7598
   Author: [removed]
   Date:   Wed Jun 6 22:45:25 2012 -0400

   Add CPU arch filter scheduler support

   In a mixed environment of running different CPU architecutres, one would not
   want to run an ARM instance on a X86_64 host and vice versa.

   This scheduler filter option will prevent instances running on a host that it
   is not intended for.

   The libvirt driver queries the guest capabilities of the host and stores the
   guest arches in the permitted_instances_types list in the cpu_info dict of
   the host.

   The Xen equivalent will be done later in another commit.

   The arch filter will compare the instance arch against the
   permitted_instances_types of a host and filter out invalid hosts.

   Also adds ARM as a valid arch to the filter.

   The ArchFilter is not turned on by default.

   Change-Id: I17bd103f00c25d6006a421252c9c8dcfd2d2c49b

Some things to note about this example commit message:

- It describes what the problem scenario is (mixed arch deployments)
- It describes the intent of the fix (make the schedular filter on arch)
- It describes the rough architecture of the fix (how libvirt returns arch)
- It notes the limitations of the fix (work needed on Xen)

Example 5
---------

::

   commit 71f0e301132a7576f238fc1e51ae0ebc399dce43
   Author: [removed]
   Date:   Wed Jul 21 08:47:13 2021 -0400

   Add parallel option to the collect tool

   The current implementation of collect cycles through
   the specified host list, one after the other.

   This update adds a parallel (-p|--parallel) option to
   collect with the goal to decrease the time it takes to
   collect logs/data from all hosts in larger systems.

   This update does not change any of the current collect
   default options. The collect tool will take advantage
   of this new feature if the -p or --parallel option is
   specified on the command line when starting collect.

   Unless specified, all of the following test cases
   were executed for both serial and parallel collects.

   Test Plan:

   PASS: Verify collect output and logging

   Failure Cases: Failure Handling = FH

   PASS: Verify collect FH for an offline host
   PASS: Verify collect FH for host that recently rebooted
   PASS: Verify collect FH for host that reboots during collect
   PASS: Verify collect FH for host mgmnt network drop during collect
   PASS: Verify collect FH of various bad command line options
   PASS: Verify parallel collect overall timeout failure handling

   Regression:

   PASS: Verify dated collect
   PASS: Verify handling of unknown host
   PASS: Verify ^C|TERM|KILL running collect removes all child processes
   PASS: Verify Single host collect (any host)
   PASS: Verify Listed hosts collect (many different groupings)

   Soak:

   PASS: Verify repeated collects (50+) until after local fs is full

   Change-Id: I91814d14341cdc438a6d5af999b6c12d39c7d97c

Some things to note about this example commit message

- It describes what the original limitation is (collect cycles through sequentially)
- It describes the functional change being made (Add parallel option)
- It describes the intent of the change (decrease the time)
- It describes the tests executed (Test Plan)
