{
  lib,
  pins,
  fetchgit,
  stdenv,
  userPatches ? [],
  tkg-config ? ./customization.cfg,
  wineWowPackages,
  autoconf,
  hexdump,
  perl,
  gitMinimal,
  python3,
  linuxHeaders,
  util-linux,
  ...
}: let
  wineRef = wineWowPackages.stagingFull;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "wine-tkg";
    inherit userPatches;
    version = "10.13";

    inherit (wineRef) NIX_LDFLAGS hardeningDisable;

    srcs = [
      (
        fetchgit {
          url = "https://gitlab.winehq.org/wine/wine.git";
          rev = "refs/tags/wine-${finalAttrs.version}";
          fetchSubmodules = true;
          deepClone = true;
          hash = "sha256-UtbhSdZ6sZMw0gapbgWCv1gRnanmsbF52bNaAtatPpg=";
        }
      )
      (
        fetchgit {
          url = "https://gitlab.winehq.org/wine/wine-staging.git";
          rev = "refs/tags/v${finalAttrs.version}";
          fetchSubmodules = true;
          deepClone = true;
          hash = "sha256-YRX71gu7r307dBQC/czod1ZsXN95DOUpSbAIzAGBDAE=";
        }
      )
      pins.wine-tkg-git
    ];
    sourceRoot = ".";
    patches = [
      ./00-no-rm-repo.patch
    ];

    nativeBuildInputs =
      (wineRef.nativeBuildInputs or [])
      ++ [
        autoconf
        hexdump
        perl
        python3
        gitMinimal
      ];
    buildInputs =
      wineRef.buildInputs
      ++ [
        autoconf
        perl
        gitMinimal
        linuxHeaders
      ]
      ++ lib.optional stdenv.hostPlatform.isLinux util-linux;
    dontPatchELF = true;
    doCheck = false;
    enableParallelBuilding = true;

    postUnpack =
      ''
        mkdir 'src'
        mv 'wine' 'src/wine-git'
        mv 'wine-staging' 'src/wine-staging-git'
        cp -rv --reflink=auto source/wine-tkg-git/* .
        rm -rf source

      ''
      + lib.optionalString (tkg-config != null) ''cp -v --reflink=auto ${tkg-config} customization.cfg'';
    prePatch = ''ls -la'';
    postPatch = ''
      substituteInPlace customization.cfg \
          --replace-warn '_plain_version="wine-VERSION"' '_plain_version="wine-${finalAttrs.version}"'

      patchShebangs wine-tkg-patches
      patchShebangs wine-tkg-scripts
      patchShebangs non-makepkg-build.sh
    '';
    preBuild = ''
      cd src/wine-staging-git
      git remote add origin 'https://gitlab.winehq.org/wine/wine-staging.git'
      cd ../wine-git
      git remote add origin 'https://gitlab.winehq.org/wine/wine.git'
      cd ../..
    '';
    buildPhase = ''
      export _NOCOMPILE="true"
      ./non-makepkg-build.sh ${lib.optionalString (tkg-config != null) "--config ${tkg-config}"}
    '';
  })
