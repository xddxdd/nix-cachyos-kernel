{
  inputs,
  callPackage,
  kernel ? null,
  variant ? "latest",
  lib,
  fetchurl,
}:
let
  versionJson = lib.importJSON ./version.json;
  metadata = versionJson."${variant}" or versionJson.latest;
  zfsGeneric = callPackage "${inputs.nixpkgs.outPath}/pkgs/os-specific/linux/zfs/generic.nix" {
    inherit kernel;
  };
in
# https://github.com/chaotic-cx/nyx/blob/aacb796ccd42be1555196c20013b9b674b71df75/pkgs/linux-cachyos/packages-for.nix#L99
(zfsGeneric {
  kernelModuleAttribute = "zfs_cachyos";
  kernelMinSupportedMajorMinor = "1.0";
  kernelMaxSupportedMajorMinor = "99.99";
  enableUnsupportedExperimentalKernel = true;
  version = metadata.version;
  tests = { };
  maintainers = with lib.maintainers; [
    pedrohlc
  ];
  hash = "";
  extraPatches = [ ];
}).overrideAttrs
  (prevAttrs: {
    src = fetchurl {
      inherit (metadata) url hash;
    };
    postPatch = builtins.replaceStrings [ "grep --quiet '^Linux-M" ] [ "# " ] prevAttrs.postPatch;
    passthru = prevAttrs.passthru // {
      cachyosVariant = variant;
    };
  })
