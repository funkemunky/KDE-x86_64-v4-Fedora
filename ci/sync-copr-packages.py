#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Register or update Copr SCM package definitions that use this "
            "repository's .copr/Makefile and optionally submit builds."
        )
    )
    parser.add_argument("--project", required=True, help="Copr project, e.g. user/project")
    parser.add_argument("--clone-url", required=True, help="Git clone URL Copr should use for this repository")
    parser.add_argument("--commit", default="HEAD", help="Git ref Copr should build from")
    parser.add_argument("--chroot", default="fedora-43-x86_64", help="Copr chroot to configure and build for")
    parser.add_argument("--packages-file", default="packages.txt", help="Package list to register")
    parser.add_argument(
        "--package-input",
        default="",
        help="Optional comma, space, or newline separated package list. Overrides --packages-file when set.",
    )
    parser.add_argument(
        "--macro-package-name",
        default="copr-rpm-macros-x86-64-v3",
        help="Name of the buildroot macro package in Copr",
    )
    parser.add_argument(
        "--macro-package-spec",
        default="packaging/copr-rpm-macros-x86-64-v3.spec",
        help="Local spec reference for the buildroot macro package",
    )
    parser.add_argument("--webhook-rebuild", choices=("on", "off"), default="off")
    parser.add_argument("--max-builds", type=int, default=0)
    parser.add_argument("--timeout", type=int, default=18000)
    parser.add_argument("--skip-chroot-update", action="store_true")
    parser.add_argument("--submit-macro-build", action="store_true")
    parser.add_argument("--submit-package-builds", action="store_true")
    parser.add_argument("--nowait-package-builds", action="store_true")
    return parser.parse_args()


def run(command: list[str], *, quiet: bool = False) -> subprocess.CompletedProcess[str]:
    kwargs: dict[str, object] = {
        "check": True,
        "text": True,
    }
    if quiet:
        kwargs["stdout"] = subprocess.DEVNULL
        kwargs["stderr"] = subprocess.DEVNULL
    return subprocess.run(command, **kwargs)


def package_exists(project: str, package_name: str) -> bool:
    result = subprocess.run(
        ["copr", "get-package", project, "--name", package_name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    return result.returncode == 0


def load_packages(packages_file: Path, package_input: str) -> list[str]:
    if package_input.strip():
        packages = [entry for entry in re.split(r"[\s,]+", package_input.strip()) if entry]
    else:
        packages = [
            line.strip()
            for line in packages_file.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
    deduped: list[str] = []
    seen: set[str] = set()
    for package in packages:
        if package not in seen:
            deduped.append(package)
            seen.add(package)
    return deduped


def upsert_scm_package(
    *,
    project: str,
    package_name: str,
    spec_ref: str,
    clone_url: str,
    commit: str,
    webhook_rebuild: str,
    max_builds: int,
    timeout: int,
) -> None:
    action = "edit-package-scm" if package_exists(project, package_name) else "add-package-scm"
    command = [
        "copr",
        action,
        project,
        "--name",
        package_name,
        "--clone-url",
        clone_url,
        "--commit",
        commit,
        "--method",
        "make_srpm",
        "--spec",
        spec_ref,
        "--webhook-rebuild",
        webhook_rebuild,
        "--max-builds",
        str(max_builds),
        "--timeout",
        str(timeout),
    ]
    run(command)


def submit_build(project: str, package_name: str, chroot: str, *, nowait: bool) -> None:
    command = [
        "copr",
        "build-package",
        project,
        "--name",
        package_name,
        "--chroot",
        chroot,
    ]
    if nowait:
        command.append("--nowait")
    run(command)


def main() -> int:
    args = parse_args()
    packages = load_packages(Path(args.packages_file), args.package_input)

    upsert_scm_package(
        project=args.project,
        package_name=args.macro_package_name,
        spec_ref=args.macro_package_spec,
        clone_url=args.clone_url,
        commit=args.commit,
        webhook_rebuild=args.webhook_rebuild,
        max_builds=args.max_builds,
        timeout=args.timeout,
    )

    for package_name in packages:
        upsert_scm_package(
            project=args.project,
            package_name=package_name,
            spec_ref=package_name,
            clone_url=args.clone_url,
            commit=args.commit,
            webhook_rebuild=args.webhook_rebuild,
            max_builds=args.max_builds,
            timeout=args.timeout,
        )

    if not args.skip_chroot_update:
        run(
            [
                "copr",
                "edit-chroot",
                f"{args.project}/{args.chroot}",
                "--packages",
                args.macro_package_name,
            ]
        )

    if args.submit_macro_build:
        submit_build(args.project, args.macro_package_name, args.chroot, nowait=False)

    if args.submit_package_builds:
        for package_name in packages:
            submit_build(
                args.project,
                package_name,
                args.chroot,
                nowait=args.nowait_package_builds,
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
