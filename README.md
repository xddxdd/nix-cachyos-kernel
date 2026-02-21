# Nix packages for CachyOS Kernel

This repo contains Linux kernels with both [CachyOS patches](https://github.com/CachyOS/kernel-patches) and [CachyOS tunings](https://github.com/CachyOS/linux-cachyos), as well as [CachyOS-patched ZFS module](https://github.com/CachyOS/zfs).

[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fxddxdd%2Fnix-cachyos-kernel)](https://garnix.io/repo/xddxdd/nix-cachyos-kernel)

> Note: If you see "all builds failed" from Garnix, it means I ran out of free plan's build time. I also have [my own Hydra CI](https://hydra.lantian.pub/jobset/lantian/nix-cachyos-kernel) that's building the kernels.

## Which kernel versions are provided?

This repo provides the following kernel variants, consistent with the [upstream definitions](https://github.com/CachyOS/linux-cachyos?tab=readme-ov-file#kernel-variants--schedulers):

```bash
└───packages
    └───x86_64-linux
        # Latest kernel, provide all LTO/CPU arch variants
        ├───linux-cachyos-latest
        ├───linux-cachyos-latest-x86_64-v2
        ├───linux-cachyos-latest-x86_64-v3
        ├───linux-cachyos-latest-x86_64-v4
        ├───linux-cachyos-latest-zen4
        ├───linux-cachyos-latest-lto
        ├───linux-cachyos-latest-lto-x86_64-v2
        ├───linux-cachyos-latest-lto-x86_64-v3
        ├───linux-cachyos-latest-lto-x86_64-v4
        ├───linux-cachyos-latest-lto-zen4
        # LTS kernel, provide all LTO/CPU arch variants
        ├───linux-cachyos-lts
        ├───linux-cachyos-lts-x86_64-v2
        ├───linux-cachyos-lts-x86_64-v3
        ├───linux-cachyos-lts-x86_64-v4
        ├───linux-cachyos-lts-zen4
        ├───linux-cachyos-lts-lto
        ├───linux-cachyos-lts-lto-x86_64-v2
        ├───linux-cachyos-lts-lto-x86_64-v3
        ├───linux-cachyos-lts-lto-x86_64-v4
        ├───linux-cachyos-lts-lto-zen4
        # Additional CachyOS kernel variants
        ├───linux-cachyos-bmq
        ├───linux-cachyos-bmq-lto
        ├───linux-cachyos-bore
        ├───linux-cachyos-bore-lto
        ├───linux-cachyos-deckify
        ├───linux-cachyos-deckify-lto
        ├───linux-cachyos-eevdf
        ├───linux-cachyos-eevdf-lto
        ├───linux-cachyos-hardened
        ├───linux-cachyos-hardened-lto
        ├───linux-cachyos-rc
        ├───linux-cachyos-rc-lto
        ├───linux-cachyos-rt-bore
        ├───linux-cachyos-rt-bore-lto
        ├───linux-cachyos-server
        └───linux-cachyos-server-lto
```

The kernel versions are automatically kept in sync with Nixpkgs, so once the latest/LTS kernel is updated in Nixpkgs, CachyOS kernels in this repo will automatically catch up.

Use `nix flake show github:xddxdd/nix-cachyos-kernel/release` to see the current effective versions.

The kernels ending in `-lto` has Clang+ThinLTO enabled.

For each linux kernel entry under `packages`, we have a corresponding `linuxPackages` entry under `legacyPackages` for easier use in your NixOS configuration, e.g.:

- `linux-cachyos-latest` -> `inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-latest`
- `linux-cachyos-lts-lto` -> `inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-lts-lto`

## How to use kernels

Add the `release` branch this repo to the inputs section of your `flake.nix`:

```nix
{
  inputs = {
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    # Do not override its nixpkgs input, otherwise there can be mismatch between patches and kernel version
  }
}
```

The `release` branch contains the latest kernel that has been built by my [Hydra CI](https://hydra.lantian.pub/jobset/lantian/nix-cachyos-kernel) and is present in binary cache.

> If you want the absolute latest version with or without binary cache, use the `master` branch (default branch) instead:
>
> ```nix
> {
>   inputs = {
>     nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";
>   }
> }
> ```

Add the repo's overlay in your NixOS configuration, this will expose the packages in this flake as `pkgs.cachyosKernels.*`.

```nix
{
  outputs = { nix-cachyos-kernel, ... }: {
    nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = [
              # Use the exact kernel versions as defined in this repo.
              # Guarantees you have binary cache.
              nix-cachyos-kernel.overlays.pinned

              # Alternatively, build the kernels on top of nixpkgs version in your flake.
              # This might cause version mismatch/build failures!
              nix-cachyos-kernel.overlays.default

              # Only use one of the two overlays!
            ];

            # ... your other configs
          }
        )
      ];
    };
  };
}
```

Then specify `pkgs.cachyosKernels.linuxPackages-cachyos-latest` (or other variants you'd like) in your `boot.kernelPackages` option.

### Binary cache

I'm running a Hydra CI to build the kernels and push them to my Attic binary cache. You can see the build status here: <https://hydra.lantian.pub/jobset/lantian/nix-cachyos-kernel>

To use my binary cache, please add the following config:

```nix
{
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
}
```

This repo also has [Garnix CI](https://garnix.io) set up, and should work as long as the total build time is below the free plan threshold.

[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fxddxdd%2Fnix-cachyos-kernel)](https://garnix.io/repo/xddxdd/nix-cachyos-kernel)

> If you see "all builds failed" from Garnix, it means I ran out of free plan's build time.

```nix
{
  nix.settings.substituters = [ "https://cache.garnix.io" ];
  nix.settings.trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
}
```

### Example configuration

```nix
{
  outputs = { nix-cachyos-kernel, ... }: {
    nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
            boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

            # Binary cache
            nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
            nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

            # ... your other configs
          }
        )
      ];
    };
  };
}
```

### Help! My kernel is failing to build!

In most cases, failing to build a kernel is caused by version mismatch between CachyOS patches and nixpkgs kernel version. (e.g. hardened 6.18 kernel as of 2025-12-12)

Common symptoms are:

- "File not found" error, which indicates that CachyOS patches for given kernel version/variant are unavailable.
- Failures/conflicts when applying patches, which indicates that CachyOS patches are for an older kernel version.

If this is the case, the build will be automatically fixed once versions to be in sync again.

## How to use ZFS modules

> Note: CachyOS-patched ZFS module may fail to compile from time to time. Most compilation failures are caused by incompatibilities between kernel and ZFS. Please check [ZFS upstream issues](https://github.com/openzfs/zfs/issues) for any compatibility reports, and try switching between `zfs_2_3`, `zfs_unstable` and `zfs_cachyos`.

To use ZFS module with `linuxPackages-cachyos-*` provided by this flake, point `boot.zfs.package` to `config.boot.kernelPackages.zfs_cachyos`.

```nix
{
  outputs = { nix-cachyos-kernel, ... }: {
    nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = [ nix-cachyos-kernel.overlays.default ];
            boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

            # ZFS config
            boot.supportedFilesystems.zfs = true;
            boot.zfs.package = config.boot.kernelPackages.zfs_cachyos;

            # ... your other configs
          }
        )
      ];
    };
  };
}
```

If you want to construct your own `linuxPackages` attrset with `linuxKernel.packagesFor (path to your kernel)`, you can directly reference the `zfs-cachyos` attribute in this flake's `packages` / `legayPackages` output, or the `cachyosKernels` overlay:

```nix
{
  outputs = { nix-cachyos-kernel, ... }: {
    nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = [ nix-cachyos-kernel.overlays.default ];
            boot.kernelPackages = pkgs.linuxKernel.packagesFor pkgs.cachyosKernels.linux-cachyos-latest;

            # ZFS config
            boot.supportedFilesystems.zfs = true;
            boot.zfs.package = pkgs.cachyosKernels.zfs-cachyos.override {
              kernel = config.boot.kernelPackages.kernel;
            };

            # ... your other configs
          }
        )
      ];
    };
  };
}
```

### Help! My ZFS module is failing to build!

In most cases, failing to build ZFS module is caused by CachyOS not updating patches for the latest kernel version. The only option is to wait for CachyOS team to update the patches.

## How to customize CachyOS kernel

The kernels provided in this flake can be overridden to use your own kernel source. This is helpful if you want to use a kernel version not available in Nixpkgs, or customize CachyOS optimization settings in [kernel-cachyos/mkCachyKernel.nix](kernel-cachyos/mkCachyKernel.nix).

### Available Arguments

The following arguments can be passed to `mkCachyKernel`:

#### Required Arguments

- **`pname`**: Package name for the kernel
- **`version`**: Kernel version string
- **`src`**: Kernel source derivation
- **`configVariant`**: Kernel config variant to use as defconfig (e.g., `"linux-cachyos-lts"`). See [CachyOS linux-cachyos repo](https://github.com/CachyOS/linux-cachyos) for available values.

#### Optional Arguments

**Compiler & Optimization:**

- **`lto`**: Link-Time Optimization setting. Options: `"none"` (default), `"thin"`, or `"full"`. Non-`"none"` values use Clang.
- **`processorOpt`**: Processor optimization level. Options: `"x86_64-v1"` (default), `"x86_64-v2"`, `"x86_64-v3"`, `"x86_64-v4"`, `"zen4"`, or `"native"` (requires impure environment).
- **`autofdo`**: AutoFDO (Automatic Feedback-Directed Optimization) settings. Options:
  - `false` (default): Disable AutoFDO
  - `true`: Enable AutoFDO for profiling performance patterns only
  - `./path/to/autofdo/profile`: Enable AutoFDO with specified profile (requires `lto != "none"`)

> AutoFDO hasn't been fully tested. Please report issue if you encounter any.

**CachyOS Fine Tuning Settings:**

- **`cpusched`**: CPU scheduler. Options: `"bore"` (default), `"bmq"`, or `null` to disable.
- **`kcfi`**: Enable Kernel Control Flow Integrity. Default: `false`.
- **`hzTicks`**: Timer frequency. Options: `"1000"` (default), `"250"`, `"300"`, `"500"`, `"750"`, or `null` to disable.
- **`performanceGovernor`**: Enable performance governor. Default: `false`.
- **`tickrate`**: Tick rate. Options: `"full"` (default), `"periodic"`, `"idle"`, `"nohz_full"`, or `null` to disable.
- **`preemptType`**: Preemption type. Options: `"full"` (default), `"voluntary"`, `"none"`, or `null` to disable.
- **`ccHarder`**: Enable harder compiler optimizations. Default: `true`.
- **`bbr3`**: Enable BBR3 TCP congestion control. Default: `false`.
- **`hugepage`**: Huge page settings. Options: `"always"` (default), `"madvise"`, `"never"`, or `null` to disable.

**CachyOS Additional Patch Settings:**

- **`hardened`**: Apply hardened security patches. Default: `false`.
- **`rt`**: Apply real-time patches. Default: `false`.
- **`acpiCall`**: Apply ACPI call patches. Default: `false`.
- **`handheld`**: Apply handheld-specific patches. Default: `false`.

**Patch Control:**

- **`prePatch`**: Shell commands to run before applying patches. Default: `""`.
- **`patches`**: List of additional patches to apply. Default: `[ ]`.
- **`postPatch`**: Shell commands to run after applying patches. Default: `""`.

**Module Settings:**

- **`autoModules`**: Build as many components as possible as kernel modules, including disabled ones. Default: `true`.

**Other Options:**

Additional arguments are passed through to `buildLinux` from nixpkgs. See [nixpkgs/pkgs/os-specific/linux/kernel/generic.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/generic.nix) for available options.

### Example Usage

```nix
{
  kernel = pkgs.cachyosKernels.linux-cachyos-latest.override {
    pname = "linux-cachyos-with-custom-source";
    version = "6.12.34";
    src = pkgs.fetchurl {
      # ...
    };

    # Customize CachyOS settings
    cpusched = "bore";
    lto = "thin";
    processorOpt = "x86_64-v3";
    hzTicks = "1000";
    bbr3 = true;
    hardened = false;

    # Additional args are available. See kernel-cachyos/mkCachyKernel.nix
  };

  # For non-LTO kernels
  kernelPackages = pkgs.linuxKernel.packagesFor kernel;


  # For LTO kernels, helpers.kernelModuleLLVMOverride fixes compilation for some
  # out-of-tree modules in nixpkgs.
  kernelPackagesWithLTOFix = let
    # helpers.nix provides a few utilities for building kernel with LTO.
    # I haven't figured out a clean way to expose it in flakes.
    helpers = pkgs.callPackage "${inputs.nix-cachyos-kernel.outPath}/helpers.nix" {};
  in helpers.kernelModuleLLVMOverride (pkgs.linuxKernel.packagesFor kernel);
}
```
