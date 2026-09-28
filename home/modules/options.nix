{ lib, ... }:

{
  options.my.user.git = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Git user name.";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Git user email.";
    };
  };
}