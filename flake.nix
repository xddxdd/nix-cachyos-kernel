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

  nixConfig = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
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
                update-kernel-cachyos = mkApp "update-lernel-cachyos" ./kernel-cachyos/update.py;
                update-zfs-cachyos = mkApp "update-zfs-cachyos" ./zfs-cachyos/update.py;
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
            cachyosKernels = loadPackages prev;
          };
          overlays.pinned = final: prev: {
            cachyosKernels = self.legacyPackages."${final.stdenv.hostPlatform.system}";
          };

          cachyos-kernel-input-path = inputs.cachyos-kernel.outPath;

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
            packages.x86_64-linux = lib.filterAttrs (n: _: !lib.hasSuffix "-v2" n) self.packages.x86_64-linux;
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
