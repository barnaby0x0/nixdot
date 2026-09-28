{ ... }:

{
  my.user.git = {
    name = "Victor";
    email = "victor@mail.com";
  };

  imports = [
    ../modules/options.nix
    ../modules/programs/git.nix
  ];
}
