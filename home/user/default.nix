{ ... }:

{

  my.user.git = {
    name = "Victor";
    email = "victor@mail.com";
  };

  imports = [
    ./programs/common.nix
    ./programs/shell.nix
    ../modules/programs/options.nix
    ../modules/programs/git.nix
    ../modules/programs/vim.nix
    ./programs/terminator.nix
  ];
}
