# Fedora 43 KDE GitHub Actions RPM Builder

This repository is a static GitHub Actions input repo for rebuilding Fedora 43
KDE packages from Fedora dist-git with `x86-64-v4` code generation and `-O3`
optimization.

## What Is Checked In

- Fedora 43 KDE binary package manifest:
  [binary-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/binary-packages.txt)
- Fedora 43 source package manifest:
  [source-packages.txt](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-packages.txt)
- Binary to source mapping:
  [source-map.tsv](/home/dawson/Dev/MIsc/KDE-x86_64-v4/manifests/fedora-43/source-map.tsv)
- A reference macro RPM spec showing the intended RPM flag override:
  [custom-macros.spec](/home/dawson/Dev/MIsc/KDE-x86_64-v4/packaging/custom-macros/custom-macros.spec)
- On-demand GitHub Actions workflow:
  [build-fedora-rpms.yml](/home/dawson/Dev/MIsc/KDE-x86_64-v4/.github/workflows/build-fedora-rpms.yml)

The checked-in manifests currently cover:

- 342 Fedora 43 binary packages
- 265 Fedora 43 source packages

## Build Model

The workflow does not use COPR. It does this instead:

1. Reads package selections from the checked-in source manifest or from a manual dispatch input.
2. Clones each selected Fedora dist-git repository from `src.fedoraproject.org`.
3. Fetches source tarballs from Fedora lookaside using `fedpkg sources`.
4. Installs `BuildRequires` with `dnf builddep`.
5. Rebuilds the package with RPM macros overriding `%optflags` to:
   `-O3 -march=x86-64-v4`
6. Uploads the built `.rpm` and `.src.rpm` files as GitHub Actions artifacts.

## Using The Workflow

Run the `Build Fedora RPMs` workflow manually with `workflow_dispatch`.

You can:

- build a specific list of source packages
- provide binary package names and have them mapped to source packages
- build a chunk from the checked-in manifest by `batch_index` and `batch_size`

This is important because GitHub Actions matrix jobs are capped, and the full
Fedora 43 KDE source manifest contains 265 packages.

## Practical Notes

- The workflow is intended for on-demand rebuilds, not for one-click rebuilding of the full KDE stack in a single run.
- Some packages may still fail in GitHub Actions because Fedora package builds can rely on environment assumptions that are easier to satisfy in Koji or COPR than in a generic CI runner.
- If you want to rebuild the whole stack, dispatch the workflow in batches.
