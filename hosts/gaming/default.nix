{
  pkgs,
  ...
}:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #hardware.cpu.vendor = "amd";
  cachyos.cpu = "amd";

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  networking = {
    networkmanager = {
      enable = true;
      dns = "none"; # Empêche NetworkManager d'écraser resolv.conf
    };
  };

  networking.resolvconf.enable = false;

  # S'assurer que resolved n'interfère pas
  services.resolved.enable = false;

  # Fichier statique
  environment.etc."resolv.conf" = {
    mode = "0644";
    text = ''
      nameserver 10.1.0.51
      nameserver 1.1.1.1
      search lan
    '';
  };

  time.timeZone = "Europe/Zurich";

  i18n = {
    defaultLocale = "fr_FR.UTF-8";

    supportedLocales = [
      "fr_FR.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];

    extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };
  };

  console.keyMap = "fr";
  services.xserver = {
    xkb.layout = "fr";
  };

  services.blueman.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  programs.zsh.enable = true;

  users.users.user.shell = pkgs.zsh;

  users.users.user = {
    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "audio"
    ];

    initialPassword = "changeme";
  };

  users.users.user.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1oFq0GYt8j7vg2nNAJNzwBtqrdOUDp8CMQwLRiz4Vz user@ull"
  ];

  security.sudo.wheelNeedsPassword = true;
  security.pki.certificateFiles = [
    ./certs/proxlab-ca.crt
  ];

  environment.etc."resov.conf".text = ''
    nameserver 1.1.1.1
    nameserver 10.1.0.51
  '';

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    pciutils
    usbutils
    htop
    btop
    fastfetch
    brave
    zsh
    vscodium
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings = {
    trusted-users = [
      "root"
      "user"
    ];

    substituters = [
      "https://cache.nixos.org/"
      "https://attic.xuyh0120.win/lantian"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
}
