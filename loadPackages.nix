inputs:
pkgs:
let
  load =
    path:
    pkgs.lib.removeAttrs
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
  zfs-cachyos = packages.linuxPackages-cachyos-latest.zfs_cachyos;
  zfs-cachyos-lto = packages.linuxPackages-cachyos-latest-lto.zfs_cachyos;
  zfs-cachyos-lts = packages.linuxPackages-cachyos-lts.zfs_cachyos;
  zfs-cachyos-lts-lto = packages.linuxPackages-cachyos-lts-lto.zfs_cachyos;
  zfs-cachyos-hardened = packages.linuxPackages-cachyos-hardened.zfs_cachyos;
  zfs-cachyos-hardened-lto = packages.linuxPackages-cachyos-hardened-lto.zfs_cachyos;
  zfs-cachyos-rc = packages.linuxPackages-cachyos-rc.zfs_cachyos;
  zfs-cachyos-rc-lto = packages.linuxPackages-cachyos-rc-lto.zfs_cachyos;
}
