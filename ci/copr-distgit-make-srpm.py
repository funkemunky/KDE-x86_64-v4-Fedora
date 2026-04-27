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
import urllib.request
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_LINE_PATTERN = re.compile(
    r"^(?P<algo>[A-Za-z0-9_+-]+)\s+\((?P<filename>.+)\)\s+=\s+(?P<checksum>[0-9A-Fa-f]+)$"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Create an SRPM either from a local spec in this repository or by "
            "cloning a Fedora dist-git package and downloading its lookaside sources."
        )
    )
    parser.add_argument("--spec-ref", required=True, help="Local .spec path or Fedora dist-git package name")
    parser.add_argument("--outdir", required=True, help="Directory where the generated SRPM should be written")
    parser.add_argument("--branch", default="f43", help="Fedora dist-git branch to clone when spec-ref is a package")
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
            with urllib.request.urlopen(url) as response, destination.open("wb") as handle:
                shutil.copyfileobj(response, handle)
        except Exception:
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

    srpms = sorted(outdir.glob("*.src.rpm"), key=lambda path: path.stat().st_mtime, reverse=True)
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


def build_from_distgit(
    package_name: str,
    *,
    branch: str,
    dist: str,
    namespace: str,
    lookaside_baseurl: str,
    attempts: int,
    outdir: Path,
) -> Path:
    clone_url = f"https://src.fedoraproject.org/{namespace}/{package_name}.git"
    with tempfile.TemporaryDirectory(prefix=f"{package_name}-distgit-") as tempdir_name:
        tempdir = Path(tempdir_name)
        package_dir = tempdir / package_name
        for attempt in range(1, attempts + 1):
            try:
                if package_dir.exists():
                    shutil.rmtree(package_dir)
                run(
                    [
                        "git",
                        "clone",
                        "--depth",
                        "1",
                        "--branch",
                        branch,
                        clone_url,
                        str(package_dir),
                    ]
                )
                break
            except subprocess.CalledProcessError:
                if attempt == attempts:
                    raise
                time.sleep(attempt * 3)
        spec_files = sorted(package_dir.glob("*.spec"))
        if not spec_files:
            raise RuntimeError(f"no spec file found in {clone_url} branch {branch}")
        spec_path = spec_files[0]
        download_lookaside_sources(
            package_name,
            package_dir,
            namespace=namespace,
            lookaside_baseurl=lookaside_baseurl,
            attempts=attempts,
        )
        return build_srpm(spec_path, source_dir=package_dir, outdir=outdir, dist=dist)


def main() -> int:
    args = parse_args()
    outdir = Path(args.outdir).resolve()

    local_spec = ensure_within_repo(Path(args.spec_ref))
    if local_spec is not None:
        srpm = build_srpm(local_spec, source_dir=local_spec.parent, outdir=outdir, dist=args.dist)
        print(f"built local SRPM {srpm.name}")
        return 0

    srpm = build_from_distgit(
        args.spec_ref,
        branch=args.branch,
        dist=args.dist,
        namespace=args.namespace,
        lookaside_baseurl=args.lookaside_baseurl.rstrip("/"),
        attempts=args.retry_count,
        outdir=outdir,
    )
    print(f"built dist-git SRPM {srpm.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
