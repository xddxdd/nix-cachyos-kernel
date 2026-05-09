{
  inputs,
  callPackage,
  lib,
  linuxKernel,
  ...
}:
let
  kernels = lib.filterAttrs (_: lib.isDerivation) (callPackage ./. { inherit inputs; });
in
lib.mapAttrs' (
  n: v:
  let
    packages = (linuxKernel.packagesFor v).extend (
      final: prev:
      let
        variant = lib.removePrefix "linux-cachyos-" v.cachyosConfigVariant;
      in
      {
        zfs_cachyos = final.callPackage ../zfs-cachyos {
          inherit inputs variant;
        };
      }
    );
  in
  lib.nameValuePair "linuxPackages-${lib.removePrefix "linux-" n}" packages
) kernels
