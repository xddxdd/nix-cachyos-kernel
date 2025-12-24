{
  inputs,
  callPackage,
  lib,
  linuxKernel,
  ...
}:
let
  helpers = callPackage ../helpers.nix { };
  inherit (helpers) kernelModuleLLVMOverride;

  kernels = lib.filterAttrs (_: lib.isDerivation) (callPackage ./. { inherit inputs; });
in
lib.mapAttrs' (
  n: v:
  let
    packages = kernelModuleLLVMOverride (
      (linuxKernel.packagesFor v).extend (
        final: prev: {
          zfs_cachyos = final.callPackage ../zfs-cachyos {
            inherit inputs;
          };
        }
      )
    );
  in
  lib.nameValuePair "linuxPackages-${lib.removePrefix "linux-" n}" packages
) kernels
