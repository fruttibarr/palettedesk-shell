# NixOS module for PaletteDesk Shell: everything the rice needs at the system level.
#
# Add it to your configuration (e.g. /etc/nixos/configuration.nix):
#
#   imports = [ /path/to/palettedesk-shell/nixos/module.nix ];
#   users.users.<you>.extraGroups = [ "ydotool" ];   # only for "middle click acts as right click"
#
# then `sudo nixos-rebuild switch`, log out and back in, and run ./nixos/install-nixos.sh as your user.
#
# Everything here uses lib.mkDefault, so your own settings win (e.g. iwd instead of NetworkManager).
# Needs a recent nixpkgs (unstable): Hyprland 0.57+ for the Lua config.
{ config, lib, pkgs, ... }:
{
  # Hyprland session, portals and Wayland plumbing
  programs.hyprland.enable = lib.mkDefault true;
  security.polkit.enable = lib.mkDefault true;

  # Audio (the equalizer is a PipeWire filter chain)
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
    wireplumber.enable = lib.mkDefault true;
  };

  # Wi-Fi / Bluetooth / power tiles in the control center
  networking.networkmanager.enable = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;
  services.upower.enable = lib.mkDefault true;
  services.power-profiles-daemon.enable = lib.mkDefault true;

  # "Middle click acts as right click" (virtual mouse clicks)
  programs.ydotool.enable = lib.mkDefault true;

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono noto-fonts-color-emoji ];

  environment.systemPackages = with pkgs; [
    quickshell matugen cava hyprsunset cliphist wl-clipboard grim slurp wf-recorder ffmpeg
    kitty fish xfce.thunar qt6Packages.qt6ct libnotify python3 git curl
    ladspaPlugins   # the equalizer's real limiter (fast lookahead limiter)
    qt6.qtmultimedia
  ];

  # Video wallpapers need Qt's multimedia module, which nixpkgs' quickshell does not bundle.
  # Without it the shell logs `module "QtMultimedia" is not installed` and videos show a still frame
  # (GIFs and images are unaffected). Qt wrappers append to these variables, so this is safe.
  environment.sessionVariables = {
    QML2_IMPORT_PATH = lib.makeSearchPath pkgs.qt6.qtbase.qtQmlPrefix [ pkgs.qt6.qtmultimedia ];
    QT_PLUGIN_PATH = lib.makeSearchPath pkgs.qt6.qtbase.qtPluginPrefix [ pkgs.qt6.qtmultimedia ];
  };

  # Make the LADSPA plugins visible to PipeWire and to scripts/gen-eq.py
  environment.pathsToLink = [ "/lib/ladspa" ];
  services.pipewire.extraLadspaPackages = [ pkgs.ladspaPlugins ];
}
