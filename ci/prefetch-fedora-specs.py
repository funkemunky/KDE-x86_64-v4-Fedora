#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import tempfile
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Prefetch Fedora dist-git packaging snapshots into SPECS/<package>/ "
            "so Copr can build packages individually from this repository."
        )
    )
    parser.add_argument("--packages-file", default="packages.txt", help="Package list to fetch")
    parser.add_argument(
        "--package-input",
        default="",
        help="Optional comma, space, or newline separated package list. Overrides --packages-file when set.",
    )
    parser.add_argument("--branch", default="f43", help="Fedora dist-git branch to clone")
    parser.add_argument("--namespace", default="rpms", help="Fedora dist-git namespace")
    parser.add_argument("--output-dir", default="SPECS", help="Destination directory")
    parser.add_argument("--retry-count", type=int, default=3)
    return parser.parse_args()


def run(command: list[str], *, cwd: Path | None = None, capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        check=True,
        text=True,
        capture_output=capture,
    )


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


def copy_tracked_files(source_dir: Path, destination_dir: Path) -> None:
    tracked = run(["git", "ls-files", "-z"], cwd=source_dir, capture=True).stdout
    destination_dir.mkdir(parents=True, exist_ok=True)
    for relative_name in tracked.split("\0"):
        if not relative_name:
            continue
        relative_path = Path(relative_name)
        source_path = source_dir / relative_path
        dest_path = destination_dir / relative_path
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, dest_path)


def fetch_package(package_name: str, *, branch: str, namespace: str, output_dir: Path, retry_count: int) -> None:
    clone_url = f"https://src.fedoraproject.org/{namespace}/{package_name}.git"
    with tempfile.TemporaryDirectory(prefix=f"{package_name}-distgit-") as tempdir_name:
        tempdir = Path(tempdir_name)
        checkout_dir = tempdir / package_name
        for attempt in range(1, retry_count + 1):
            try:
                run(
                    [
                        "git",
                        "clone",
                        "--depth",
                        "1",
                        "--branch",
                        branch,
                        clone_url,
                        str(checkout_dir),
                    ]
                )
                break
            except subprocess.CalledProcessError:
                if attempt == retry_count:
                    raise
                if checkout_dir.exists():
                    shutil.rmtree(checkout_dir)
                time.sleep(attempt * 3)

        destination_dir = output_dir / package_name
        if destination_dir.exists():
            shutil.rmtree(destination_dir)
        copy_tracked_files(checkout_dir, destination_dir)

        spec_files = sorted(destination_dir.glob("*.spec"))
        if not spec_files:
            raise RuntimeError(f"no spec file found for {package_name}")
        if len(spec_files) > 1:
            raise RuntimeError(
                f"multiple spec files found for {package_name}: "
                + ", ".join(path.name for path in spec_files)
            )


def main() -> int:
    args = parse_args()
    packages = load_packages(Path(args.packages_file), args.package_input)
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    for package_name in packages:
        fetch_package(
            package_name,
            branch=args.branch,
            namespace=args.namespace,
            output_dir=output_dir,
            retry_count=args.retry_count,
        )
        print(f"prefetched {package_name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
