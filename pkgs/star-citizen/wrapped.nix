{
  lib,
  extraPkgs ? _pkgs: [],
  extraLibs ? _pkgs: [],
  extraProfile ? "", # string to append to shell profile
  extraEnvVars ? {}, # Environment variables to include in shell profile
  steam,
  star-citizen-unwrapped,
  dxvk-nvapi-vkreflex-layer,
  mangohud,
  gameScopeEnable ? false,
  gamescope,
  pname ? "star-citizen",
  includeGamemode ? false,
  gamemode,
  ...
} @ args: let
  sc = star-citizen-unwrapped.override args;
in
  steam.buildRuntimeEnv {
    inherit pname;
    inherit (sc) version meta;

    extraPkgs = pkgs:
      [sc]
      ++ lib.optional includeGamemode gamemode
      ++ lib.optional gameScopeEnable gamescope
      ++ extraPkgs pkgs;
    extraLibraries = pkgs:
      [dxvk-nvapi-vkreflex-layer mangohud]
      ++ lib.optional includeGamemode gamemode
      ++ lib.optional gameScopeEnable gamescope
      ++ extraLibs pkgs;
    extraEnv = extraEnvVars;
    inherit extraProfile;

    executableName = sc.meta.mainProgram;
    runScript = lib.getExe sc;

    dieWithParent = false;

    extraInstallCommands = ''
      ln -s ${sc}/lib $out/lib
      ln -s ${sc}/share $out/share
    '';
  }
