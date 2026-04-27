# Fedora 43 KDE Copr x86_64-v3 Builder

This repository now targets Copr rather than doing local `rpmbuild -ba` work inside CI.
It uses Copr's SCM `make_srpm` flow to generate SRPMs from Fedora dist-git content and installs
a dedicated buildroot macro package so Copr's Fedora 43 `x86_64` builders compile with an
`x86-64-v3` ISA baseline.

## What changed
- `.copr/Makefile` is the Copr entrypoint used by the SCM `make_srpm` method.
- `ci/copr-distgit-make-srpm.py` clones Fedora dist-git, downloads lookaside sources, and builds SRPMs.
- `packaging/copr-rpm-macros-x86-64-v3.spec` produces the buildroot macro package that changes Fedora's
  `%__cflags_arch_x86_64_level` to `-v3` while keeping the rest of `redhat-rpm-config` intact.
- `ci/sync-copr-packages.py` registers or updates Copr SCM package definitions and can queue builds.

## Why the macro package exists

Copr does not expose a generic `rpmbuild --define` interface for package builds. The supported way to
change buildroot macros is to build a small RPM that drops a file into `%{rpmmacrodir}` and then add
that package to the Copr chroot's additional packages list. This repo does that with
`copr-rpm-macros-x86-64-v3`.

With that package installed in the buildroot, packages that honor Fedora's standard `%optflags` /
`%set_build_flags` path will compile with `-march=x86-64-v3` on Copr builders.

## Local validation

Generate the macro SRPM:

```bash
make -f .copr/Makefile srpm outdir=dist-srpms spec=packaging/copr-rpm-macros-x86-64-v3.spec
```

Generate a Fedora dist-git package SRPM the same way Copr will:

```bash
make -f .copr/Makefile srpm outdir=dist-srpms spec=konsole
```

## Copr setup

1. Create or reuse a Copr project with the `fedora-43-x86_64` chroot enabled.
2. Sync this repository's SCM package definitions into that project:

```bash
python3 ci/sync-copr-packages.py \
  --project yourname/kde-x86-64-v3 \
  --clone-url https://github.com/<owner>/<repo>.git \
  --commit <git-ref> \
  --submit-macro-build
```

3. After the macro package build succeeds, queue the package builds:

```bash
python3 ci/sync-copr-packages.py \
  --project yourname/kde-x86-64-v3 \
  --clone-url https://github.com/<owner>/<repo>.git \
  --commit <git-ref> \
  --submit-package-builds \
  --nowait-package-builds
```

The sync step also sets the Copr chroot's additional packages list to `copr-rpm-macros-x86-64-v3`,
which is the piece that makes the `x86-64-v3` compile target apply on Copr builders.
