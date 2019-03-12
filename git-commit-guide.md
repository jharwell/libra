# Git Commit Guide

## Basic Stuff

- Use the present tense ("Add feature" not "Added feature")

- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")

- Limit the first line (subject line) to 72 characters or less

- Subject line should have the following form:

        <TYPE>(#issue_number): Subject

  Where TYPE is one of [feature, bugfix, docs, enh, refactor, chore, revert,
  tests], and matches the issue types it corresponds to (see the [Git Issue
  Guide](git-issue-guide.md) for further explanations).

- Reference issues and pull requests liberally after the first line.

- Your commit messages don't have to be an essay, but they should all reference
  the issue # of the task so that in-progress commits show up in github, and
  describe what was done and why in reasonable detail. Don't do things like "in
  progress", or "misc updates", or if you do such things, rebase/collapse your
  history into a single detailed commit when you are done BEFORE merging to
  devel.

  *DO NOT REBASE/REWRITE HISTORY ON* `devel` *OR* `master` *BRANCHES.*

## Semantic Versioning

In addition, you may need to put an appropriate tag for semantic versioning
somewhere in your message (I usually put it at the bottom), depending on if you
are working on one of the following categories of issues:

- Feature -> `+semver: feature`
- Bugfix -> `+semver: bugfix`
- Docs -> `+semver: docs`
- Enhancement -> `+semver: enh`

There should only be ONE semantic versioning tag for each issue/task you are
working on, so you should add it on the last commit on your branch before you
merge to `devel`.
