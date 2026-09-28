{
  disko.devices = {
    disk.main = {
      type = "disk";

      device = "/dev/nvme0n1";

      content = {
        type = "gpt";

        partitions = {
          ESP = {
            name = "EFI";
            size = "1G";
            type = "EF00";

            content = {
              type = "filesystem";

              format = "vfat";

              mountpoint = "/boot";

              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };

          root = {
            name = "NIXOS";

            size = "100%";

            content = {
              type = "filesystem";

              format = "ext4";

              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
