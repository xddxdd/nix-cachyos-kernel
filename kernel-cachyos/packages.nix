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
        final: prev:
        let
          variant = v.zfsVariant;
        in
        {
          zfs_cachyos = final.callPackage ../zfs-cachyos {
            inherit inputs variant;
          };

          # VirtualBox host module doesn't pass kernel specific makeflags
          virtualbox = prev.virtualbox.overrideAttrs (old: {
            makeFlags = (old.makeFlags or [ ]) ++ final.kernel.commonMakeFlags;
          });

          # Fix NVIDIA open module build failure
          # https://hydra.lantian.pub/build/30817/nixlog/4
          nvidiaPackages = prev.nvidiaPackages // {
            latest = prev.nvidiaPackages.latest // {
              open = prev.nvidiaPackages.latest.open.overrideAttrs (old: {
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace kernel-open/common/inc/nv-linux.h \
                    --replace-fail \
                      "static inline int __to_hwgpio(const struct gpio_device *gdev," \
                      "static inline int __to_hwgpio(struct gpio_device *gdev,"
                '';
              });
            };
          };
        }
      )
    );
  in
  lib.nameValuePair "linuxPackages-${lib.removePrefix "linux-" n}" packages
) kernels
