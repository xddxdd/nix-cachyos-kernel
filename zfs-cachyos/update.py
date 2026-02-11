#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p python3Packages.requests -p nix-prefetch-git

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any, Optional

import requests


def get_latest_zfs_cachyos_branch() -> Optional[str]:
    api_url = "https://api.github.com/repos/CachyOS/zfs/branches"
    all_branches = []
    page = 1
    per_page = 100  # Maximum allowed

    # Setup headers for GitHub API authentication if token is available
    headers = {}
    github_token = os.environ.get("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"token {github_token}"

    while True:
        params = {"per_page": per_page, "page": page}
        response = requests.get(api_url, params=params, headers=headers, timeout=30)
        response.raise_for_status()

        branches = response.json()
        if not branches:
            break

        all_branches.extend(branches)
        page += 1

        # If we got less than per_page results, we're on the last page
        if len(branches) < per_page:
            break

    cachyos_branches = []

    branch_pattern = re.compile(r"^zfs-\d+\.\d+\.\d+-cachyos$")

    for branch in all_branches:
        branch_name = branch.get("name", "")
        if branch_pattern.match(branch_name):
            cachyos_branches.append(branch_name)

    if not cachyos_branches:
        print("No branch found matching zfs-x.y.z-cachyos or x.y.z-cachyos pattern")
        return None

    cachyos_branches.sort(reverse=True)
    latest_branch = cachyos_branches[0]
    print(f"Found latest branch: {latest_branch}")
    return latest_branch


def run_nix_prefetch_git(branch: str) -> Optional[Dict[str, Any]]:
    cmd = ["nix-prefetch-git", "https://github.com/CachyOS/zfs.git", "--rev", f"refs/heads/{branch}"]

    print(f"Running command: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

    if result.returncode != 0:
        print(f"nix-prefetch-git command failed with return code: {result.returncode}")
        print(f"Error output: {result.stderr}")
        return None

    output = result.stdout.strip()
    if not output:
        print("nix-prefetch-git output is empty")
        return None

    parsed_output = json.loads(output)
    return parsed_output


def save_version_info(branch: str, prefetch_data: Dict[str, Any], output_file: Path):
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump({"zfs_branch": branch, **prefetch_data}, f, indent=2)

    print(f"Version info saved to: {output_file}")


def main() -> int:
    print("Starting ZFS CachyOS version update...")

    latest_branch = get_latest_zfs_cachyos_branch()
    if not latest_branch:
        print("Failed to get latest branch, exiting")
        return 1

    prefetch_data = run_nix_prefetch_git(latest_branch)
    if not prefetch_data:
        print("nix-prefetch-git execution failed, exiting")
        return 1

    current = Path.cwd()
    while not (current / "flake.lock").exists():
        if current == current.parent:
            print("Could not find flake.lock in any parent directory, exiting")
            return 1
        current = current.parent

    output_file = current / "zfs-cachyos" / "version.json"

    save_version_info(latest_branch, prefetch_data, output_file)

    print("ZFS CachyOS version info update completed!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
