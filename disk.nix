# WARNING: Applying this layout unconditionally destroys everything on /dev/sda.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sdc";
    content = {
      type = "gpt";
      partitions = {
esp= {
          size = "512M";
          type = "EF00";
          priority = 1;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
mountOptions = [ "umask=0077" ];
};
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
