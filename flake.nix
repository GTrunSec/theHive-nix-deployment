{
  description = "TheHive: a Scalable, Open Source and Free Security Incident Response Platform";

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

        defaultPackage = pkgs.theHive;

        packages = {
          inherit (pkgs)
            theHive_frontend
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
            generated = ./misc/bower-generated.nix;
            src = ./misc;
          });

        theHive_frontend = with final;
          (npmlock2nix.build {
            src = ./misc;
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

        sbt = prev.sbt.override {
          jre = prev.jdk11;
        };

        theHive = with final;
          (final.sbt.mkDerivation
            rec {
              version = "2021-03-29";
              pname = "TheHive";
              src = fetchFromGitHub {
                owner = "TheHive-Project";
                repo = "TheHive";
                rev = "0074446368ba82b55cac5af72ec83fa9b493acb5";
                fetchSubmodules = true;
                sha256 = "14jyrw7sy43ywhya854hbap9wpkqcna80xf529b6gc3mlb5nigl2";
              };

              depsSha256 = "sha256-H8N3/v9CTk8YOOpbNHJ72MK0E7CdkGs63jQW3jDbkxA=";

              HOME = ".";

              buildPhase = ''

                rm -rf build.sbt && cp ${./misc/build.sbt} build.sbt

                substituteInPlace build.sbt \
                --replace 'command = baseDirectory.value -> "grunt build"' 'command = baseDirectory.value -> "/build/source/frontend/node_modules/.bin/grunt build"' \
                --replace 'command = baseDirectory.value -> "grunt wiredep"' 'command = baseDirectory.value -> "/build/source/frontend/node_modules/.bin/grunt wiredep"' \
                --replace 'command = baseDirectory.value -> "bower install"' 'command = baseDirectory.value -> "/build/source/frontend/node_modules/.bin/bower info"' \
                --replace 'command = baseDirectory.value -> "npm install"' 'command = baseDirectory.value -> "${nodejs}/bin/npm install"'

                cp -r ${theHive_frontend}/node_modules frontend/.
                rm -rf frontend/{package.json,package-lock.json} && cp ${./misc/package.json} frontend/. && cp ${./misc/package-lock.json} frontend/.
                # WIP
                cp -r ${theHive_bower}/bower_components frontend/.

                sbt stage
              '';

              installPhase = ''
                mkdir -p $out/{bin,conf,jar,lib}
                mv target/universal/stage/bin/* $out/bin/
                mv target/universal/stage/conf/application.conf target/universal/stage/conf/application.exmaple.conf
                mv target/universal/stage/conf/* $out/conf/
                mv target/universal/stage/lib/* $out/lib/
                mv target/scala-2.12/thehive_2.12-4.1.0-1.jar  $out/jar/
              '';
            });
      };
    };
}
