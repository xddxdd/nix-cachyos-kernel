{
  inputs,
  callPackage,
  lib,
  fetchurl,
  ...
}:
let
  mkCachyKernel = callPackage ./mkCachyKernel.nix { inherit inputs; };

  sources = lib.importJSON ./sources.json;
  cachySrc = track: let
    s = sources.${track};
    tag = "cachyos-${s.version}-${toString s.tagrel}";
  in {
    inherit (s) version;
    src = fetchurl {
      url = "https://github.com/CachyOS/linux/releases/download/${tag}/${tag}.tar.gz";
      inherit (s) hash;
    };
  };
  latest = cachySrc "latest";
  lts = cachySrc "lts";
  rc = cachySrc "rc";
in
builtins.listToAttrs (
  builtins.map (v: lib.nameValuePair v.pname v) [
    # Latest kernel, provide all LTO/CPU arch variants
    (mkCachyKernel {
      pname = "linux-cachyos-latest";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v2";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v3";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v4";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-zen4";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      processorOpt = "zen4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v2";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v3";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v4";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-zen4";
      inherit (latest) version src;
      configVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "zen4";
    })

    # LTS kernel
    (mkCachyKernel {
      pname = "linux-cachyos-lts";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-x86_64-v2";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-x86_64-v3";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-x86_64-v4";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-zen4";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      processorOpt = "zen4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-x86_64-v2";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-x86_64-v3";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-x86_64-v4";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-zen4";
      inherit (lts) version src;
      configVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "zen4";
    })

    # Additional CachyOS provided variants
    (mkCachyKernel {
      pname = "linux-cachyos-bmq";
      inherit (latest) version src;
      configVariant = "linux-cachyos-bmq";
      cpusched = "bmq";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bmq-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos-bmq";
      lto = "thin";
      cpusched = "bmq";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore";
      inherit (latest) version src;
      configVariant = "linux-cachyos-bore";
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-deckify";
      inherit (latest) version src;
      configVariant = "linux-cachyos-deckify";
      acpiCall = true;
      handheld = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-deckify-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos-deckify";
      lto = "thin";
      acpiCall = true;
      handheld = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf";
      inherit (latest) version src;
      configVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-hardened";
      inherit (latest) version src;
      configVariant = "linux-cachyos-hardened";
      hardened = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-hardened-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos-hardened";
      hardened = true;
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rc";
      inherit (rc) version src;
      configVariant = "linux-cachyos-rc";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rc-lto";
      inherit (rc) version src;
      configVariant = "linux-cachyos-rc";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore";
      inherit (latest) version src;
      configVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "bore";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-server";
      inherit (latest) version src;
      configVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-server-lto";
      inherit (latest) version src;
      configVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
      lto = "thin";
    })
  ]
)
