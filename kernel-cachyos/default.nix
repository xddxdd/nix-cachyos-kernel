{
  inputs,
  callPackage,
  lib,
  linux_latest,
  linux_testing,
  linux,
  ...
}:
let
  mkCachyKernel = callPackage ./mkCachyKernel.nix { inherit inputs; };
in
builtins.listToAttrs (
  builtins.map (v: lib.nameValuePair v.pname v) [
    (mkCachyKernel {
      pname = "linux-cachyos-latest";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts";
      inherit (linux) version src;
      configVariant = "linux-cachyos-lts";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto";
      inherit (linux) version src;
      configVariant = "linux-cachyos-lts";
      lto = "thin";
    })

    # Additional CachyOS provided variants
    (mkCachyKernel {
      pname = "linux-cachyos-bmq";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bmq";
      cpusched = "bmq";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bmq-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bmq";
      lto = "thin";
      cpusched = "bmq";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bore";
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-deckify";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-deckify";
      acpiCall = true;
      handheld = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-deckify-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-deckify";
      lto = "thin";
      acpiCall = true;
      handheld = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-hardened";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-hardened";
      hardened = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-hardened-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-hardened";
      hardened = true;
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rc";
      inherit (linux_testing) version src;
      configVariant = "linux-cachyos-rc";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rc-lto";
      inherit (linux_testing) version src;
      configVariant = "linux-cachyos-rc";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "bore";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-server";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-server-lto";
      inherit (linux_latest) version src;
      configVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
      lto = "thin";
    })
  ]
)
