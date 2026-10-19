{ userConfig, vim-flake, ... }:

{
  imports = [
    ../../modules/options
    ../../modules/programs/common.nix
    ../../modules/programs/shell.nix
    ../../modules/programs/git.nix
    ../../modules/programs/vim.nix
    ../../modules/programs/terminator.nix
    ../../modules/programs/tmux.nix
  ];

  my.user.git = {
    name = userConfig.git.name;
    email = userConfig.git.email;
  };
}
