# Fedora 43 KDE x86-64-v4 COPR Pipeline

This repository bootstraps a personal COPR project that rebuilds the Fedora 43
`KDE Plasma Workspaces` environment in `x86-64-v4`.

The package set is not hard-coded by hand. It is resolved from Fedora 43 comps
metadata using `dnf5`, starting from the `kde-desktop-environment` environment
and layering in the Fedora KDE kickstart additions that the spin uses:

- `firefox`
- `kde-apps`
- `kde-media`
- `kde-pim`
- `kde-spin-initial-setup`
- `libreoffice`

It also applies the Fedora KDE spin additions and removals encoded in
[config/kde_f43.json](/home/dawson/Dev/MIsc/KDE-x86_64-v4/config/kde_f43.json).

## What The Repo Does

- Resolves the Fedora 43 KDE binary package set and maps it to Fedora source packages.
- Builds a `custom-macros` RPM that overrides `%optflags` to use `-march=x86-64-v4`.
- Creates or reuses a personal COPR project on `copr.fedorainfracloud.org`.
- Adds `custom-macros` to the `fedora-43-x86_64` buildroot.
- Registers all source packages as Fedora dist-git package definitions pinned to branch `f43`.
- Queues a two-pass rebuild so later packages can consume project-local rebuilt libraries.

## Files

- Resolver: [scripts/resolve_kde_set.py](/home/dawson/Dev/MIsc/KDE-x86_64-v4/scripts/resolve_kde_set.py)
- COPR driver: [scripts/copr_kde_pipeline.py](/home/dawson/Dev/MIsc/KDE-x86_64-v4/scripts/copr_kde_pipeline.py)
- COPR macro RPM: [packaging/custom-macros/custom-macros.spec](/home/dawson/Dev/MIsc/KDE-x86_64-v4/packaging/custom-macros/custom-macros.spec)
- Package-set definition: [config/kde_f43.json](/home/dawson/Dev/MIsc/KDE-x86_64-v4/config/kde_f43.json)

## Prerequisites

- `copr-cli` installed and authenticated with your Fedora account.
- `dnf5` available locally.
- `rpmbuild` available locally.

Your COPR credentials should already work with:

```bash
copr-cli whoami
```

## Usage

First resolve the Fedora 43 KDE package set:

```bash
./scripts/resolve_kde_set.py
```

That writes:

- `manifests/fedora-43/manifest.json`
- `manifests/fedora-43/binary-packages.txt`
- `manifests/fedora-43/source-packages.txt`

Then create and queue the COPR pipeline:

```bash
./scripts/copr_kde_pipeline.py --project kde-x86_64-v4 --disable-createrepo
```

If you want to target a specific owner or group explicitly:

```bash
./scripts/copr_kde_pipeline.py --owner your_fas_name --project kde-x86_64-v4 --disable-createrepo
```

## Notes

- The resolver depends on Fedora 43 repository metadata being available through `dnf5`.
- The rebuild is intentionally queued in two passes. The first pass rebuilds the stack with the new flags. The second pass gives consumers a chance to rebuild against project-local `x86-64-v4` libraries.
- This is a practical COPR pipeline, not a full Fedora mass-rebuild dependency solver. If you want tighter dependency staging, reduce `--batch-size` or split known base libraries into earlier batches.
- `--disable-createrepo` is recommended for large stacks because COPR keeps the internal development repository available to subsequent builds while avoiding expensive public metadata regeneration on every build.
