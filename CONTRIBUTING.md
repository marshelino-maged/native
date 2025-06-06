# How to Contribute

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow.

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement (CLA). You (or your employer) retain the copyright to your
contribution; this simply gives us permission to use and redistribute your
contributions as part of the project. Head over to
<https://cla.developers.google.com/> to see your current agreements on file or
to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

## Code Reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

## Coding style

The Dart source code in this repo follows the:

  * [Dart style guide](https://dart.dev/guides/language/effective-dart/style)

You should familiarize yourself with those guidelines.

## File headers

All files in the Dart project must start with the following header; if you add a
new file please also add this. The year should be a single number stating the
year the file was created (don't use a range like "2011-2012"). Additionally, if
you edit an existing file, you shouldn't update the year.

    // Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
    // for details. All rights reserved. Use of this source code is governed by a
    // BSD-style license that can be found in the LICENSE file.

## Community Guidelines

This project follows
[Google's Open Source Community Guidelines](https://opensource.google/conduct/).

We pledge to maintain an open and welcoming environment. For details, see our
[code of conduct](https://dart.dev/code-of-conduct).

## Tests

Packages `hooks`, `code_assets`, `data_assets`, `hooks_runner`, and
`native_toolchain_c` roll into the Dart SDK. The tests of these packages are run
on the Dart SDK in [a different
way](https://github.com/dart-lang/sdk/issues/56574) than on the GitHub actions
on this repo.

1. The `tools/test.py` runs `(.*)test.dart`, so no `package:test` annotations
   are respected. So, things such as skips should be done with early returns.
2. The `tools/test.py` does not run test in the root directory of the package,
   So, any test accessing test data must do so via `findPackageRoot`.
3. Native toolchains for cross compilation are not available. So tests doing
   cross compilation must be in a separate test file, and will be skipped on
   the Dart CI.
4. Native toolchains are not installed in default locations. So, any test
   manually instantiating `HookConfig`s must pass in the environment.

The `jnigen` packages has a set of test cases that use the Java build library 
Maven (`mvn` command) to build some sources and run integration tests. 

On Linux and MacOS, it can be installed with the [`sdkman`](https://sdkman.io/)
 package manager or a manual method. On Windows, it can be installed with 
[chocolatey](https://community.chocolatey.org/packages/maven) or 
[scoop](https://scoop.sh/#/apps?q=maven).
