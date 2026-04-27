#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
import tempfile
import time
import urllib.parse
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_LINE_PATTERN = re.compile(
    r"^(?P<algo>[A-Za-z0-9_+-]+)\s+\((?P<filename>.+)\)\s+=\s+(?P<checksum>[0-9A-Fa-f]+)$"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Create an SRPM from a repo-local spec path or from a package snapshot "
            "under SPECS/<package>/, downloading Fedora lookaside sources as needed."
        )
    )
    parser.add_argument("--spec-ref", required=True, help="Local .spec path or package name under SPECS/")
    parser.add_argument("--outdir", required=True, help="Directory where the generated SRPM should be written")
    parser.add_argument(
        "--specs-dir",
        default="SPECS",
        help="Directory containing repo-local Fedora packaging snapshots",
    )
    parser.add_argument("--dist", default=".fc43", help="RPM dist suffix to define while generating the SRPM")
    parser.add_argument("--namespace", default="rpms", help="Fedora dist-git namespace")
    parser.add_argument(
        "--lookaside-baseurl",
        default="https://src.fedoraproject.org/repo/pkgs",
        help="Base URL for the Fedora lookaside cache",
    )
    parser.add_argument("--retry-count", type=int, default=3, help="Number of retries for network operations")
    return parser.parse_args()


def run(command: list[str], *, cwd: Path | None = None) -> None:
    subprocess.run(command, cwd=cwd, check=True)


def ensure_within_repo(path: Path) -> Path | None:
    candidate = (REPO_ROOT / path).resolve()
    try:
        candidate.relative_to(REPO_ROOT)
    except ValueError:
        return None
    if candidate.is_file() and candidate.suffix == ".spec":
        return candidate
    return None


def resolve_package_spec(package_name: str, specs_dir: Path) -> Path | None:
    package_dir = (REPO_ROOT / specs_dir / package_name).resolve()
    try:
        package_dir.relative_to(REPO_ROOT)
    except ValueError:
        return None
    if not package_dir.is_dir():
        return None

    package_named_spec = package_dir / f"{package_name}.spec"
    if package_named_spec.is_file():
        return package_named_spec

    spec_files = sorted(package_dir.glob("*.spec"))
    if len(spec_files) == 1:
        return spec_files[0]
    if len(spec_files) > 1:
        raise RuntimeError(
            f"multiple spec files found for {package_name} under {package_dir}; "
            "use an explicit spec path"
        )
    return None


def package_name_for_specs_path(spec_path: Path, specs_dir: Path) -> str | None:
    specs_root = (REPO_ROOT / specs_dir).resolve()
    try:
        relative = spec_path.resolve().relative_to(specs_root)
    except ValueError:
        return None
    if len(relative.parts) < 2:
        return None
    return relative.parts[0]


def hash_file(path: Path, algorithm: str) -> str:
    digest = hashlib.new(algorithm.lower())
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_file(url: str, destination: Path, *, algorithm: str, checksum: str, attempts: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(1, attempts + 1):
        if destination.exists() and hash_file(destination, algorithm) == checksum.lower():
            return

        try:
            subprocess.run(
                [
                    "curl",
                    "--fail",
                    "--location",
                    "--silent",
                    "--show-error",
                    "--output",
                    str(destination),
                    url,
                ],
                check=True,
            )
        except subprocess.CalledProcessError:
            if destination.exists():
                destination.unlink()
            if attempt == attempts:
                raise
            time.sleep(attempt * 3)
            continue

        if hash_file(destination, algorithm) == checksum.lower():
            return

        destination.unlink(missing_ok=True)
        if attempt == attempts:
            raise RuntimeError(f"checksum mismatch for {destination.name} from {url}")
        time.sleep(attempt * 3)


def build_srpm(spec_path: Path, *, source_dir: Path, outdir: Path, dist: str) -> Path:
    outdir.mkdir(parents=True, exist_ok=True)
    existing = {path.resolve() for path in outdir.glob("*.src.rpm")}
    with tempfile.TemporaryDirectory(prefix="copr-srpm-topdir-") as topdir_name:
        topdir = Path(topdir_name)
        command = [
            "rpmbuild",
            "-bs",
            str(spec_path),
            "--define",
            f"_topdir {topdir}",
            "--define",
            f"_builddir {topdir / 'BUILD'}",
            "--define",
            f"_buildrootdir {topdir / 'BUILDROOT'}",
            "--define",
            f"_rpmdir {topdir / 'RPMS'}",
            "--define",
            f"_srcrpmdir {outdir}",
            "--define",
            f"_sourcedir {source_dir}",
            "--define",
            f"_specdir {spec_path.parent}",
        ]
        if dist:
            command.extend(["--define", f"dist {dist}"])
        run(command, cwd=source_dir)

    srpms = sorted(
        (path for path in outdir.glob("*.src.rpm") if path.resolve() not in existing),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    if not srpms:
        raise RuntimeError(f"rpmbuild did not produce an SRPM in {outdir}")
    return srpms[0]


def parse_sources_file(path: Path) -> list[tuple[str, str, str]]:
    entries: list[tuple[str, str, str]] = []
    if not path.exists():
        return entries

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        match = SOURCE_LINE_PATTERN.match(line)
        if not match:
            raise RuntimeError(f"unsupported lookaside source format: {line}")
        entries.append(
            (
                match.group("algo").lower(),
                match.group("filename"),
                match.group("checksum").lower(),
            )
        )
    return entries


def download_lookaside_sources(
    package_name: str,
    source_dir: Path,
    *,
    namespace: str,
    lookaside_baseurl: str,
    attempts: int,
) -> None:
    for algorithm, filename, checksum in parse_sources_file(source_dir / "sources"):
        encoded_filename = urllib.parse.quote(filename)
        url = (
            f"{lookaside_baseurl}/{namespace}/{package_name}/"
            f"{encoded_filename}/{algorithm}/{checksum}/{encoded_filename}"
        )
        download_file(
            url,
            source_dir / filename,
            algorithm=algorithm,
            checksum=checksum,
            attempts=attempts,
        )


def ensure_lookaside_sources_present(package_name: str, source_dir: Path) -> None:
    missing = [
        filename
        for _, filename, _ in parse_sources_file(source_dir / "sources")
        if not (source_dir / filename).is_file()
    ]
    if missing:
        missing_list = ", ".join(missing)
        raise RuntimeError(
            f"lookaside sources missing for {package_name}: {missing_list}. "
            "The Fedora lookaside download step did not leave the expected files in place."
        )


def main() -> int:
    args = parse_args()
    outdir = Path(args.outdir).resolve()
    specs_dir = Path(args.specs_dir)

    local_spec = ensure_within_repo(Path(args.spec_ref))
    if local_spec is not None:
        package_name = package_name_for_specs_path(local_spec, specs_dir)
        if package_name is not None:
            download_lookaside_sources(
                package_name,
                local_spec.parent,
                namespace=args.namespace,
                lookaside_baseurl=args.lookaside_baseurl.rstrip("/"),
                attempts=args.retry_count,
            )
            ensure_lookaside_sources_present(package_name, local_spec.parent)
        srpm = build_srpm(local_spec, source_dir=local_spec.parent, outdir=outdir, dist=args.dist)
        print(f"built local SRPM {srpm.name}")
        return 0

    package_spec = resolve_package_spec(args.spec_ref, specs_dir)
    if package_spec is None:
        raise RuntimeError(
            f"spec reference {args.spec_ref!r} is not a repo-local spec path and no "
            f"snapshot was found under {(REPO_ROOT / specs_dir / args.spec_ref)!s}"
        )

    package_dir = package_spec.parent
    download_lookaside_sources(
        args.spec_ref,
        package_dir,
        namespace=args.namespace,
        lookaside_baseurl=args.lookaside_baseurl.rstrip("/"),
        attempts=args.retry_count,
    )
    ensure_lookaside_sources_present(args.spec_ref, package_dir)
    srpm = build_srpm(package_spec, source_dir=package_dir, outdir=outdir, dist=args.dist)
    print(f"built package SRPM {srpm.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
