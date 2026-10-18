# home/generic.nix
{ userConfig, vim-flake, ... }:

{
  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;

  home.stateVersion = "26.05";

  imports = [
    ./profiles/generic
  ];
}
