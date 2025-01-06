Contribution Guidelines
==

This package is developed in the open by the OCaml community for the OCaml community.

This document is a collection of guides to facilitate contributions to the project.

Meta Goals
--

We want contributions to be easy for outsiders who are not familiar with
the internals of the project. We also want contributions to be easy to
review and to approve by the project admins.

One-off contributions
--

We encourage first-time contributions
but before making complicated changes, it's best to open an
issue in which you present
your plans. For simple bugfixes and enhancements, you don't have to file
an issue first but it's generally a good idea.

Build the project with `make`. Test it with `make test`.

When making a pull request (PR), a check list will remind you of a few
essential things that need to be taken care of before the PR can be
reviewed and merged into the main branch. We have CI checks in place. Make
sure that they pass.

If you would like to make an official release, notify a project
admin. They will follow the instructions below.

Release instructions for admins
--

The release process involves assigning a
[version ID](https://semver.org/), tagging a git commit with this
version ID, building an archive, and publishing the opam packages that
use this archive.
[dune-release](https://github.com/ocamllabs/dune-release) makes this
process easy and safe. Refer to its documentation for more information.

Note that:
* We run the release steps directly on the main branch. We could
  resort to creating a branch if pushing to the main branch was
  restricted or if there was significant material to review.
* The point of no return is `dune-release publish`. If there's a
  failure after that, the release ID should be incremented and all the
  steps should be followed again.

1. Review and update the changelog `CHANGES.md`.
2. Create a section with the desired version e.g. `2.3.0
   (2025-01-06)`.
3. Commit the changes.
4. Install [dune-release](https://github.com/ocamllabs/dune-release)
   if not already installed:
   `opam install dune-release`
5. Run `make opam-release` or run the individual steps below by hand:
   * Run `dune-release tag`. It will pick up the version from the
     changelog and ask for confirmation.
   * Run `dune-release distrib` to create a tarball.
   * Run `dune-release publish` to upload the tarball to GitHub and
     create GitHub release including the changes extracted from the
     changelog.
   * Create opam packages with `dune-release opam pkg`.
   * Submit the opam packages to opam-repository using
     `dune-release opam submit`.
6. Fix the opam-repository pull request as needed. For example, this
   may require setting a new version constraint on the `atd` package
   in the opam files, if it wasn't possible to do so in
   `dune-project`.
7. Check whether opam-repository's CI test succeed and fix problems
   accordingly until the pull request is merged.
