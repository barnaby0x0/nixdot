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