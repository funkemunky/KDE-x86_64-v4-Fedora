#!/usr/bin/env python3

import argparse
import shutil
import subprocess
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Assemble built RPM artifacts into a DNF repository."
    )
    parser.add_argument("--input-dir", required=True, help="Directory containing built RPM artifacts")
    parser.add_argument("--output-dir", required=True, help="Directory where the repo should be created")
    parser.add_argument("--repo-id", required=True, help="DNF repository ID to embed in the template")
    parser.add_argument("--repo-name", required=True, help="Human-readable repository name")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_dir = Path(args.input_dir).resolve()
    output_dir = Path(args.output_dir).resolve()
    packages_dir = output_dir / "packages"

    if not input_dir.exists():
        raise SystemExit(f"input directory does not exist: {input_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)
    packages_dir.mkdir(parents=True, exist_ok=True)

    rpm_paths = sorted(
        path
        for path in input_dir.rglob("*.rpm")
        if not path.name.endswith(".src.rpm")
    )

    if not rpm_paths:
        raise SystemExit(f"no binary RPMs found under {input_dir}")

    copied = 0
    for rpm_path in rpm_paths:
        destination = packages_dir / rpm_path.name
        if destination.exists():
            if rpm_path.stat().st_size != destination.stat().st_size:
                raise SystemExit(f"conflicting RPM filename encountered: {rpm_path.name}")
            continue
        shutil.copy2(rpm_path, destination)
        copied += 1

    subprocess.run(
        ["createrepo_c", "--database", str(output_dir)],
        check=True,
    )

    repo_file = output_dir / f"{args.repo_id}.repo"
    repo_file.write_text(
        "\n".join(
            [
                f"[{args.repo_id}]",
                f"name={args.repo_name}",
                "baseurl=REPLACE_WITH_REPO_URL",
                "enabled=1",
                "gpgcheck=0",
                "repo_gpgcheck=0",
                "",
            ]
        ),
        encoding="utf-8",
    )

    readme_file = output_dir / "README.txt"
    readme_file.write_text(
        "\n".join(
            [
                args.repo_name,
                "",
                f"Binary RPMs copied: {copied}",
                "",
                "Usage:",
                "1. Publish this directory over HTTP(S) or copy it to a local path on Fedora 43.",
                f"2. Edit {repo_file.name} and replace REPLACE_WITH_REPO_URL with the repo root URL.",
                "   Example HTTP URL: http://your-server/path/to/repo",
                "   Example local URL: file:///srv/repos/your-repo",
                "3. Install the repo file on the target machine:",
                f"   sudo install -Dm0644 {repo_file.name} /etc/yum.repos.d/{repo_file.name}",
                "4. Refresh metadata and install packages:",
                "   sudo dnf clean all",
                "   sudo dnf makecache",
                "   sudo dnf install <package-name>",
                "",
            ]
        ),
        encoding="utf-8",
    )

    print(f"assembled {copied} RPMs into {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
