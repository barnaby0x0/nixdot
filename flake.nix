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
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "vim-yaml"
            ];
        };

      mkHomeConfiguration =
        system:
        let
          pkgs = mkPkgs system;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit vim-flake; };
          modules = [ ./home/user.nix ];
        };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;

          install = 
            configuration:
            pkgs.writeShellApplication {
            name = "nixdot-install";

            runtimeInputs = [
              pkgs.nix
              home-manager.packages.${system}.default
            ];

            text = ''
              # if [ "$#" -lt 1 ]; then
              #   echo "Usage: nix run github:barnaby0x0/nixdot#install -- <configuration> [options]"
              #   exit 1
              # fi

              # configuration="$1"
              configuration="${configuration}"
              shift

              exec home-manager switch \
                --flake "${self}#$configuration" \
                "$@"
            '';
          };

          # install =
          #   name:
          #   pkgs.writeShellApplication {
          #     name = "nixdot-install";

          #     runtimeInputs = [
          #       pkgs.nix
          #       home-manager.packages.${system}.default
          #     ];

          #     text = ''
          #       exec home-manager switch \
          #         --flake "${self}#${name}" \
          #         "$@"
          #     '';
          #   };
        in
        {

          install-victor-laptop = install "victor-laptop";
          install-victor-macbook = install "victor-macbook";
          # install = install "";

          install = pkgs.writeShellApplication {
            name = "nixdot-install";

            runtimeInputs = [
              pkgs.nix
              home-manager.packages.${system}.default
            ];

            text = ''
              if [ "$#" -lt 1 ]; then
                echo "Usage: nix run github:barnaby0x0/nixdot#install -- <configuration> [options]"
                exit 1
              fi

              configuration="$1"
              shift

              exec home-manager switch \
                --flake "${self}#$configuration" \
                "$@"
            '';
          };

          configure = pkgs.writeShellApplication {
            name = "nixdot-configure";

            runtimeInputs = [
              pkgs.nix
              home-manager.packages.${system}.default
            ];

            text = ''
              cat <<'EOF'
              nixdot - Home Manager configuration

              Usage:
                nix run github:barnaby0x0/nixdot#configure -- --config ./config.nix

              Arguments:
                --config PATH   Path to the client configuration file (required)
                -b backup      Back up existing files before activation

              Client configuration example (config.nix):
                {
                  git = {
                    name = "Your Name";
                    email = "you@example.com";
                  };
                }

              The configuration file is evaluated by Nix and must return
              an attribute set.
              EOF

              if [ "$#" -eq 0 ]; then
                exit 0
              fi

              config=""

              while [ "$#" -gt 0 ]; do
                case "$1" in
                  --config)
                    if [ "$#" -lt 2 ]; then
                      echo "Error: --config requires a path" >&2
                      exit 1
                    fi
                    config="$2"
                    shift 2
                    ;;
                  *)
                    echo "Error: unknown argument: $1" >&2
                    exit 1
                    ;;
                esac
              done

              if [ -z "$config" ]; then
                echo "Error: --config is required" >&2
                exit 1
              fi

              if [ ! -f "$config" ]; then
                echo "Error: configuration file not found: $config" >&2
                exit 1
              fi

              echo "Configuration file found: $config"
              echo "Next step: pass its evaluated values to Home Manager."
            '';
          };

        }
      );

      # homeConfigurations = forAllSystems (system: mkHomeConfiguration system);
      homeConfigurations = {
        "victor-laptop" = mkHomeConfiguration "x86_64-linux";
        "victor-macbook" = mkHomeConfiguration "aarch64-darwin";
        "victor-server" = mkHomeConfiguration "aarch64-linux";
      };

      formatter = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        pkgs.nixfmt
      );
    };

}
