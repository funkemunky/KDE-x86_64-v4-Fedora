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
    parser.add_argument("--specs-dir", default="SPECS", help="Directory containing repo-local package snapshots")
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
    parser.add_argument(
        "--copr-debug",
        action="store_true",
        help="Run copr-cli commands with --debug and include full output on failures.",
    )
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


def run_copr(args: argparse.Namespace, command: list[str]) -> subprocess.CompletedProcess[str]:
    copr_command = command[:]
    if args.copr_debug and len(copr_command) >= 1 and copr_command[0] == "copr":
        copr_command.insert(1, "--debug")

    try:
        return subprocess.run(
            copr_command,
            check=True,
            text=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as exc:
        stdout = (exc.stdout or "").strip()
        stderr = (exc.stderr or "").strip()
        details = []
        if stdout:
            details.append(f"stdout:\n{stdout}")
        if stderr:
            details.append(f"stderr:\n{stderr}")
        output_block = "\n\n".join(details) if details else "(no output captured)"
        raise RuntimeError(
            "Copr command failed:\n"
            f"{' '.join(copr_command)}\n\n"
            f"{output_block}\n\n"
            "If this includes 'Response is not in JSON format', the server likely "
            "returned an HTML error page (auth issue, wrong project path/casing, or "
            "temporary Copr outage). Re-run with --copr-debug for request details."
        ) from exc


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


def resolve_spec_ref(package_name: str, specs_dir: Path) -> str:
    package_dir = specs_dir / package_name
    package_named_spec = package_dir / f"{package_name}.spec"
    if package_named_spec.is_file():
        return package_named_spec.as_posix()

    spec_files = sorted(package_dir.glob("*.spec"))
    if len(spec_files) == 1:
        return spec_files[0].as_posix()
    if len(spec_files) > 1:
        raise RuntimeError(
            f"multiple spec files found for {package_name} under {package_dir}; "
            "set an explicit spec path instead"
        )
    raise RuntimeError(f"no spec file found for {package_name} under {package_dir}")


def upsert_scm_package(
    *,
    args: argparse.Namespace,
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
        "--method",
        "make_srpm",
        "--spec",
        spec_ref,
    ]
    if commit != "HEAD":
        command.extend(["--commit", commit])
    if webhook_rebuild != "off":
        command.extend(["--webhook-rebuild", webhook_rebuild])
    if max_builds != 0:
        command.extend(["--max-builds", str(max_builds)])
    if timeout != 18000:
        command.extend(["--timeout", str(timeout)])
    run_copr(args, command)


def submit_build(args: argparse.Namespace, project: str, package_name: str, chroot: str, *, nowait: bool) -> None:
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
    run_copr(args, command)


def main() -> int:
    args = parse_args()
    packages = load_packages(Path(args.packages_file), args.package_input)
    specs_dir = Path(args.specs_dir)

    # Preflight to fail fast on auth/project typos before batch operations.
    run_copr(args, ["copr", "get", args.project])

    upsert_scm_package(
        args=args,
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
            args=args,
            project=args.project,
            package_name=package_name,
            spec_ref=resolve_spec_ref(package_name, specs_dir),
            clone_url=args.clone_url,
            commit=args.commit,
            webhook_rebuild=args.webhook_rebuild,
            max_builds=args.max_builds,
            timeout=args.timeout,
        )

    if not args.skip_chroot_update:
        run_copr(
            args,
            [
                "copr",
                "edit-chroot",
                f"{args.project}/{args.chroot}",
                "--packages",
                args.macro_package_name,
            ]
        )

    if args.submit_macro_build:
        submit_build(args, args.project, args.macro_package_name, args.chroot, nowait=False)

    if args.submit_package_builds:
        for package_name in packages:
            submit_build(
                args,
                args.project,
                package_name,
                args.chroot,
                nowait=args.nowait_package_builds,
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
