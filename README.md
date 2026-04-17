# Fedora 43 KDE x86-64-v4 COPR Repo

This repository is a static input repo for a personal COPR project on
`copr.fedorainfracloud.org`.

It contains:

- a buildroot macro RPM that forces `x86-64-v4` optimization
- the Fedora 43 KDE binary package manifest
- the Fedora 43 KDE source package manifest
- the binary-to-source mapping used to populate the COPR project

It does not contain queueing or automation scripts.

## Purpose

The target package set is Fedora 43 `KDE Plasma Workspaces`, based on the
Fedora KDE spin package selection:

- environment: `kde-desktop-environment`
- extra groups: `firefox`, `kde-apps`, `kde-media`, `kde-pim`,
  `kde-spin-initial-setup`, `libreoffice`
- Fedora KDE spin additions such as `fedora-release-kde`, `plasma-welcome-fedora`,
  `kde-l10n`, `fuse`, `mediawriter`, `libreoffice-draw`, `libreoffice-math`
- Fedora KDE spin removals such as `admin-tools`, `tracker`, `tracker-miners`,
  `mariadb-server-utils`, `ktorrent`, `digikam`, `kipi-plugins`, `krusader`, `k3b`

The checked-in manifests currently resolve to:

- 342 binary packages in [binary-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/binary-packages.txt)
- 265 source packages in [source-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-packages.txt)

## Repo Contents

- Macro RPM spec: [custom-macros.spec](/home/dawson/Dev/MIsc/KDE-x86_64-v4/packaging/custom-macros/custom-macros.spec)
- Binary package list: [binary-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/binary-packages.txt)
- Source package list: [source-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-packages.txt)
- Binary to source mapping: [source-map.tsv](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-map.tsv)
- COPR setup notes: [project-setup.md](/home/dawson/Dev/MIsc/KDE-x86_64-v4/copr/project-setup.md)

## How To Use This Repo In COPR

1. Create a personal COPR project with chroot `fedora-43-x86_64`.
2. Build [custom-macros.spec](/home/dawson/Dev/MIsc/KDE-x86_64-v4/packaging/custom-macros/custom-macros.spec) into that project as `custom-macros`.
3. Edit the project chroot and add `custom-macros` to the buildroot package list.
4. Register each package from [source-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-packages.txt) as a Fedora dist-git package on branch `f43`.
5. Queue the rebuild in COPR batches, starting with low-level libraries and core KDE/Qt pieces if you want tighter ordering, or by broad passes if you are comfortable with a coarse rebuild.

The exact COPR-side settings are documented in
[project-setup.md](/home/dawson/Dev/MIsc/KDE-x86_64-v4/copr/project-setup.md).
