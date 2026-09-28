{
  callPackage,
  lib,
  fetchurl,
  fetchgit,
  ...
}:
let
  mkCachyKernel = callPackage ./mkCachyKernel.nix { };

  # FIXME: remove this patch when no longer applicable
  # https://github.com/CachyOS/linux-cachyos/issues/1031
  ltsPatch = fetchurl {
    url = "https://github.com/user-attachments/files/32050144/0001-revert-drm-gud-validate-TV-mode-names-before-creating-enum-property.patch";
    hash = "sha256-hBw+vsSix/eQIPS26qT7YTe6W2rdqw2eF2Q3sJfksa4=";
  };

  linuxSources = lib.mapAttrs (_: v: {
    inherit (v) version;
    src = fetchurl {
      inherit (v) url hash;
    };
    cachyosConfigFile = fetchurl {
      url = v.configUrl;
      hash = v.configHash;
    };
    cachyosPatchesSrc = fetchgit {
      url = "https://github.com/CachyOS/kernel-patches.git";
      rev = v.patchRev;
      rootDir = "${v.patchVersion}/";
      hash = v.patchHash;
    };
  }) (lib.importJSON ./version.json);
in
builtins.listToAttrs (
  builtins.map (v: lib.nameValuePair v.pname v) [
    # Latest kernel, provide all LTO and v2/v3/v4/zen4 arch variants
    (mkCachyKernel {
      pname = "linux-cachyos-latest";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v2";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v3";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-x86_64-v4";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-zen4";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      processorOpt = "zen4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v2";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v3";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-x86_64-v4";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-latest-lto-zen4";
      inherit (linuxSources.linux-cachyos)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos";
      lto = "thin";
      processorOpt = "zen4";
    })

    # LTS kernel
    (mkCachyKernel {
      pname = "linux-cachyos-lts";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-x86_64-v2";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-x86_64-v3";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-x86_64-v4";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-zen4";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      processorOpt = "zen4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-x86_64-v2";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-x86_64-v3";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-x86_64-v4";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-lts-lto-zen4";
      inherit (linuxSources.linux-cachyos-lts)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      patches = [ ltsPatch ];
      zfsVariant = "linux-cachyos-lts";
      lto = "thin";
      processorOpt = "zen4";
    })

    # BORE variant
    (mkCachyKernel {
      pname = "linux-cachyos-bore";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-x86_64-v2";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      cpusched = "bore";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-x86_64-v3";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      cpusched = "bore";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-x86_64-v4";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      cpusched = "bore";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-zen4";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      cpusched = "bore";
      processorOpt = "zen4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto-x86_64-v2";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
      processorOpt = "x86_64-v2";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto-x86_64-v3";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
      processorOpt = "x86_64-v3";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto-x86_64-v4";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
      processorOpt = "x86_64-v4";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bore-lto-zen4";
      inherit (linuxSources.linux-cachyos-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bore";
      lto = "thin";
      cpusched = "bore";
      processorOpt = "zen4";
    })

    # Additional CachyOS provided variants
    (mkCachyKernel {
      pname = "linux-cachyos-bmq";
      inherit (linuxSources.linux-cachyos-bmq)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bmq";
      cpusched = "bmq";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-bmq-lto";
      inherit (linuxSources.linux-cachyos-bmq)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-bmq";
      lto = "thin";
      cpusched = "bmq";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-deckify";
      inherit (linuxSources.linux-cachyos-deckify)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-deckify";
      acpiCall = true;
      handheld = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-deckify-lto";
      inherit (linuxSources.linux-cachyos-deckify)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-deckify";
      lto = "thin";
      acpiCall = true;
      handheld = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf";
      inherit (linuxSources.linux-cachyos-eevdf)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-eevdf-lto";
      inherit (linuxSources.linux-cachyos-eevdf)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-eevdf";
      cpusched = "eevdf";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-hardened";
      inherit (linuxSources.linux-cachyos-hardened)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-hardened";
      hardened = true;
    })
    (mkCachyKernel {
      pname = "linux-cachyos-hardened-lto";
      inherit (linuxSources.linux-cachyos-hardened)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-hardened";
      hardened = true;
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rc";
      inherit (linuxSources.linux-cachyos-rc)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-rc";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rc-lto";
      inherit (linuxSources.linux-cachyos-rc)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-rc";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore";
      inherit (linuxSources.linux-cachyos-rt-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "rt-bore";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-rt-bore-lto";
      inherit (linuxSources.linux-cachyos-rt-bore)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-rt-bore";
      rt = true;
      cpusched = "rt-bore";
      lto = "thin";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-server";
      inherit (linuxSources.linux-cachyos-server)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
    })
    (mkCachyKernel {
      pname = "linux-cachyos-server-lto";
      inherit (linuxSources.linux-cachyos-server)
        version
        src
        cachyosConfigFile
        cachyosPatchesSrc
        ;
      zfsVariant = "linux-cachyos-server";
      cpusched = "eevdf";
      hzTicks = "300";
      preemptType = "none";
      lto = "thin";
    })
  ]
)
