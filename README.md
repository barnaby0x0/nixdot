# nixdot

Reusable **Home Manager** configurations managed with Nix flakes.

The goal of this repository is to keep user-specific configuration reproducible and portable across different machines and NixOS configurations.

## Features

* Nix flakes
* Home Manager
* Multiple user profiles
* Standalone Home Manager configurations
* Reusable Home Manager modules
* Configuration shared between standalone Home Manager and NixOS
* Reproducible configurations through `flake.lock`

## Structure

```text
nixdot/
├── flake.nix
├── flake.lock
└── home/
    ├── user.nix
    ├── arch.nix
    ├── user/
    │   ├── default.nix
    │   └── programs/
    │       ├── common.nix
    │       ├── git.nix
    │       ├── shell.nix
    │       ├── terminator.nix
    │       └── vim.nix
    └── arch/
        └── default.nix
```

The `home/` directory contains the different user profiles.

The files `user.nix` and `arch.nix` are the entry points for their respective Home Manager profiles.

Profiles can import reusable configurations from `home/modules/` or other shared locations.

## Flake outputs

The flake exposes two types of outputs.

### Home Manager modules

```nix
homeManagerModules.user
homeManagerModules.arch
```

These can be imported from another NixOS or Home Manager configuration.

### Standalone configurations

```nix
homeConfigurations.user
homeConfigurations.arch
```

These can be used directly with Home Manager.

## Standalone usage

### User profile

Apply the `user` configuration:

```bash
nix run github:nix-community/home-manager -- \
  switch --flake github:barnaby0x0/nixdot#user
```

### Arch profile

Apply the `arch` configuration:

```bash
nix run github:nix-community/home-manager -- \
  switch --flake github:barnaby0x0/nixdot#arch
```

After the first installation, the regular `home-manager` command can also be used if Home Manager is installed in the environment:

```bash
home-manager switch --flake github:barnaby0x0/nixdot#arch
```

## Rolling back a configuration

Home Manager creates a new generation each time a configuration is activated.

List available generations:

```bash
home-manager generations
```

To return to the previous generation:

```bash
home-manager switch --rollback
```

This is useful when testing a new configuration and you want to quickly restore the previous working state.

Unused generations can be removed with:

```bash
home-manager remove-generations <generation>
```

## Using a specific revision

A specific Git revision can be selected:

```bash
nix run github:nix-community/home-manager -- \
  switch --flake \
  github:barnaby0x0/nixdot/<revision>#arch
```

For example:

```bash
nix run github:nix-community/home-manager -- \
  switch --flake \
  github:barnaby0x0/nixdot/d77e3bfed7e3abf5905f0b28a41cf846db0cf406#arch
```

This is useful when testing or reproducing a known configuration revision.

## Using the configuration from NixOS

The profiles can also be consumed from another flake.

For example, in a NixOS configuration using Home Manager:

```nix
{
  inputs = {
    nixdot.url = "github:barnaby0x0/nixdot";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixdot,
      ...
    }:
    {
      nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.users.user = {
              imports = [
                nixdot.homeManagerModules.user
              ];
            };
          }
        ];
      };
    };
}
```

The `user` profile can therefore be shared between a standalone Home Manager installation and a NixOS system.

## Reusable configuration modules

Configurations that are useful across multiple profiles can be kept separately from the profiles themselves.

For example:

```text
home/
├── modules/
│   └── programs/
│       ├── git.nix
│       ├── shell.nix
│       └── vim.nix
│
├── arch/
│   └── default.nix
│
└── user/
    └── default.nix
```

A reusable configuration can receive parameters from the profile.

For example, `git.nix`:

```nix
{ config, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = config.my.user.git.name;
        email = config.my.user.git.email;
      };

      status.showUntrackedFiles = "yes";
    };
  };
}
```

The profile can then provide its specific values:

```nix
{
  my.user.git = {
    name = "Victor";
    email = "victor@mail.com";
  };

  imports = [
    ../modules/programs/git.nix
  ];
}
```

This keeps reusable configuration independent from a specific profile while allowing each profile to provide its own values.

## Development

Clone the repository:

```bash
git clone https://github.com/barnaby0x0/nixdot.git
cd nixdot
```

Inspect the available flake outputs:

```bash
nix flake show
```

Check the flake:

```bash
nix flake check
```

Update the flake inputs:

```bash
nix flake update
```

Update a specific input:

```bash
nix flake lock --update-input nixpkgs
```

## Testing locally

When developing the configuration, the repository can be used directly:

```bash
nix run github:nix-community/home-manager -- \
  switch --flake .#arch
```

This allows changes to be tested before pushing them to GitHub.

You can inspect the resulting Home Manager generations with:

```bash
home-manager generations
```

If the configuration causes a problem, return to the previous generation with:

```bash
home-manager switch --rollback
```

## Adding a new profile

Create a new entry point under `home/`:

```text
home/
├── user.nix
├── arch.nix
└── new-profile.nix
```

Then expose it from `flake.nix`:

```nix
homeManagerModules.new-profile = ./home/new-profile.nix;

homeConfigurations.new-profile =
  home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    modules = [
      ./home/new-profile.nix
    ];
  };
```

The new profile can then be used with:

```bash
home-manager switch --flake .#new-profile
```

## Design philosophy

This repository intentionally focuses on **user-specific configuration** rather than providing a generic collection of Home Manager modules.

Machine-specific system configuration belongs in the corresponding system flake, while user configuration belongs here.

Reusable configurations such as Git, Vim, shell, and other user programs can be shared between profiles while keeping profile-specific values separate.

This separation makes it possible to:

```text
NixOS system
     │
     ├── system configuration
     │
     └── Home Manager
            │
            └── nixdot
                  ├── user
                  └── arch
```

The same Home Manager profile can therefore be reused by different NixOS systems without coupling the dotfiles repository to a specific host.

## License

Personal configuration repository.
