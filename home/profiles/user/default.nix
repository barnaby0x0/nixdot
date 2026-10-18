{ vim-flake, ... }:

{

  my.user.git = {
    name = "Victor";
    email = "victor@mail.com";
  };

  imports = [
    ./../../modules/programs/common.nix
    ./../../modules/programs/shell.nix
    ./../../modules/options.nix
    ./../../modules/programs/git.nix
    ./../../modules/programs/vim.nix
    ./../../modules/programs/terminator.nix
    ./../../modules/programs/tmux.nix
  ];
}
