{
  inputs,
  lib,
  callPackage,
  buildLinux,
  stdenv,
  kernelPatches,
  ...
}:
lib.makeOverridable (
  {
    pname,
    version,
    src,

    # Kernel config variant to be used as defconfig, e.g. "linux-cachyos-lts".
    # See https://github.com/CachyOS/linux-cachyos for available values.
    configVariant,

    # Set to true to enable Clang+ThinLTO.
    lto,

    # Patches to be applied in patchedSrc phase. This is different from buildLinux's kernelPatches.
    prePatch ? "",
    patches ? [ ],
    postPatch ? "",

    # CachyOS fine tuning settings, see ./cachySettings.nix for corresponding options
    # Default value sourced from https://github.com/CachyOS/linux-cachyos/blob/master/linux-cachyos/PKGBUILD
    # Set to null or false to disable
    cpusched ? "bore",
    kcfi ? false,
    hzTicks ? "1000",
    performanceGovernor ? false,
    tickrate ? "full",
    preemptType ? "full",
    ccHarder ? true,
    bbr3 ? false,
    hugepage ? "always",

    # CachyOS additional patch settings
    hardened ? false,
    rt ? false,

    # Build as much components as possible as kernel modules, including disabled ones.
    # This can enable unexpected modules. Disabling by default for as close behavior
    # as possible compared to upstream.
    # https://github.com/xddxdd/nix-cachyos-kernel/issues/13
    autoModules ? false,

    # See nixpkgs/pkgs/os-specific/linux/kernel/generic.nix for additional options.
    # Additional args are passed to buildLinux.
    ...
  }@args:
  let
    helpers = callPackage ../helpers.nix { };
    inherit (helpers) stdenvLLVM ltoMakeflags;

    splitted = lib.splitString "-" version;
    ver0 = builtins.elemAt splitted 0;
    major = lib.versions.pad 2 ver0;
    fullVersion = lib.versions.pad 3 ver0;

    cachyosConfigFile = "${inputs.cachyos-kernel.outPath}/${configVariant}/config";
    cachyosPatches = builtins.map (p: "${inputs.cachyos-kernel-patches.outPath}/${major}/${p}") (
      [ "all/0001-cachyos-base-all.patch" ]
      ++ (lib.optional (cpusched == "bore") "sched/0001-bore-cachy.patch")
      ++ (lib.optional (cpusched == "bmq") "sched/0001-prjc-cachy.patch")
      ++ (lib.optional hardened "misc/0001-hardened.patch")
      ++ (lib.optional rt "misc/0001-rt-i915.patch")
    );

    # buildLinux doesn't accept postPatch, so adding config file early here
    patchedSrc = stdenv.mkDerivation {
      pname = "${pname}-src";
      inherit version src prePatch;
      patches = [
        kernelPatches.bridge_stp_helper.patch
        kernelPatches.request_key_helper.patch
      ]
      ++ cachyosPatches
      ++ patches;
      postPatch = ''
        install -Dm644 ${cachyosConfigFile} arch/x86/configs/cachyos_defconfig
      ''
      + postPatch;
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
      installPhase = ''
        mkdir -p $out
        cp -r * $out/
      '';
    };

    defaultLocalVersion = if lto then "-cachyos-lto" else "-cachyos";

    cachySettings = callPackage ./cachySettings.nix { };
    structuredExtraConfig =
      # Apply basic kernel options
      (with lib.kernel; {
        NR_CPUS = lib.mkForce (option (freeform "8192"));
        LOCALVERSION = freeform defaultLocalVersion;

        # Follow NixOS default config to not break etc overlay
        OVERLAY_FS = module;
        OVERLAY_FS_REDIRECT_DIR = no;
        OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW = yes;
        OVERLAY_FS_INDEX = no;
        OVERLAY_FS_XINO_AUTO = no;
        OVERLAY_FS_METACOPY = no;
        OVERLAY_FS_DEBUG = no;
      })
      // (lib.optionalAttrs lto {
        LTO_NONE = lib.kernel.no;
        LTO_CLANG_THIN = lib.kernel.yes;
      })

      # Apply CachyOS specific settings
      // (lib.mapAttrs (_: lib.mkForce) (
        cachySettings.common
        // (lib.optionalAttrs (cpusched != null) cachySettings.cpusched."${cpusched}")
        // (lib.optionalAttrs kcfi cachySettings.kcfi)
        // (lib.optionalAttrs (hzTicks != null) cachySettings.hzTicks."${hzTicks}")
        // (lib.optionalAttrs performanceGovernor cachySettings.performanceGovernor)
        // (lib.optionalAttrs (tickrate != null) cachySettings.tickrate."${tickrate}")
        // (lib.optionalAttrs (preemptType != null) cachySettings.preemptType."${preemptType}")
        // (lib.optionalAttrs ccHarder cachySettings.ccHarder)
        // (lib.optionalAttrs bbr3 cachySettings.bbr3)
        // (lib.optionalAttrs (hugepage != null) cachySettings.hugepage."${hugepage}")
      ))

      # Apply user custom settings
      // (args.structuredExtraConfig or { });
  in
  buildLinux (
    (lib.removeAttrs args [
      "pname"
      "version"
      "src"
      "configVariant"
      "lto"
      "prePatch"
      "patches"
      "postPatch"
    ])
    // {
      inherit pname version;
      src = patchedSrc;
      stdenv = args.stdenv or (if lto then stdenvLLVM else stdenv);

      extraMakeFlags = (lib.optionals lto ltoMakeflags) ++ (args.extraMakeFlags or [ ]);

      defconfig = args.defconfig or "cachyos_defconfig";

      modDirVersion = args.modDirVersion or "${fullVersion}${defaultLocalVersion}";

      # CachyOS's options has some unused options for older kernel versions
      ignoreConfigErrors = args.ignoreConfigErrors or true;

      inherit structuredExtraConfig autoModules;

      extraMeta = {
        description = "Linux CachyOS Kernel" + lib.optionalString lto " with Clang+ThinLTO";
        broken = !stdenv.isx86_64;
      }
      // (args.extraMeta or { });

      extraPassthru = {
        inherit cachyosConfigFile cachyosPatches;
      }
      // (args.extraPassthru or { });
    }
  )
)
