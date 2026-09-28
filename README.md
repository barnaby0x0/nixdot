# NixOS Gaming

A reproducible NixOS gaming environment inspired by CachyOS.

The project provides a declarative NixOS gaming system while also allowing the same repository to manage user configuration on regular Arch Linux systems through Home Manager.

The main goals are:

* NixOS
* CachyOS kernel optimizations
* KDE Plasma
* Steam
* Proton / GE-Proton
* DXVK / VKD3D
* Gamescope
* GameMode
* MangoHud
* Mesa / Vulkan
* zram
* declarative performance tuning
* reproducible user configuration with Home Manager
* multi-host support through a single Nix flake

---

# Architecture

The project currently supports two environments:

```text
                         nixos-gaming
                              │
                           flake.nix
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
      nixosConfigurations             homeConfigurations
                │                           │
             gaming                        arch
                │                           │
              NixOS                        Arch
                │                           │
       NixOS + Home Manager        Home Manager standalone
                │                           │
                └─────────────┬─────────────┘
                              │
                       Shared user config
```

The NixOS Gaming host provides the complete operating system:

```text
NixOS
│
├── CachyOS Kernel
├── KDE Plasma
├── Mesa / Vulkan
├── Performance tuning
├── zram
│
└── Gaming
    ├── Steam
    ├── Proton
    ├── GE-Proton
    ├── Gamescope
    ├── GameMode
    └── MangoHud
```

Arch Linux uses the same repository only for the user environment:

```text
Arch Linux
│
├── pacman
│   ├── kernel
│   ├── drivers
│   ├── applications
│   └── system packages
│
└── Nix
    └── Home Manager
        ├── dotfiles
        ├── shell
        ├── Git
        ├── Neovim
        ├── Starship
        └── user configuration
```

---

# Project structure

The project is organized into three main layers:

```text
nixos-gaming/
├── flake.nix
├── flake.lock
├── README.md
│
├── hosts/
│   └── gaming/
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── disko.nix
│
├── modules/
│   ├── cachyos2.nix
│   ├── desktop.nix
│   ├── gaming.nix
│   └── performance.nix
│
└── home/
    ├── common.nix
    ├── gaming.nix
    └── arch.nix
```

The exact Home Manager structure can evolve as more dotfiles are migrated.

The intended separation is:

```text
hosts/
    Machine-specific configuration

modules/
    Reusable NixOS modules

home/
    Home Manager configuration
```

---

# Hosts

## NixOS Gaming

The main NixOS host is:

```text
nixosConfigurations.gaming
```

It is responsible for:

* the NixOS system;
* the CachyOS kernel;
* desktop configuration;
* gaming packages;
* performance tuning;
* Disko integration;
* Home Manager integration.

It is activated with:

```bash
sudo nixos-rebuild switch --flake .#gaming
```

---

## Arch Linux

Arch is not configured as a NixOS host.

Instead, Home Manager runs in standalone mode:

```text
homeConfigurations.arch
```

It is activated with:

```bash
nix run github:nix-community/home-manager -- \
  switch --flake .#arch
```

Arch remains managed by `pacman`.

Nix/Home Manager is used for the user environment and dotfiles.

---

# Requirements

## NixOS Gaming

* x86_64 machine
* UEFI firmware
* NixOS Live ISO for a clean installation
* Internet connection
* Target disk dedicated to the installation

## Arch + Home Manager

* Existing Arch Linux installation
* x86_64 Linux system
* systemd
* Internet connection
* Nix installed in multi-user mode
* flakes enabled

---

# Installing Nix on Arch

Install Nix using the multi-user daemon installer:

```bash
curl --proto '=https' --tlsv1.2 \
  -L https://nixos.org/nix/install | sh -s -- --daemon
```

The installer creates:

```text
/nix
```

and the Nix daemon:

```text
nix-daemon.service
nix-daemon.socket
```

It also creates dedicated build users:

```text
nixbld1
nixbld2
...
nixbld32
```

These are system users used by Nix to isolate builds.

They are not normal interactive users and do not represent additional human accounts.

---

# Enabling flakes on Arch

Modern Nix commands and flakes require the following experimental features:

```text
nix-command
flakes
```

Edit:

```bash
sudoedit /etc/nix/nix.conf
```

and add:

```ini
experimental-features = nix-command flakes
```

Restart the daemon:

```bash
sudo systemctl restart nix-daemon
```

Reload the shell:

```bash
exec $SHELL -l
```

Verify:

```bash
nix --version
```

Test:

```bash
nix shell nixpkgs#vim
```

---

# Home Manager on Arch

Home Manager is already declared as a flake input:

```nix
home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

The NixOS host uses Home Manager as a NixOS module:

```nix
home-manager.nixosModules.home-manager
```

Arch uses Home Manager standalone:

```nix
homeConfigurations.arch =
  home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    modules = [
      ./home/arch.nix
    ];
  };
```

These are two different integration methods.

---

# Arch Home Manager configuration

A minimal `home/arch.nix`:

```nix
{ ... }:

{
  home.username = "user";
  home.homeDirectory = "/home/user";

  home.stateVersion = "25.11";
}
```

The values must correspond to the existing Arch Linux user:

```bash
whoami
```

and:

```bash
echo "$HOME"
```

`home.username` does not create a Linux user.

Home Manager assumes that the user already exists.

---

# Home Manager shared configuration

The intended architecture is to progressively move common user configuration into:

```text
home/common.nix
```

For example:

```nix
{
  programs.zsh.enable = true;
  programs.git.enable = true;
}
```

Then:

```text
home/
├── common.nix
├── gaming.nix
└── arch.nix
```

Both hosts can import the common configuration:

```text
                   home/common.nix
                    /           \
                   /             \
                Arch            Gaming
                 │                │
           home/arch.nix    home/gaming.nix
                 │                │
              Arch Linux        NixOS
```

This allows the same dotfiles to be shared between machines while keeping machine-specific configuration separate.

---

# Package management on Arch

The Arch host intentionally keeps `pacman` as the primary system package manager.

For example, if the following packages already exist on Arch:

```text
ripgrep
fd
fzf
jq
yq
git
```

there is no need to redeclare them in:

```nix
home.packages
```

The preferred separation is:

```text
pacman
│
├── kernel
├── drivers
├── applications
├── system packages
└── CLI tools

Home Manager
│
├── shell configuration
├── Git configuration
├── Neovim configuration
├── Starship configuration
├── dotfiles
└── user services
```

Nix can still be used for individual applications when reproducibility or version pinning is desirable.

---

# First Home Manager deployment on Arch

From the project root:

```bash
cd ~/Workspace/nixos-projects/nixos-gaming
```

Run:

```bash
nix run github:nix-community/home-manager -- \
  switch --flake .#arch
```

A successful activation looks similar to:

```text
Démarrage de l'activation de Home Manager
Activation de checkFilesChanged
Activation de checkLinkTargets
Activation de writeBoundary
Activation de installPackages
Activation de linkGeneration
Nettoyage des liens orphelins
Création des liens de fichiers personnels
Activation de reloadSystemd
```

The first generation can then be inspected with:

```bash
nix run github:nix-community/home-manager -- generations
```

Example:

```text
2026-09-28 11:48 : id 1 -> /nix/store/...-home-manager-generation (current)
```

---

# CachyOS Kernel

The NixOS Gaming host uses:

```text
nix-cachyos-kernel
```

through its pinned overlay:

```nix
nix-cachyos-kernel.overlays.pinned
```

The kernel configuration is handled by the NixOS Gaming modules.

The exact kernel version is determined by `flake.lock` and may change after updating the flake.

For example, the currently validated configuration may evaluate to:

```text
linux-cachyos-latest-7.2.4
```

The exact version should not be considered permanent.

Verify the currently selected kernel with:

```bash
sudo nix eval \
  .#nixosConfigurations.gaming.config.boot.kernelPackages.kernel.name
```

---

# CachyOS binary cache

The NixOS Gaming configuration can use the CachyOS kernel binary cache:

```text
https://attic.xuyh0120.win/lantian
```

with public key:

```text
lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=
```

The cache is intended for the NixOS Gaming environment.

It should not be required by the Arch Home Manager configuration.

The cache configuration should therefore be kept in the NixOS host configuration rather than exposed globally through the flake's top-level `nixConfig`.

For NixOS, system-wide Nix settings should be declared through NixOS configuration:

```nix
nix.settings = {
  extra-substituters = [
    "https://attic.xuyh0120.win/lantian"
  ];

  extra-trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
  ];
};
```

---

# Local development and validation

The following commands are useful when validating the NixOS Gaming configuration.

## 1. Check the flake

```bash
sudo nix flake check
```

---

## 2. Build the complete system without activating it

```bash
sudo nix build \
  .#nixosConfigurations.gaming.config.system.build.toplevel \
  -L
```

This evaluates and builds the complete NixOS system generation without changing the running system.

---

## 3. Verify the configured kernel

```bash
sudo nix eval \
  .#nixosConfigurations.gaming.config.boot.kernelPackages.kernel.name
```

Example:

```text
"linux-cachyos-latest-7.2.4"
```

The exact version can change when `flake.lock` is updated.

---

## 4. Verify the NixOS state version

```bash
sudo nix eval \
  .#nixosConfigurations.gaming.config.system.stateVersion
```

Expected:

```text
"26.05"
```

`system.stateVersion` is a compatibility setting.

It is independent from the version of `nixpkgs` used to build the system.

---

## 5. Dry-build a NixOS generation

```bash
sudo nixos-rebuild dry-build --flake .#gaming
```

This does not activate a new system generation.

---

## 6. Activate the configuration

Only after validation:

```bash
sudo nixos-rebuild switch --flake .#gaming
```

---

# Clean NixOS installation from a Live ISO

The project can be installed directly from GitHub.

The repository does not need to be cloned onto the Live ISO.

The flake can be referenced as:

```text
github:barnaby0x0/nixos-gaming#gaming
```

---

## 1. Boot the NixOS Live ISO

Open a root shell:

```bash
sudo -i
```

Verify that networking works.

---

## 2. Identify the target disk

Before running Disko:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,PARTLABEL,MOUNTPOINTS
```

Also useful:

```bash
blkid
```

The current Disko configuration targets:

```text
/dev/nvme0n1
```

Do not continue unless this is the intended installation disk.

---

# Disko

Disko is used for initial disk preparation.

It is destructive when used with:

```text
--mode disko
```

The current configuration targets:

```text
/dev/nvme0n1
```

Always verify the disk before executing Disko.

---

## Partition, format and mount

Disko can consume the remote flake directly:

```bash
sudo nix \
  --experimental-features "nix-command flakes" \
  run github:nix-community/disko/latest -- \
  --mode disko \
  --flake github:barnaby0x0/nixos-gaming#gaming
```

**WARNING:** `--mode disko` will partition and format the disks defined by the Disko configuration.

After Disko completes:

```bash
mount | grep /mnt
```

and:

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTLABEL,MOUNTPOINTS
```

The expected layout is approximately:

```text
nvme0n1
├─nvme0n1p1   vfat   disk-main-EFI    /mnt/boot
└─nvme0n1p2   ext4   disk-main-NIXOS  /mnt
```

Exact device names may differ.

The EFI and NIXOS labels should match the Disko configuration.

---

# Install NixOS directly from GitHub

No repository clone is required.

Run:

```bash
sudo nixos-install \
  --no-write-lock-file \
  --flake github:barnaby0x0/nixos-gaming#gaming \
  --refresh
```

After installation, the system can be rebuilt using:

```bash
sudo nixos-rebuild switch \
  --no-write-lock-file \
  --flake github:barnaby0x0/nixos-gaming#gaming \
  --refresh
```

## Why `--no-write-lock-file`?

A remote GitHub flake is not writable from the Live ISO.

Without this option, Nix may attempt to modify the flake lock file and fail with:

```text
cannot write modified lock file of flake
(use '--no-write-lock-file' to ignore this)
```

The option prevents Nix from attempting to write the remote repository's lock file.

---

# Reboot

After a successful installation:

```bash
reboot
```

Remove the Live ISO/USB and boot from the installed system.

---

# Important installation notes

## Do not use this

```bash
sudo nixos-install \
  --extra-experimental-features "nix-command flakes" ...
```

`--extra-experimental-features` is not a `nixos-install` option.

If flakes need to be enabled explicitly for a Nix command, use:

```bash
sudo nix \
  --experimental-features "nix-command flakes" \
  ...
```

The NixOS environment used by the project already provides the required functionality in the normal installation workflow.

---

# Disko and hardware-configuration.nix

Disko generates filesystem configuration from:

```text
hosts/gaming/disko.nix
```

Therefore `hosts/gaming/hardware-configuration.nix` must not define duplicate `fileSystems` or `swapDevices` entries for partitions managed by Disko.

Otherwise NixOS can fail because of conflicting filesystem definitions.

---

# Do not run Disko during a normal rebuild

A normal:

```bash
sudo nixos-rebuild switch --flake .#gaming
```

does **not** repartition the disk.

Disko is used for initial disk preparation.

The Disko module can still be imported into the NixOS configuration so that filesystem definitions remain declarative.

The destructive operation is specifically:

```text
--mode disko
```

---

# `stateVersion`

There are two different concepts that should not be confused.

## NixOS

```nix
system.stateVersion = "26.05";
```

This controls compatibility behavior for NixOS system modules.

## Home Manager

```nix
home.stateVersion = "25.11";
```

This controls compatibility behavior for Home Manager modules.

Neither value means that the system is running that exact package release.

The actual package versions are determined by the flake inputs and `flake.lock`.

---

# Git working tree warning

Nix may display:

```text
warning: Git tree '/home/user/Workspace/nixos-projects/nixos-gaming' is dirty
```

This means the repository contains uncommitted changes.

Check them with:

```bash
git status
```

A dirty Git tree does not by itself prevent the configuration from being evaluated or activated.

---

# Current status

Validated during development:

* Flake evaluation
* Multi-host flake structure
* Home Manager standalone on Arch
* Home Manager integration on NixOS
* Disko module integration
* EFI + ext4 root layout
* NixOS system build
* CachyOS kernel selection
* CachyOS kernel binary cache access
* KDE Plasma configuration
* Steam / gaming stack configuration

Arch validation includes:

* Nix multi-user installation
* `nix-command`
* Flakes
* Home Manager standalone
* Home Manager generation activation
* shared flake usage
* separation from the CachyOS binary cache configuration

---

# TODO

The generic configuration should remain independent from hardware-specific tuning.

K8 Plus-specific work will be handled separately:

* identify exact CPU and GPU
* select the appropriate CachyOS microarchitecture package
* evaluate x86-64-v3/v4 or Zen-specific kernel variants
* AMDGPU / Mesa / RADV tuning
* ReBAR / VRR / HDR
* Gamescope configuration
* CPU frequency and power-management tuning
* scheduler comparison
* EEVDF vs BORE
* evaluate `sched_ext` where appropriate
* benchmark stock vs CachyOS configuration

The generic NixOS Gaming configuration should remain usable independently from the K8 Plus hardware-specific profile.

---

# Design principles

The project follows a few simple rules.

## NixOS manages the operating system

```text
NixOS
├── kernel
├── system services
├── networking
├── desktop
├── drivers
├── gaming stack
└── performance configuration
```

## Arch remains Arch

```text
Arch
└── pacman
    └── system packages
```

Nix does not replace Arch's system management.

## Home Manager manages the user environment

```text
Home Manager
├── shell
├── Git
├── Neovim
├── terminal tools
├── dotfiles
└── ~/.config
```

## One flake, multiple environments

```text
                  nixos-gaming
                       │
                    flake.nix
                       │
          ┌────────────┴────────────┐
          │                         │
       NixOS                      Arch
       gaming                     user
          │                         │
   Home Manager              Home Manager
          │                         │
          └────────────┬────────────┘
                       │
                 shared config
```

This allows the project to evolve into a reproducible multi-machine configuration without duplicating the complete Nix setup for every operating system.
