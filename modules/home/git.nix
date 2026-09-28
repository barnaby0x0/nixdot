{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Victor";
        email = "victor@mail.com";
      };
      status = {
        showUntrackedFiles = "yes";
      };
    };
  };
}
