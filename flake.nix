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

      defaultUserConfig = {
        username = "user";
        homeDirectory = "/home/user";
        git = {
          name = "User";
          email = "user@example.com";
        };
      };

      # Vide en évaluation pure (nix flake check), rempli quand nixdot lance --impure
      loadUserConfig =
        let
          path = builtins.getEnv "NIXDOT_CONFIG";
        in
        nixpkgs.lib.recursiveUpdate defaultUserConfig (if path == "" then { } else import (/. + path));

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
        {
          system,
          modules,
          specialArgs ? { },
          userConfig ? { },
        }:
        let
          pkgs = mkPkgs system;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs modules;

          extraSpecialArgs = specialArgs // {
            inherit userConfig;
          };
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

              text =
                if configuration != null then
                  ''
                    exec home-manager switch \
                      --flake "${self}#${configuration}" \
                      "$@"
                  ''
                else
                  ''
                    if [ "$#" -lt 1 ]; then
                      echo "Usage: nix run .#install -- <configuration> [options]" >&2
                      exit 1
                    fi

                    configuration="$1"
                    shift

                    exec home-manager switch \
                      --flake "${self}#$configuration" \
                      "$@"
                  '';
            };

        in
        {
          nixdot = pkgs.writeShellApplication {
            name = "nixdot";
            runtimeInputs = [
              pkgs.nix
              pkgs.coreutils
              home-manager.packages.${system}.default
            ];
            text = ''
              config=""
              hm_args=()

              while [ $# -gt 0 ]; do
                case "$1" in
                  --config)
                    [ $# -ge 2 ] || { echo "Erreur : --config nécessite un fichier." >&2; exit 1; }
                    config="$2"; shift 2 ;;
                  -h|--help)
                    echo "Usage : nixdot --config <fichier.nix> [options home-manager, ex: -b backup]"
                    exit 0 ;;
                  *) hm_args+=("$1"); shift ;;
                esac
              done

              [ -f "$config" ] || { echo "Erreur : fichier de configuration absent ou introuvable." >&2; exit 1; }

              NIXDOT_CONFIG="$(realpath "$config")"
              export NIXDOT_CONFIG

              exec home-manager switch --impure \
                --flake "${self}#generic-${system}" \
                "''${hm_args[@]}"
            '';
          };

          install-victor-laptop = install "victor-laptop";
          install-victor-macbook = install "victor-macbook";
          install = install null;

        }
      );

      # homeConfigurations = forAllSystems (system: mkHomeConfiguration system);
      homeModules.default = import ./home/modules;

      ## LEGACY
      # homeConfigurations = {

      #   "victor-laptop" = mkHomeConfiguration {
      #     system = "x86_64-linux";

      #     specialArgs = { inherit vim-flake; };

      #     modules = [
      #       ./home/user.nix
      #       # ./home/modules/default.nix
      #       # ./home/profiles/victor-laptop.nix
      #     ];
      #   };

      #   "generic" = mkHomeConfiguration {
      #     system = "x86_64-linux";

      #     specialArgs = { inherit vim-flake; };

      #     modules = [
      #       ./home/generic.nix
      #     ];

      #     userConfig = {
      #       username = "alice";
      #       homeDirectory = "/home/alice";
      #       git = {
      #         name = "Alice";
      #         email = "alice@example.com";
      #       };
      #     };
      #   };

      # };

      homeConfigurations = {
        "victor-laptop" = mkHomeConfiguration {
          system = "x86_64-linux";

          specialArgs = { inherit vim-flake; };

          modules = [
            ./home/user.nix
          ];
        };
      }
      // builtins.listToAttrs (
        map (system: {
          name = "generic-${system}";
          value = mkHomeConfiguration {
            inherit system;
            specialArgs = { inherit vim-flake; };
            modules = [ ./home/generic.nix ];
            userConfig = loadUserConfig;
          };
        }) systems
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        pkgs.nixfmt
      );
    };
}
