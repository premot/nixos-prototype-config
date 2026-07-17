# WARNING: Applying this layout unconditionally destroys everything on /dev/sda.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      # A GPT BIOS boot partition gives GRUB room for its core image while
      # retaining compatibility with machines that boot in legacy BIOS mode.
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        root = {
          size = "100%";
          priority = 2;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
