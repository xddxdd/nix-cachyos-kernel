{
  description = "CachyOS Kernels";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  outputs =
    { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        lib,
        ...
      }:
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
            legacyPackages = import ./loadPackages.nix inputs pkgs;

            # Packages only contain linux-cachyos-* due to Flake schema requirements
            packages = lib.filterAttrs (_: lib.isDerivation) legacyPackages;

            apps =
              let
                mkApp = name: script: {
                  type = "app";
                  program =
                    let
                      python = pkgs.python3.withPackages (ps: [ ps.requests ]);
                      app = pkgs.writeShellApplication {
                        inherit name;
                        runtimeInputs = [
                          python
                          pkgs.git
                          pkgs.nix-prefetch-git
                        ];
                        text = ''
                          python3 ${script}
                        '';
                      };
                    in
                    lib.getExe app;
                };
              in
              {
                update-cachyos = mkApp "update-cachyos" ./update.py;
              };

            # Allow build unfree modules such as nvidia_x11
            _module.args.pkgs = lib.mkForce (
              import inputs.nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                  allowInsecurePredicate = _: true;
                };
              }
            );
          };

        flake = {
          overlay = self.overlays.pinned;
          overlays.default = final: prev: {
            cachyosKernels = import ./loadPackages.nix inputs prev;
          };
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
            packages.x86_64-linux = {
              inherit (self.packages.x86_64-linux)
                # Latest kernel
                linux-cachyos-latest
                linux-cachyos-latest-lto
                linux-cachyos-latest-lto-x86_64-v2
                linux-cachyos-latest-lto-x86_64-v3
                linux-cachyos-latest-lto-x86_64-v4
                linux-cachyos-latest-lto-zen4
                linux-cachyos-latest-x86_64-v2
                linux-cachyos-latest-x86_64-v3
                linux-cachyos-latest-x86_64-v4
                linux-cachyos-latest-zen4
                # LTS kernel
                linux-cachyos-lts
                linux-cachyos-lts-lto
                linux-cachyos-lts-lto-x86_64-v2
                linux-cachyos-lts-lto-x86_64-v3
                linux-cachyos-lts-lto-x86_64-v4
                linux-cachyos-lts-lto-zen4
                linux-cachyos-lts-x86_64-v2
                linux-cachyos-lts-x86_64-v3
                linux-cachyos-lts-x86_64-v4
                linux-cachyos-lts-zen4
                # Latest kernel with BORE scheduler
                linux-cachyos-bore
                linux-cachyos-bore-lto
                linux-cachyos-bore-lto-x86_64-v2
                linux-cachyos-bore-lto-x86_64-v3
                linux-cachyos-bore-lto-x86_64-v4
                linux-cachyos-bore-lto-zen4
                linux-cachyos-bore-x86_64-v2
                linux-cachyos-bore-x86_64-v3
                linux-cachyos-bore-x86_64-v4
                linux-cachyos-bore-zen4
                # Additional CachyOS kernel variants
                linux-cachyos-bmq
                linux-cachyos-deckify
                linux-cachyos-eevdf
                linux-cachyos-hardened
                linux-cachyos-rc
                linux-cachyos-rt-bore
                linux-cachyos-server
                # ZFS, latest and LTS
                zfs-cachyos
                zfs-cachyos-lto
                zfs-cachyos-lts
                zfs-cachyos-lts-lto
                # ZFS, less used variants
                zfs-cachyos-hardened
                zfs-cachyos-rc
                ;
            };
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

                        # NVIDIA test
                        hardware.graphics.enable = true;
                        services.xserver.videoDrivers = [ "nvidia" ];
                        hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest;
                        hardware.nvidia.open = true;

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
              cachyos-bore = mkSystem "linuxPackages-cachyos-bore";
              cachyos-bore-lto = mkSystem "linuxPackages-cachyos-bore-lto";
            };
        };
      }
    );
}
