{
  description = "gomod2nix development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/3a7674c896847d18e598fa5da23d7426cb9be3d2";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    ranz2nix = { url = "github:andir/ranz2nix"; flake = false; };
    npmlock2nix-src = { url = "github:tweag/npmlock2nix"; flake = false; };
    sbt-derivation-flake = { url = "github:zaninime/sbt-derivation"; flake = false; };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-utils
    , flake-compat
    , ranz2nix
    , sbt-derivation-flake
    , npmlock2nix-src
    }:
    { }
    //
    (flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ]
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlay
            (import "${sbt-derivation-flake}")
          ];
          config = { };
        };
      in
      rec {
        devShell = with pkgs; mkShell {
          buildInputs = [
          ];
          shellHook = ''
          '';
        };
        defaultPackage = pkgs.theHive_static;
        packages = {
          inherit (pkgs)
            theHive_static
            theHive
            theHive_bower
            ;
        };
      }
      )
    ) //
    {
      overlay = final: prev: {

        theHive_bower = with final;
          (pkgs.buildBowerComponents {
            name = "theHive-bower";
            generated = ./bower-generated.nix;
            src = ./misc;
          });

        theHive_static = with final;
          (npmlock2nix.build {
            src = ./.;
            buildCommands = [ "npm build" ];
            node_modules_attrs = {
              buildInputs = [ phantomjs2 ];
            };
            installPhase = "
            mkdir $out
            cp -r node_modules $out/.
            ";
          });

        npmlock2nix = prev.callPackage "${npmlock2nix-src}" { };

        theHive = with final;
          (sbt.mkDerivation
            rec {
              version = "2021-03-18";
              pname = "TheHive";
              src = fetchFromGitHub {
                owner = "TheHive-Project";
                repo = "TheHive";
                rev = "ce20ee3241767157f829d045938c2d105959becf";
                fetchSubmodules = true;
                sha256 = "0hnbqkyzisyrmqhxwdlkbfjp8db2mk9y5r94w6pv8givf72bvm27";
              };

              depsSha256 = "sha256-H8N3/v9CTk8YOOpbNHJ72MK0E7CdkGs63jQW3jDbkxA=";

              buildPhase = ''
                ./sbt stage
              '';
            });
      };
    };
}
