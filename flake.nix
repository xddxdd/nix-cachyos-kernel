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
            zfs-cachyos = pkgs.callPackage ./zfs-cachyos {
              inherit inputs;
              kernel = kernels.linux-cachyos-latest;
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
          overlay = self.overlays.default;
          overlays.default = final: prev: {
            cachyosKernels = loadPackages prev;
          };

          hydraJobs.packages = self.packages;

          # Example configurations for testing CachyOS kernel
          nixosConfigurations = lib.genAttrs systems (
            system:
            inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                (
                  { pkgs, config, ... }:
                  {
                    nixpkgs.overlays = [ self.overlay ];
                    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

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
            }
          );
        };
      }
    );
}
