# Support Arch Linux avec Home Manager

Le projet `nixos-gaming` peut également être utilisé sur une installation **Arch Linux** afin de gérer la configuration utilisateur avec **Nix + Home Manager**, sans remplacer le système Arch.

L'objectif est de conserver :

* **pacman** pour la gestion du système Arch et des paquets système ;
* **Nix** pour fournir l'environnement déclaratif ;
* **Home Manager** pour gérer les dotfiles et la configuration utilisateur ;
* le même dépôt Git et les mêmes `inputs` que la configuration NixOS Gaming.

---

## Architecture

Le flake contient deux types de configurations :

```text
nixos-gaming/
├── flake.nix
│
├── hosts/
│   └── gaming/
│       ├── configuration.nix
│       └── hardware-configuration.nix
│
├── home/
│   ├── gaming.nix
│   ├── arch.nix
│   └── common.nix
│
└── modules/
    ├── nixos/
    │   ├── cachyos2.nix
    │   ├── desktop.nix
    │   ├── gaming.nix
    │   └── performance.nix
    │
    └── home/
        ├── git.nix
        ├── shell.nix
        ├── neovim.nix
        └── starship.nix
```

La séparation est la suivante :

```text
                         flake.nix
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    nixosConfigurations              homeConfigurations
              │                             │
           gaming                          arch
              │                             │
            NixOS                           Arch
              │                             │
       NixOS + Home Manager          Home Manager standalone
```

---

# 1. Installer Nix sur Arch Linux

L'installation de Nix utilise le mode multi-utilisateur (`--daemon`) :

```bash
curl --proto '=https' --tlsv1.2 \
  -L https://nixos.org/nix/install | sh -s -- --daemon
```

Le mode multi-utilisateur installe Nix notamment dans :

```text
/nix
```

et crée le service :

```text
nix-daemon.service
nix-daemon.socket
```

ainsi qu'un groupe et plusieurs utilisateurs système dédiés aux builds :

```text
nixbld1
nixbld2
...
nixbld32
```

Ces comptes sont utilisés par Nix pour exécuter les builds avec des privilèges limités. Ils ne correspondent pas à des utilisateurs humains et ne créent pas de sessions utilisateur supplémentaires.

---

# 2. Activer `nix-command` et `flakes`

Les commandes modernes de Nix ainsi que les flakes nécessitent les fonctionnalités expérimentales :

```text
nix-command
flakes
```

Modifier :

```bash
sudoedit /etc/nix/nix.conf
```

et ajouter :

```ini
experimental-features = nix-command flakes
```

Puis redémarrer le daemon :

```bash
sudo systemctl restart nix-daemon
```

Recharger le shell :

```bash
exec $SHELL -l
```

Vérifier :

```bash
nix --version
```

Tester une commande Nix :

```bash
nix shell nixpkgs#vim
```

---

# 3. Configuration du flake

Le flake contient déjà Home Manager :

```nix
home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

La configuration NixOS Gaming utilise Home Manager comme module NixOS :

```nix
home-manager.nixosModules.home-manager
```

Arch Linux utilise quant à lui Home Manager en mode **standalone**.

Ajouter dans `outputs` :

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

La configuration NixOS Gaming reste inchangée :

```nix
nixosConfigurations.gaming = nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    {
      nixpkgs.config.allowUnfree = true;

      nixpkgs.overlays = [
        nix-cachyos-kernel.overlays.pinned
      ];
    }

    disko.nixosModules.disko

    ./hosts/gaming/configuration.nix

    ./modules/cachyos2.nix
    ./modules/desktop.nix
    ./modules/gaming.nix
    ./modules/performance.nix

    home-manager.nixosModules.home-manager

    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.users.user =
        import ./home/gaming.nix;
    }
  ];
};
```

---

# 4. Configuration Home Manager pour Arch

Créer :

```text
home/arch.nix
```

avec une configuration minimale :

```nix
{ ... }:

{
  home.username = "user";
  home.homeDirectory = "/home/user";

  home.stateVersion = "25.11";
}
```

`home.username` et `home.homeDirectory` **ne créent pas l'utilisateur Linux**.

Ils indiquent simplement à Home Manager quel utilisateur existant doit être configuré.

Vérifier l'utilisateur courant :

```bash
whoami
```

et son répertoire :

```bash
echo "$HOME"
```

Les valeurs doivent correspondre à :

```nix
home.username = "user";
home.homeDirectory = "/home/user";
```

---

# 5. Home Manager ne remplace pas Arch

Home Manager fonctionne comme une couche utilisateur au-dessus d'Arch :

```text
Arch Linux
│
├── pacman
│   ├── kernel
│   ├── drivers
│   ├── applications
│   └── outils système
│
└── Nix
    └── Home Manager
        ├── dotfiles
        ├── .zshrc
        ├── .gitconfig
        ├── ~/.config
        ├── Neovim
        ├── Starship
        └── configuration utilisateur
```

Home Manager ne :

* remplace pas Arch Linux ;
* remplace pas `pacman` ;
* modifie pas le kernel ;
* modifie pas le bootloader ;
* crée pas d'utilisateur Linux ;
* remplace pas `/etc` ;
* convertit pas Arch en NixOS.

---

# 6. Gestion des paquets

Si un outil est déjà installé par `pacman` :

```bash
pacman -Qs ripgrep
pacman -Qs fd
pacman -Qs fzf
pacman -Qs jq
pacman -Qs yq
pacman -Qs git
```

il n'est pas nécessaire de le redéclarer dans :

```nix
home.packages
```

Par exemple, éviter de faire inutilement :

```nix
home.packages = with pkgs; [
  ripgrep
  fd
  fzf
  jq
  yq
  git
];
```

si ces logiciels sont déjà gérés par Arch.

Une séparation possible est :

```text
pacman
│
├── kernel
├── drivers
├── applications
└── outils CLI

Home Manager
│
├── configuration Zsh
├── configuration Git
├── configuration Neovim
├── configuration Starship
└── dotfiles
```

Nix peut toutefois être utilisé pour certains logiciels spécifiques lorsque l'objectif est de rendre leur version reproductible indépendamment d'Arch.

---

# 7. Premier déploiement

Depuis la racine du projet :

```bash
cd ~/Workspace/nixos-projects/nixos-gaming
```

Le binaire `home-manager` n'est pas nécessairement installé globalement.

Il peut être exécuté directement depuis l'input du flake :

```bash
nix run github:nix-community/home-manager -- \
  switch --flake .#arch
```

Une fois le déploiement terminé, on obtient une génération Home Manager :

```text
2026-09-28 11:48 : id 1 -> /nix/store/...-home-manager-generation (current)
```

Cette génération représente la configuration utilisateur actuellement active.

---

# 8. Générations Home Manager

Lister les générations :

```bash
nix run github:nix-community/home-manager -- generations
```

Exemple :

```text
2026-09-28 11:48 : id 1 -> /nix/store/...-home-manager-generation (current)
```

Les générations permettent de conserver l'historique des configurations Home Manager et de revenir à une génération précédente si nécessaire.

---

# 9. Message `Git tree is dirty`

Lors de l'utilisation du flake, Nix peut afficher :

```text
warning: Git tree '/home/user/Workspace/nixos-projects/nixos-gaming' is dirty
```

Cela signifie simplement que le dépôt Git contient des modifications non commit.

Vérifier :

```bash
git status
```

Ce message n'empêche pas le déploiement.

---

# 10. `nixConfig` et le cache CachyOS

La configuration NixOS Gaming utilisait initialement :

```nix
nixConfig = {
  extra-substituters = [
    "https://attic.xuyh0120.win/lantian"
  ];

  extra-trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
  ];
};
```

Comme `nixConfig` est défini au niveau du flake, cette configuration était également visible lors de l'utilisation du flake depuis Arch.

Pour éviter que le host Arch demande l'autorisation d'utiliser ce cache, le `nixConfig` global peut être supprimé du flake.

La configuration peut alors être ajoutée au host NixOS Gaming :

```nix
{
  nix.settings = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
    ];

    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
}
```

Ainsi :

```text
NixOS Gaming
└── cache CachyOS

Arch
└── aucun cache CachyOS spécifique
```

---

# 11. Architecture Home Manager recommandée

Une fois la configuration fonctionnelle, les configurations Home Manager peuvent être centralisées dans `home/` :

```text
home/
├── common.nix
├── gaming.nix
└── arch.nix
```

`common.nix` contient les configurations communes :

```nix
{
  programs.zsh.enable = true;
  programs.git.enable = true;
}
```

`arch.nix` :

```nix
{
  imports = [
    ./common.nix
  ];

  home.username = "user";
  home.homeDirectory = "/home/user";

  home.stateVersion = "25.11";
}
```

`gaming.nix` :

```nix
{
  imports = [
    ./common.nix
  ];

  # Configuration spécifique au Gaming
}
```

Cela permet de partager progressivement les dotfiles :

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

---

# 12. Workflow

### Arch Linux

```bash
cd ~/Workspace/nixos-projects/nixos-gaming

nix run github:nix-community/home-manager -- \
  switch --flake .#arch
```

### NixOS Gaming

```bash
sudo nixos-rebuild switch --flake .#gaming
```

Les deux systèmes utilisent donc le même dépôt et le même `flake.lock`, tout en ayant des couches système différentes.

---

## Résultat

Le projet devient un dépôt multi-machine :

```text
nixos-gaming/
│
├── flake.nix
│
├── hosts/
│   └── gaming/
│       ├── configuration.nix
│       └── hardware-configuration.nix
│
├── home/
│   ├── common.nix
│   ├── gaming.nix
│   └── arch.nix
│
└── modules/
    ├── nixos/
    │   ├── cachyos2.nix
    │   ├── desktop.nix
    │   ├── gaming.nix
    │   └── performance.nix
    │
    └── home/
        ├── git.nix
        ├── shell.nix
        ├── neovim.nix
        └── starship.nix
```

**Principe général :**

> NixOS gère le système, Arch continue d'être géré par pacman, et Home Manager fournit une couche déclarative commune pour les environnements utilisateur.
