{
  inputs,
  lib,
  callPackage,
  buildLinux,
  stdenv,
  kernelPatches,
  linuxKernel,
  ...
}:
{
  pnameSuffix,
  version,
  src,
  configVariant,
  lto,
}:
let
  helpers = callPackage ../helpers.nix { };
  inherit (helpers) stdenvLLVM ltoMakeflags kernelModuleLLVMOverride;

  splitted = lib.splitString "-" version;
  ver0 = builtins.elemAt splitted 0;
  major = lib.versions.pad 2 ver0;

  cachyosConfigFile = "${inputs.cachyos-kernel.outPath}/${configVariant}/config";

  # buildLinux doesn't accept postPatch, so adding config file early here
  patchedSrc = stdenv.mkDerivation {
    pname = "linux-cachyos-${pnameSuffix}-src";
    inherit version src;
    patches = [
      kernelPatches.bridge_stp_helper.patch
      kernelPatches.request_key_helper.patch
      "${inputs.cachyos-kernel-patches.outPath}/${major}/all/0001-cachyos-base-all.patch"
    ];
    postPatch = ''
      for DIR in arch/*/configs; do
        install -Dm644 ${cachyosConfigFile} $DIR/cachyos_defconfig
      done
    '';
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

  kernelPackage = buildLinux {
    pname = "linux-cachyos-${pnameSuffix}";
    inherit version;
    src = patchedSrc;
    stdenv = if lto then stdenvLLVM else stdenv;

    extraMakeFlags = lib.optionals lto ltoMakeflags;

    defconfig = "cachyos_defconfig";

    # Clang has some incompatibilities with NixOS's default kernel config
    ignoreConfigErrors = lto;

    structuredExtraConfig =
      with lib.kernel;
      (
        {
          NR_CPUS = lib.mkForce (option (freeform "8192"));
        }
        // lib.optionalAttrs lto {
          LTO_NONE = no;
          LTO_CLANG_THIN = yes;
        }
      );

    extraMeta = {
      description = "Linux CachyOS Kernel" + lib.optionalString lto " with Clang+ThinLTO";
    };
  };
in
[
  (lib.nameValuePair "linux-cachyos-${pnameSuffix}" kernelPackage)
  (lib.nameValuePair "linuxPackages-cachyos-${pnameSuffix}" (
    kernelModuleLLVMOverride (linuxKernel.packagesFor kernelPackage)
  ))
]
