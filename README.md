# Nix packages for CachyOS Kernel

This repo contains Linux kernels with both [CachyOS patches](https://github.com/CachyOS/kernel-patches) and [CachyOS tunings](https://github.com/CachyOS/linux-cachyos).

## Which kernel versions are provided?

This repo provides the latest kernel version and the latest LTS kernel version:

```bash
└───packages
    ├───aarch64-linux
        ├───linux-cachyos-latest
        ├───linux-cachyos-latest-lto
        ├───linux-cachyos-lts
        └───linux-cachyos-lts-lto
    └───x86_64-linux
        ├───linux-cachyos-latest
        ├───linux-cachyos-latest-lto
        ├───linux-cachyos-lts
        └───linux-cachyos-lts-lto
```

The kernel versions are automatically kept in sync with Nixpkgs, so once the latest/LTS kernel is updated in Nixpkgs, CachyOS kernels in this repo will automatically catch up.

The kernels ending in `-lto` has Clang+ThinLTO enabled.

For each linux kernel entry under `packages`, we have a corresponding `linuxPackages` entry under `legacyPackages` for easier use in your NixOS configuration, e.g.:

- `linux-cachyos-latest` -> `inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-latest`
- `linux-cachyos-lts-lto` -> `inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-lts-lto`

## How to use

Add this repo to the inputs section of your `flake.nix`:

```nix
{
  inputs = {
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";
  }
}
```

And then specify `inputs.nix-cachyos-kernel.legacyPackages.${pkgs.system}.linuxPackages-cachyos-latest` (or other variants you'd like) in your `boot.kernelPackages` option:

```nix
{ pkgs, inputs, ... }:
{
  boot.kernelPackages = inputs.nix-cachyos-kernel.legacyPackages.${pkgs.system}.linuxPackages-cachyos-latest
}
```
