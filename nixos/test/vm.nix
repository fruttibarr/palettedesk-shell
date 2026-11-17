# A throwaway NixOS VM that imports ../module.nix, for testing the NixOS install end to end.
# Build and run it with the steps in nixos/test/README.md. Login: tester / tester (never use outside a VM).
{ config, lib, pkgs, ... }:
{
  imports = [ ../module.nix ];

  system.stateVersion = lib.trivial.release;
  networking.hostName = "palettedesk-test";

  users.users.tester = {
    isNormalUser = true;
    password = "tester";
    extraGroups = [ "wheel" "video" "audio" "ydotool" ];
  };
  security.sudo.wheelNeedsPassword = false;
  services.getty.autologinUser = "tester";
  services.openssh = { enable = true; settings.PasswordAuthentication = true; };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # VM sizing; these options only exist for the `.vm` build
  virtualisation.vmVariant.virtualisation = {
    memorySize = 6144;
    cores = 4;
    # carry the Nix store inside the VM image (no virtiofs, so it also runs in a rootless container)
    mountHostNixStore = false;
    useNixStoreImage = true;
    writableStore = true;
    sharedDirectories = lib.mkForce { };   # no host folders either (virtiofsd needs real privileges)
    diskSize = 20480;
    resolution = { x = 1920; y = 1080; };
    forwardPorts = [ { from = "host"; host.address = "0.0.0.0"; host.port = 2223; guest.port = 22; } ];
  };
}
