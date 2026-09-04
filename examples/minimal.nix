{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [
      "nofail"
      "noauto"
    ];
  };

  swapDevices = [ ];
  zramSwap.enable = true;

  networking.hostName = "orangepizero2w";
  networking.networkmanager = {
    enable = true;
    unmanaged = [ "interface-name:usb0" ];
    wifi.powersave = false;
  };

  services.openssh.enable = false;

  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
    ];
  };

  system.stateVersion = "26.05";
}
