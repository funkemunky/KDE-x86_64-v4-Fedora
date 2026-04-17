#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST_DIR = REPO_ROOT / "manifests" / "fedora-43"
DEFAULT_MANIFEST_FILE = DEFAULT_MANIFEST_DIR / "manifest.json"
DEFAULT_SPEC_FILE = REPO_ROOT / "packaging" / "custom-macros" / "custom-macros.spec"


def run(cmd, check=True, capture_output=True):
    return subprocess.run(cmd, text=True, check=check, capture_output=capture_output)


def project_ref(owner, project):
    return f"{owner}/{project}" if owner else project


def ensure_manifest(manifest_path):
    if manifest_path.exists():
        return
    resolver = REPO_ROOT / "scripts" / "resolve_kde_set.py"
    cmd = [str(resolver), "--output-dir", str(manifest_path.parent)]
    subprocess.run(cmd, check=True)


def load_manifest(manifest_path):
    ensure_manifest(manifest_path)
    return json.loads(manifest_path.read_text(encoding="ascii"))


def create_project_if_missing(owner, project, chroot, disable_createrepo):
    ref = project_ref(owner, project)
    existing = run(["copr-cli", "get", ref], check=False)
    if existing.returncode == 0:
        return False

    description = (
        "Fedora 43 KDE Plasma Workspaces rebuild with x86-64-v4 optimization."
    )
    instructions = (
        "Personal COPR that rebuilds the Fedora 43 KDE Plasma Workspaces package "
        "set from Fedora dist-git using a custom buildroot macro package that "
        "switches optflags to -march=x86-64-v4."
    )
    cmd = [
        "copr-cli",
        "create",
        ref,
        "--chroot",
        chroot,
        "--description",
        description,
        "--instructions",
        instructions,
        "--appstream",
        "off",
        "--bootstrap",
        "on",
    ]
    if disable_createrepo:
        cmd.extend(["--disable_createrepo", "true"])
    subprocess.run(cmd, check=True)
    return True


def build_custom_macros_srpm(spec_file):
    topdir = REPO_ROOT / ".rpmbuild"
    for dirname in ["BUILD", "BUILDROOT", "RPMS", "SOURCES", "SPECS", "SRPMS"]:
        (topdir / dirname).mkdir(parents=True, exist_ok=True)

    cmd = [
        "rpmbuild",
        "-bs",
        str(spec_file),
        "--define",
        f"_topdir {topdir}",
        "--define",
        f"_sourcedir {spec_file.parent}",
        "--define",
        f"_srcrpmdir {topdir / 'SRPMS'}",
    ]
    subprocess.run(cmd, check=True)
    srpms = sorted((topdir / "SRPMS").glob("custom-macros-*.src.rpm"))
    if not srpms:
        raise RuntimeError("rpmbuild did not produce a custom-macros SRPM")
    return srpms[-1]


def parse_build_id(text):
    match = re.search(r"Created builds?:\s*([0-9]+)", text)
    if not match:
        raise RuntimeError(f"Could not parse build ID from output:\n{text}")
    return int(match.group(1))


def submit_build(cmd):
    completed = run(cmd)
    output = completed.stdout + completed.stderr
    return parse_build_id(output)


def attach_buildroot_package(owner, project, chroot, package_name):
    ref = project_ref(owner, project)
    subprocess.run(
        [
            "copr-cli",
            "edit-chroot",
            f"{ref}/{chroot}",
            "--packages",
            package_name,
        ],
        check=True,
    )


def register_distgit_packages(owner, project, branch, packages):
    ref = project_ref(owner, project)
    listed = run(["copr-cli", "list-package-names", ref], check=False)
    existing = set()
    if listed.returncode == 0:
        existing = {line.strip() for line in listed.stdout.splitlines() if line.strip()}

    added = 0
    for package_name in packages:
        if package_name in existing:
            continue
        subprocess.run(
            [
                "copr-cli",
                "add-package-distgit",
                ref,
                "--name",
                package_name,
                "--commit",
                branch,
            ],
            check=True,
        )
        added += 1
    return added


def chunked(items, size):
    for index in range(0, len(items), size):
        yield items[index : index + size]


def queue_build_batch(owner, project, chroot, packages, anchor_build_id=None):
    ref = project_ref(owner, project)
    batch_anchor = None
    for index, package_name in enumerate(packages):
        cmd = [
            "copr-cli",
            "build-package",
            ref,
            "--name",
            package_name,
            "--background",
            "--nowait",
            "-r",
            chroot,
        ]
        if index == 0 and anchor_build_id is not None:
            cmd.extend(["--after-build-id", str(anchor_build_id)])
        elif index > 0 and batch_anchor is not None:
            cmd.extend(["--with-build-id", str(batch_anchor)])
        build_id = submit_build(cmd)
        if batch_anchor is None:
            batch_anchor = build_id
    return batch_anchor


def queue_mass_rebuild(owner, project, chroot, packages, passes, batch_size):
    previous_anchor = None
    for _ in range(passes):
        for package_batch in chunked(packages, batch_size):
            previous_anchor = queue_build_batch(
                owner,
                project,
                chroot,
                package_batch,
                anchor_build_id=previous_anchor,
            )
    return previous_anchor


def run_all(args):
    manifest = load_manifest(args.manifest)
    sources = manifest["source_packages"]

    created = create_project_if_missing(
        args.owner,
        args.project,
        args.chroot,
        args.disable_createrepo,
    )
    if created:
        print(f"Created project {project_ref(args.owner, args.project)}")
    else:
        print(f"Using existing project {project_ref(args.owner, args.project)}")

    srpm_path = build_custom_macros_srpm(args.spec_file)
    custom_build_id = submit_build(
        [
            "copr-cli",
            "build",
            project_ref(args.owner, args.project),
            str(srpm_path),
            "--nowait",
            "-r",
            args.chroot,
        ]
    )
    print(f"Queued custom-macros build {custom_build_id}")

    attach_buildroot_package(args.owner, args.project, args.chroot, "custom-macros")
    print(f"Attached custom-macros to {args.chroot}")

    added = register_distgit_packages(args.owner, args.project, args.branch, sources)
    print(f"Registered {added} dist-git packages")

    final_anchor = queue_mass_rebuild(
        args.owner,
        args.project,
        args.chroot,
        sources,
        args.passes,
        args.batch_size,
    )
    print(f"Queued rebuild batches through anchor build {final_anchor}")


def main():
    parser = argparse.ArgumentParser(
        description="Bootstrap a Fedora 43 KDE x86-64-v4 COPR pipeline."
    )
    parser.add_argument("--project", required=True, help="Bare COPR project name.")
    parser.add_argument(
        "--owner",
        help="Optional COPR owner prefix. Leave unset for your personal account.",
    )
    parser.add_argument(
        "--chroot",
        default="fedora-43-x86_64",
        help="Target COPR chroot.",
    )
    parser.add_argument(
        "--branch",
        default="f43",
        help="Fedora dist-git branch to build.",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST_FILE,
        help="Manifest JSON generated by resolve_kde_set.py.",
    )
    parser.add_argument(
        "--spec-file",
        type=Path,
        default=DEFAULT_SPEC_FILE,
        help="Path to the custom-macros spec file.",
    )
    parser.add_argument(
        "--passes",
        type=int,
        default=2,
        help="How many full rebuild passes to queue.",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=40,
        help="How many package builds to place in each sequential batch.",
    )
    parser.add_argument(
        "--disable-createrepo",
        action="store_true",
        help="Disable automatic repository publication for the project.",
    )
    args = parser.parse_args()
    run_all(args)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        if exc.stdout:
            sys.stderr.write(exc.stdout)
        if exc.stderr:
            sys.stderr.write(exc.stderr)
        raise
