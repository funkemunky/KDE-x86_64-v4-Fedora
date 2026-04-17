# COPR Project Setup

Use this repository as the static definition for a personal COPR project that
rebuilds Fedora 43 KDE in `x86-64-v4`.

## Project

- Name: your choice, for example `kde-x86_64-v4`
- Chroot: `fedora-43-x86_64`
- Source type for the stack packages: `DistGit`
- DistGit instance: `fedora`
- Branch: `f43`
- AppStream metadata: `off`
- Automatic createrepo: `off` is recommended for the large rebuild

## Buildroot Macro Package

Build [custom-macros.spec](/home/dawson/Dev/MIsc/KDE-x86_64-v4/packaging/custom-macros/custom-macros.spec) first.

After it succeeds:

- open the `fedora-43-x86_64` chroot settings
- add `custom-macros` to the `Packages` field

This makes the buildroot load `/usr/lib/rpm/macros.d/macros.custom`, which
overrides `%optflags` to use:

`-march=x86-64-v4`

## Package Lists

Use these files as the project definition:

- build target binaries:
  [binary-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/binary-packages.txt)
- dist-git package names:
  [source-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-packages.txt)
- binary-to-source lookup:
  [source-map.tsv](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-map.tsv)

## Recommended COPR Procedure

1. Create the project.
2. Build `custom-macros`.
3. Add `custom-macros` to the `fedora-43-x86_64` chroot package list.
4. Add every package from `source-packages.txt` as a Fedora DistGit package pinned to `f43`.
5. Start with one broad rebuild pass.
6. Run a second pass over the same package set so consumers rebuild against already rebuilt `x86-64-v4` libraries.

## Notes

- This repo is intentionally static. It does not attempt to solve dependency ordering for you.
- If you want stricter ordering, use `source-map.tsv` and split the project into manual batches in the COPR UI or `copr-cli`.
- The package set here is intended for Fedora 43 and should be refreshed if Fedora KDE package selection changes.
