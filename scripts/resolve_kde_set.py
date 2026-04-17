#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from pathlib import Path


def run(cmd):
    result = subprocess.run(cmd, check=True, text=True, capture_output=True)
    return result.stdout


def dnf_base_args(releasever, repos):
    state_dir = Path(__file__).resolve().parent.parent / ".dnf"
    log_dir = state_dir / "log"
    cache_dir = state_dir / "cache"
    log_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)

    args = [
        "dnf5",
        "--disablerepo=*",
        f"--releasever={releasever}",
        f"--setopt=logdir={log_dir}",
        f"--setopt=cachedir={cache_dir}",
    ]
    for repo in repos:
        args.append(f"--enablerepo={repo}")
    return args


def parse_sectioned_names(output, section_names):
    collected = []
    current = None
    sections = set(section_names)
    for raw_line in output.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue
        matched = False
        for section in sections:
            prefix = f"{section:<21}:"
            if line.startswith(prefix) or line.startswith(f"{section}:"):
                current = section
                value = line.split(":", 1)[1].strip()
                if value:
                    collected.append(value)
                matched = True
                break
        if matched:
            continue
        if current and raw_line.startswith(" " * 21):
            value = raw_line.strip()
            if value.startswith(":"):
                value = value[1:].strip()
            if value:
                collected.append(value)
        else:
            current = None
    return collected


def unique_sorted(values):
    return sorted(set(values))


def resolve_group_packages(group_name, releasever, repos):
    cmd = dnf_base_args(releasever, repos) + [
        "group",
        "info",
        "--hidden",
        group_name,
    ]
    output = run(cmd)
    return unique_sorted(
        parse_sectioned_names(output, ["Mandatory packages", "Default packages"])
    )


def resolve_environment_groups(environment_name, releasever, repos):
    cmd = dnf_base_args(releasever, repos) + [
        "environment",
        "info",
        environment_name,
    ]
    output = run(cmd)
    return unique_sorted(parse_sectioned_names(output, ["Required groups"]))


def chunked(items, size):
    for index in range(0, len(items), size):
        yield items[index : index + size]


def resolve_source_packages(binary_packages, releasever, repos, arch):
    source_packages = set()
    for package_chunk in chunked(binary_packages, 150):
        cmd = dnf_base_args(releasever, repos) + [
            "repoquery",
            "--available",
            "--latest-limit=1",
            f"--arch={arch},noarch",
            "--srpm",
            "--qf",
            "%{name}\n",
        ] + package_chunk
        output = run(cmd)
        for line in output.splitlines():
            name = line.strip()
            if name:
                source_packages.add(name)
    return sorted(source_packages)


def write_lines(path, items):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(f"{item}\n" for item in items), encoding="ascii")


def main():
    parser = argparse.ArgumentParser(
        description="Resolve the Fedora KDE Plasma Workspaces package set into source packages."
    )
    parser.add_argument(
        "--config",
        default="config/kde_f43.json",
        help="Path to resolver configuration JSON.",
    )
    parser.add_argument(
        "--output-dir",
        default="manifests/fedora-43",
        help="Directory for generated manifest files.",
    )
    parser.add_argument(
        "--repo",
        action="append",
        default=["fedora", "updates"],
        help="DNF repo ID to use. Repeat for multiple repos.",
    )
    parser.add_argument(
        "--arch",
        default="x86_64",
        help="Primary binary package architecture to resolve.",
    )
    args = parser.parse_args()

    config_path = Path(args.config)
    config = json.loads(config_path.read_text(encoding="ascii"))
    releasever = config["releasever"]

    env_groups = resolve_environment_groups(config["environment"], releasever, args.repo)
    include_groups = unique_sorted(env_groups + config["extra_groups"])
    excluded_groups = unique_sorted(config["exclude_groups"])

    included_binary_packages = set(config["extra_packages"])
    for group_name in include_groups:
        included_binary_packages.update(
            resolve_group_packages(group_name, releasever, args.repo)
        )

    excluded_binary_packages = set(config["exclude_packages"])
    for group_name in excluded_groups:
        excluded_binary_packages.update(
            resolve_group_packages(group_name, releasever, args.repo)
        )

    final_binary_packages = sorted(included_binary_packages - excluded_binary_packages)
    source_packages = resolve_source_packages(
        final_binary_packages, releasever, args.repo, args.arch
    )

    output_dir = Path(args.output_dir)
    manifest = {
        "releasever": releasever,
        "environment": config["environment"],
        "include_groups": include_groups,
        "exclude_groups": excluded_groups,
        "explicit_packages": unique_sorted(config["extra_packages"]),
        "excluded_packages": unique_sorted(config["exclude_packages"]),
        "binary_package_count": len(final_binary_packages),
        "source_package_count": len(source_packages),
        "binary_packages": final_binary_packages,
        "source_packages": source_packages,
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="ascii"
    )
    write_lines(output_dir / "binary-packages.txt", final_binary_packages)
    write_lines(output_dir / "source-packages.txt", source_packages)

    print(
        f"Resolved {len(final_binary_packages)} binary packages "
        f"into {len(source_packages)} source packages."
    )
    print(f"Wrote manifest to {output_dir / 'manifest.json'}")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(exc.stdout)
        sys.stderr.write(exc.stderr)
        raise
