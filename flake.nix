{
  description = "CachyOS Kernels";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    cachyos-kernel = {
      url = "github:CachyOS/linux-cachyos";
      flake = false;
    };
    cachyos-kernel-patches = {
      url = "github:CachyOS/kernel-patches";
      flake = false;
    };
  };
  outputs =
    { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        lib,
        ...
      }:
      let
        loadPackages =
          pkgs:
          let
            load =
              path:
              lib.removeAttrs
                (pkgs.callPackage path {
                  inherit inputs;
                })
                [
                  "override"
                  "overrideDerivation"
                ];
            kernels = load ./kernel-cachyos;
            packages = load ./kernel-cachyos/packages.nix;
          in
          kernels
          // packages
          // {
            zfs-cachyos = packages.linuxPackages-cachyos-latest.callPackage ./zfs-cachyos {
              inherit inputs;
            };
            zfs-cachyos-lto = packages.linuxPackages-cachyos-latest-lto.callPackage ./zfs-cachyos {
              inherit inputs;
            };
          };
      in
      rec {
        systems = [ "x86_64-linux" ];

        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          rec {
            # Legacy packages contain linux-cachyos-* and linuxPackages-cachyos-*
            legacyPackages = loadPackages pkgs;

            # Packages only contain linux-cachyos-* due to Flake schema requirements
            packages = lib.filterAttrs (_: lib.isDerivation) legacyPackages;

            # Allow build unfree modules such as nvidia_x11
            _module.args.pkgs = lib.mkForce (
              import inputs.nixpkgs {
                inherit system;
                config.allowUnfree = true;
              }
            );
          };

        flake = {
          overlay = self.overlays.pinned;
          overlays.default =
            lib.warn
              "\"nix-cachyos-kernel.overlays.default\" may cause kernel/patch version mismatch and build failure. Please use \"nix-cachyos-kernel.overlays.pinned\" instead."
              (
                final: prev: {
                  cachyosKernels = loadPackages prev;
                }
              );
          overlays.pinned = final: prev: {
            cachyosKernels = self.legacyPackages."${final.stdenv.hostPlatform.system}";
          };

          mkCachyKernel =
            { buildLinux, pkgs, ... }@args:
            (import ./kernel-cachyos/mkCachyKernel.nix) {
              inherit
                inputs
                lib
                buildLinux
                args
                ;
              inherit (pkgs)
                stdenv
                callPackage
                kernelPatches
                applyPatches
                impureUseNativeOptimizations
                ;
            };

          hydraJobs = {
            inherit (self) packages;
            nixosConfigurations = lib.mapAttrs (n: v: v.config.system.build.toplevel) self.nixosConfigurations;
          };

          # Example configurations for testing CachyOS kernel
          nixosConfigurations =
            let
              mkSystem =
                kernelPackageName:
                inputs.nixpkgs.lib.nixosSystem {
                  system = "x86_64-linux";
                  modules = [
                    (
                      { pkgs, config, ... }:
                      {
                        nixpkgs.overlays = [ self.overlays.pinned ];
                        boot.kernelPackages = pkgs.cachyosKernels."${kernelPackageName}";

                        # ZFS test
                        boot.supportedFilesystems.zfs = true;
                        boot.zfs.package = config.boot.kernelPackages.zfs_cachyos;
                        networking.hostId = "12345678";

                        # Minimal config to make test configuration build
                        boot.loader.grub.devices = [ "/dev/vda" ];
                        fileSystems."/" = {
                          device = "tmpfs";
                          fsType = "tmpfs";
                        };
                        system.stateVersion = lib.trivial.release;
                      }
                    )
                  ];
                };
            in
            {
              cachyos-latest = mkSystem "linuxPackages-cachyos-latest";
              cachyos-latest-lto = mkSystem "linuxPackages-cachyos-latest-lto";
              cachyos-lts = mkSystem "linuxPackages-cachyos-lts";
              cachyos-lts-lto = mkSystem "linuxPackages-cachyos-lts-lto";
            };
        };
      }
    );
}
