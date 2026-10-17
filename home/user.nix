{ vim-flake, ... }:

{
  home.username = "user";
  home.homeDirectory = "/home/user";

  home.stateVersion = "26.05";

  imports = [
    ./profiles/user
  ];
}
