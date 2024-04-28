{
  description = "example python poetry nix";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, nixpkgs, poetry2nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;

          pythonPkg = pkgs.python310;

          app = mkPoetryApplication {
            python = pythonPkg;
            projectDir = ./.;
          };

          devShell = {
            cachix.enable = true;
            packages = [
              pkgs.git
              pkgs.nil
            ];

            languages = {
              nix.enable = true;
              python = {
                enable = true;
                package = pythonPkg;
                poetry = {
                  enable = true;
                };
              };
            };

            difftastic.enable = true;
            dotenv.enable = true;
            devcontainer.enable = true;

            enterShell = ''
              python --version
              which python
              poetry --version
              which poetry
            '';

            pre-commit = {
              hooks = {
                autoflake.enable = true;
                ruff.enable = true;
                poetry-check.enable = true;
              };
            };
          };

        in
        {
          packages = {
            default = pkgs.hello;
            app = app;
          };
          devenv.shells.default = devShell;
        };
      flake = { };
    };
}
