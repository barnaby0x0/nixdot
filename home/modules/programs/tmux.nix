{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # --- Options natives Home Manager ---
    terminal = "screen-256color";      # set -g default-terminal
    baseIndex = 1;                     # set -g base-index + setw -g pane-base-index
    historyLimit = 25000;              # set-option -g history-limit
    mouse = true;                      # set -g mouse on
    keyMode = "vi";                    # setw -g mode-keys vi
    escapeTime = 10;                   # set -s escape-time

    # --- Plugins via nixpkgs ---
    plugins = with pkgs.tmuxPlugins; [
      sensible
      # Les plugins suivants ne sont pas dans nixpkgs,
      # voir la section TPM ci-dessous
    ];

    # --- Configuration brute ---
    extraConfig = ''
      # Reload configuration
      bind-key -r r source-file ~/.config/tmux/tmux.conf

      # Plugins configurés via TPM
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'graemedavidson/tmux-pane-focus'

      # Pane focus settings
      set -g @pane-focus-size on
      set -g @pane-focus-size '50'
      set -g @pane-focus-direction '+'

      # Initialisation TPM (à la toute fin)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };

  # --- TPM : installation manuelle du Plugin Manager ---
  home.file.".tmux/plugins/tpm".source = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "e261deb1b47614eed3400089ce7197dc68acc4eb";
    sha256 = "sha256-oRKUZNyJYQXlkeQfbEYiltUEBpvdwn2SoEBWHVUNmrA=";
  };
}