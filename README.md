# Fedora 43 KDE Actions RPM Builder

This repository provides CI workflows for both GitHub Actions and Gitea Actions to rebuild Fedora 43
KDE packages from Fedora dist-git with `x86-64-v3` and `x86-64-v4` code generation and `-O3`
optimization.

## Workflows
- **GitHub Actions**: `.github/workflows/build-v3-rpms.yml`
- **Gitea Actions**: `.gitea/workflows/build-v3-rpms.yml`