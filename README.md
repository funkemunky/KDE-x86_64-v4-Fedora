# Fedora 43 KDE Actions RPM Builder

This repository provides CI workflows for both GitHub Actions and Gitea Actions to rebuild Fedora 43
KDE packages from Fedora dist-git with `x86-64-v3` and `x86-64-v4` code generation and `-O3`
optimization.

## Workflows
- **GitHub Actions**: `.github/workflows/build-v3-rpms.yml`
- **Gitea Actions**: `.gitea/workflows/build-v3-rpms.yml`

Each build workflow now finishes with a repository assembly job that collects the shard artifacts,
generates `repodata/` with `createrepo_c`, and uploads a ready-to-serve DNF repository artifact.

## Repository artifacts
- **GitHub Actions** uploads `dnf-repo-x86-64-v3`
- **Gitea Actions** uploads `dnf-repo-x86-64-v3` and `dnf-repo-x86-64-v4`

Each repository artifact contains:
- `packages/` with the built binary RPMs
- `repodata/` generated for DNF
- a `.repo` template with a placeholder `baseurl`
- `README.txt` with Fedora 43 install instructions
