{
  description = "Reusable Home Manager dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f rec {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
    in
    {

      # Useful when you use this flake as a dependencie
      homeManagerModules.user = ./home/user.nix;
      homeManagerModules.arch = ./home/arch.nix;

      homeConfigurations = {
        "dev-x86_64-linux" =
          let
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "vim-yaml"
                ];
            };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home/user.nix
            ];
          };

        "dev-aarch64-linux" =
          let
            pkgs = import nixpkgs {
              system = "aarch64-linux";
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "vim-yaml"
                ];
            };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home/user.nix
            ];
          };
      };

      # homeConfigurations.user = forEachSystem (
      #   { pkgs }:
      #   home-manager.lib.homeManagerConfiguration {
      #     inherit pkgs;
      #     modules = [
      #       { nixpkgs.config.allowUnfree = true; }
      #       ./home/user.nix
      #     ];

      #   }
      # );

      # homeConfigurations.arch = forEachSystem (
      #   { pkgs }:
      #   home-manager.lib.homeManagerConfiguration {
      #     inherit pkgs;

      #     modules = [
      #       { nixpkgs.config.allowUnfree = true; }
      #       ./home/arch.nix
      #     ];
      #   }
      # );

      homeModules.shell = ./home/user/programs/shell.nix;
      homeModules.git = ./home/modules/programs/git.nix;
      formatter = forEachSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
