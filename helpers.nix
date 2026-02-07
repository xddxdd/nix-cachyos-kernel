{
  pkgs,
  lib,
  ...
}:
rec {
  # https://github.com/NixOS/nixpkgs/pull/129806
  # https://github.com/lovesegfault/nix-config/blob/master/nix/overlays/linux-lto.nix

  noBintools = {
    bootBintools = null;
    bootBintoolsNoLibc = null;
  };
  hostLLVM = pkgs.pkgsBuildHost.llvmPackages.override noBintools;
  buildLLVM = pkgs.pkgsBuildBuild.llvmPackages.override noBintools;

  ltoMakeflags = [
    "LLVM=1"
    "LLVM_IAS=1"
    "CC=${buildLLVM.clangUseLLVM}/bin/clang"
    "LD=${buildLLVM.lld}/bin/ld.lld"
    "HOSTLD=${hostLLVM.lld}/bin/ld.lld"
    "AR=${buildLLVM.llvm}/bin/llvm-ar"
    "HOSTAR=${hostLLVM.llvm}/bin/llvm-ar"
    "NM=${buildLLVM.llvm}/bin/llvm-nm"
    "STRIP=${buildLLVM.llvm}/bin/llvm-strip"
    "OBJCOPY=${buildLLVM.llvm}/bin/llvm-objcopy"
    "OBJDUMP=${buildLLVM.llvm}/bin/llvm-objdump"
    "READELF=${buildLLVM.llvm}/bin/llvm-readelf"
    "HOSTCC=${hostLLVM.clangUseLLVM}/bin/clang"
    "HOSTCXX=${hostLLVM.clangUseLLVM}/bin/clang++"

    # Mute nixpkgs CC wrapper warnings for Clang+LTO
    "NIX_CC_WRAPPER_SUPPRESS_TARGET_WARNING=1"
  ];

  stdenvLLVM =
    let
      mkLLVMPlatform =
        platform:
        platform
        // {
          linux-kernel = platform.linux-kernel // {
            makeFlags = (platform.linux-kernel.makeFlags or [ ]) ++ ltoMakeflags;
          };
        };

      stdenv' = pkgs.overrideCC hostLLVM.stdenv hostLLVM.clangUseLLVM;
    in
    stdenv'.override (old: {
      hostPlatform = mkLLVMPlatform old.hostPlatform;
      buildPlatform = mkLLVMPlatform old.buildPlatform;
      extraNativeBuildInputs = [
        hostLLVM.lld
        pkgs.patchelf
      ];
    });

  kernelModuleLLVMOverride =
    kernelPackages_:
    kernelPackages_.extend (
      _final: prev:
      lib.mapAttrs (
        n: v:
        if
          builtins.elem "LLVM=1" kernelPackages_.kernel.commonMakeFlags
          && !(builtins.elem n [ "kernel" ])
          && lib.isDerivation v
          && ((v.overrideAttrs or null) != null)
        then
          v.overrideAttrs (old: {
            makeFlags = (old.makeFlags or [ ]) ++ kernelPackages_.kernel.commonMakeFlags;
            postPatch = (if (old.postPatch or null) == null then "" else old.postPatch) + ''
              if [ -f Makefile ]; then
                substituteInPlace Makefile --replace "gcc" "cc"
              fi
            '';
          })
        else
          v
      ) prev
    );
}
