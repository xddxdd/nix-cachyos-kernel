#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p python3Packages.requests -p nix

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Optional

import requests

GITHUB_API = "https://api.github.com/repos/CachyOS/linux/releases"

# Pattern: cachyos-{version}-{tagrel}
# Stable: cachyos-6.19.5-2
# RC:     cachyos-7.0-rc1-2
TAG_PATTERN = re.compile(
    r"^cachyos-(?P<version>\d+\.\d+(?:\.\d+)?(?:-rc\d+)?)-(?P<tagrel>\d+)$"
)

# For sorting: extract (major, minor, patch) from version string
VERSION_PATTERN = re.compile(
    r"^(?P<major>\d+)\.(?P<minor>\d+)(?:\.(?P<patch>\d+))?(?:-rc(?P<rc>\d+))?$"
)


def parse_version_tuple(version: str) -> tuple:
    m = VERSION_PATTERN.match(version)
    if not m:
        return (0, 0, 0, 0)
    major = int(m.group("major"))
    minor = int(m.group("minor"))
    patch = int(m.group("patch") or "0")
    # RC versions sort before stable (rc=0 means stable, higher is better)
    rc = int(m.group("rc") or "0")
    # Stable versions (rc=0) should sort higher than any RC
    rc_sort = (1, 0) if rc == 0 else (0, rc)
    return (major, minor, patch, *rc_sort)


def is_rc(version: str) -> bool:
    return "-rc" in version


def major_minor(version: str) -> str:
    m = VERSION_PATTERN.match(version)
    if not m:
        return version
    return f"{m.group('major')}.{m.group('minor')}"


def fetch_releases() -> list[dict[str, Any]]:
    headers = {}
    github_token = os.environ.get("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"token {github_token}"

    all_releases = []
    page = 1
    per_page = 100

    while True:
        params = {"per_page": per_page, "page": page}
        response = requests.get(GITHUB_API, params=params, headers=headers, timeout=30)
        response.raise_for_status()

        releases = response.json()
        if not releases:
            break

        all_releases.extend(releases)
        page += 1

        if len(releases) < per_page:
            break

    return all_releases


def parse_releases(releases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    parsed = []
    for release in releases:
        tag = release.get("tag_name", "")
        m = TAG_PATTERN.match(tag)
        if not m:
            continue
        parsed.append({
            "tag": tag,
            "version": m.group("version"),
            "tagrel": int(m.group("tagrel")),
        })
    return parsed


def pick_latest_per_track(parsed: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    # Separate RC from stable releases
    rc_releases = [r for r in parsed if is_rc(r["version"])]
    stable_releases = [r for r in parsed if not is_rc(r["version"])]

    # Group stable releases by major.minor series
    series: dict[str, list[dict[str, Any]]] = {}
    for r in stable_releases:
        mm = major_minor(r["version"])
        series.setdefault(mm, []).append(r)

    # Sort each series by (version_tuple, tagrel) descending, pick the best
    def sort_key(r: dict[str, Any]) -> tuple:
        return (*parse_version_tuple(r["version"]), r["tagrel"])

    best_per_series = {}
    for mm, releases in series.items():
        releases.sort(key=sort_key, reverse=True)
        best_per_series[mm] = releases[0]

    # Sort series by version to determine latest vs LTS
    sorted_series = sorted(
        best_per_series.keys(),
        key=lambda mm: parse_version_tuple(best_per_series[mm]["version"]),
        reverse=True,
    )

    result = {}

    if len(sorted_series) >= 1:
        result["latest"] = best_per_series[sorted_series[0]]
    if len(sorted_series) >= 2:
        result["lts"] = best_per_series[sorted_series[1]]

    # Pick best RC release
    if rc_releases:
        rc_releases.sort(key=sort_key, reverse=True)
        result["rc"] = rc_releases[0]

    return result


def nix_prefetch_url(url: str) -> Optional[str]:
    print(f"  Prefetching {url}...")
    cmd = ["nix-prefetch-url", "--type", "sha256", url]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if result.returncode != 0:
        print(f"  nix-prefetch-url failed: {result.stderr}")
        return None
    nix32_hash = result.stdout.strip()

    # Convert to SRI format
    cmd2 = ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", nix32_hash]
    result2 = subprocess.run(cmd2, capture_output=True, text=True, timeout=30)
    if result2.returncode != 0:
        print(f"  nix hash convert failed: {result2.stderr}")
        return None
    return result2.stdout.strip()


def build_tag(version: str, tagrel: int) -> str:
    return f"cachyos-{version}-{tagrel}"


def build_url(tag: str) -> str:
    return f"https://github.com/CachyOS/linux/releases/download/{tag}/{tag}.tar.gz"


def main() -> int:
    print("Updating CachyOS kernel sources...")

    # Find repo root
    current = Path.cwd()
    while not (current / "flake.lock").exists():
        if current == current.parent:
            print("Could not find flake.lock in any parent directory")
            return 1
        current = current.parent

    sources_file = current / "kernel-cachyos" / "sources.json"

    # Load existing sources for comparison
    existing = {}
    if sources_file.exists():
        with open(sources_file, encoding="utf-8") as f:
            existing = json.load(f)

    # Fetch and parse releases
    print("Fetching releases from GitHub...")
    releases = fetch_releases()
    parsed = parse_releases(releases)
    tracks = pick_latest_per_track(parsed)

    if "latest" not in tracks:
        print("Could not determine latest kernel release")
        return 1

    # Build new sources.json
    new_sources = {}
    for track_name in ["latest", "lts", "rc"]:
        if track_name not in tracks:
            print(f"Warning: no {track_name} release found, skipping")
            continue

        track = tracks[track_name]
        tag = build_tag(track["version"], track["tagrel"])

        # Check if this version is already in sources.json with a hash
        old = existing.get(track_name, {})
        old_tag = build_tag(old.get("version", ""), old.get("tagrel", 0))

        if old_tag == tag and old.get("hash"):
            print(f"  {track_name}: {tag} (unchanged)")
            new_sources[track_name] = old
        else:
            print(f"  {track_name}: {old_tag} -> {tag}")
            url = build_url(tag)
            sri_hash = nix_prefetch_url(url)
            if not sri_hash:
                print(f"  Failed to prefetch {track_name} source")
                return 1
            new_sources[track_name] = {
                "version": track["version"],
                "tagrel": track["tagrel"],
                "hash": sri_hash,
            }

    with open(sources_file, "w", encoding="utf-8") as f:
        json.dump(new_sources, f, indent=2)
        f.write("\n")

    print(f"Sources updated: {sources_file}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
