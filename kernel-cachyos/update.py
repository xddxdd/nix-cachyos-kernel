import json
import subprocess
import tempfile
from pathlib import Path


def get_srctag(variant: str = "latest") -> str:
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as dir:
        subprocess.run(
            ["nix", "build", ".#cachyos-kernel-input-path", "-o", f"{dir}/result"],
            check=True,
        )

        pkgbuild_path = (
            f"linux-cachyos-{variant}" if variant != "latest" else "linux-cachyos"
        )

        with open(f"{dir}/result/{pkgbuild_path}/PKGBUILD") as f:
            pkgbuild = f.read()

        script = pkgbuild + "\necho $_srctag"
        result = subprocess.run(
            ["bash"],
            input=script,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()


def nix_sha256_to_sri(hash: str) -> str:
    cmd = ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", hash]

    print(f"Running command: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

    if result.returncode != 0:
        raise RuntimeError(
            f"nix hash command failed with return code: {result.returncode}"
        )

    output = result.stdout.strip()
    if not output:
        raise RuntimeError("nix hash output is empty")

    return output


def run_nix_prefetch_url(url: str) -> str:
    cmd = ["nix-prefetch-url", url]

    print(f"Running command: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

    if result.returncode != 0:
        raise RuntimeError(
            f"nix-prefetch-url command failed with return code: {result.returncode}"
        )

    output = result.stdout.strip()
    if not output:
        raise RuntimeError("nix-prefetch-url output is empty")

    return output


if __name__ == "__main__":
    versions = {}
    for variant in ["latest", "lts", "rc", "hardened"]:
        print(f"{variant=}")
        srctag = get_srctag(variant)
        real_version = "-".join(srctag.split("-")[1:-1])
        print(f"{srctag=} {real_version=}")

        url = f"https://github.com/CachyOS/linux/releases/download/{srctag}/{srctag}.tar.gz"
        print(f"{url=}")
        hash = run_nix_prefetch_url(url)
        hash = nix_sha256_to_sri(hash)
        print(f"{hash=}")
        versions[variant] = {
            "version": real_version,
            "url": url,
            "hash": hash,
        }

    current = Path.cwd()
    while not (current / "flake.lock").exists():
        if current == current.parent:
            raise RuntimeError(
                "Could not find flake.lock in any parent directory, exiting"
            )
        current = current.parent

    output_file = current / "kernel-cachyos" / "version.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(versions, f, indent=2)
