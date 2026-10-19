{ ... }:

{
  imports = [
    ./options

    ./programs/common.nix
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/tmux.nix
    ./programs/vim.nix
    ./programs/terminator.nix
  ];
}
