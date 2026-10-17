{
  description = "Reusable Home Manager dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vim-flake = {
      url = "github:Victor733909/flakes?dir=vim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      vim-flake,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkHomeConfiguration =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;

            config.allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "vim-yaml"
              ];
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit vim-flake;
          };

          modules = [
            ./home/user.nix
          ];
        };
    in
    {
      # Reusable Home Manager modules
      homeManagerModules = {
        user = ./home/user.nix;
        arch = ./home/arch.nix;
        shell = ./home/modules/programs/shell.nix;
        git = ./home/modules/programs/git.nix;
        vim = ./home/modules/programs/vim.nix;
      };

      # One configuration per supported system
      homeConfigurations = forAllSystems (system: mkHomeConfiguration system);
      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt-rfc-style
      );
    };
}
