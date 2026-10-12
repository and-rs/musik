{
  description = "A beginner-friendly TidalCycles and SuperCollider setup";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      perSystem = system:
        let
          pkgs = import nixpkgs { inherit system; };
          scVersion = "3.14.1";

          supercolliderApp =
            if pkgs.stdenv.hostPlatform.isDarwin then
              pkgs.stdenvNoCC.mkDerivation {
                pname = "supercollider-macos-app";
                version = scVersion;
                src = pkgs.fetchurl {
                  name = "SuperCollider-${scVersion}-macOS-universal.dmg";
                  url = "https://github.com/supercollider/supercollider/releases/download/Version-${scVersion}/SuperCollider-${scVersion}-macOS-universal.dmg";
                  hash = "sha256-7SZLMnUtJ/yG5QbdCn6zbefBnrznPD/fLtVRT4xz8C4=";
                };
                nativeBuildInputs = [ pkgs.undmg ];
                sourceRoot = "SuperCollider.app";
                dontStrip = true;
                dontFixup = true;

                installPhase = ''
                  mkdir -p "$out/Applications"
                  cp -R . "$out/Applications/SuperCollider.app"
                '';
              }
            else
              null;

          sclang = pkgs.writeShellApplication {
            name = "sclang";
            text = ''
              exec "${supercolliderApp}/Applications/SuperCollider.app/Contents/MacOS/sclang" "$@"
            '';
          };

          scsynth = pkgs.writeShellApplication {
            name = "scsynth";
            text = ''
              exec "${supercolliderApp}/Applications/SuperCollider.app/Contents/Resources/scsynth" "$@"
            '';
          };

          scide = pkgs.writeShellApplication {
            name = "scide";
            text = ''
              exec /usr/bin/open -a "${supercolliderApp}/Applications/SuperCollider.app" "$@"
            '';
          };

          supercolliderTools =
            if pkgs.stdenv.hostPlatform.isLinux then
              pkgs.supercollider
            else
              pkgs.symlinkJoin {
                name = "supercollider-tools";
                paths = [ sclang scsynth scide ];
              };

          tidalGhc = pkgs.haskellPackages.ghcWithPackages (haskellPackages: [
            haskellPackages.tidal
          ]);

          tidalBoot = pkgs.runCommand "tidal-boot" {
            nativeBuildInputs = [ pkgs.gnutar pkgs.gzip ];
          } ''
            mkdir -p "$out"
            tar -xOzf "${pkgs.haskellPackages.tidal.src}" \
              "tidal-${pkgs.haskellPackages.tidal.version}/BootTidal.hs" \
              > "$out/BootTidal.hs"
          '';

          tidal = pkgs.writeShellApplication {
            name = "tidal";
            runtimeInputs = [ tidalGhc ];
            text = ''
              exec ghci -ghci-script "${tidalBoot}/BootTidal.hs" "$@"
            '';
          };

          superdirt = pkgs.writeShellApplication {
            name = "superdirt";
            runtimeInputs = [ supercolliderTools ];
            text = ''
              script="$PWD/superdirt.scd"
              if [[ ! -f "$script" ]]; then
                echo "Run superdirt from the project directory containing superdirt.scd." >&2
                exit 1
              fi
              exec sclang -D "$script" "$@"
            '';
          };
        in
        {
          inherit supercolliderApp supercolliderTools tidal superdirt;
          devShell = pkgs.mkShell {
            packages = [ tidalGhc tidal supercolliderTools superdirt ];
            shellHook = ''
              echo "TidalCycles and SuperCollider are ready. See README.md to get started."
            '';
          };
        };
    in
    {
      devShells = forAllSystems (system: {
        default = (perSystem system).devShell;
      });

      packages = forAllSystems (system:
        let
          env = perSystem system;
          pkgs = import nixpkgs { inherit system; };
        in {
          supercollider-tools = env.supercolliderTools;
          tidal = env.tidal;
          default = env.supercolliderTools;
        } // nixpkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          supercollider-app = env.supercolliderApp;
        });
    };
}
