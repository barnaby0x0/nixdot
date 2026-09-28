{ pkgs, ... }:

{

  home.packages = with pkgs; [
    terminator
  ];

  home.file.".config/terminator/config".text = ''
    [global_config]

    [keybindings]
      broadcast_off = <Alt>o
      broadcast_group = <Alt>g
      broadcast_all = <Alt>a

    [profiles]
      [[default]]
        background_color = "#300a24"
        background_darkness = 0.96
        background_type = transparent
        foreground_color = "#ffffff"
        show_titlebar = False
        scrollbar_position = hidden

    [layouts]
      [[default]]
        [[[window0]]]
          type = Window
          parent = ""
          size = 900, 400
        [[[child1]]]
          type = Terminal
          parent = window0

    [plugins]
  '';
}
