# Import from configuration.nix:  imports = [ ./klipper.nix ];
# Review option names against your nixpkgs with: nixos-option services.klipper
{ config, pkgs, ... }:
{
  #users.users.klipper = {
  #  isSystemUser = true;
  #  group = "klipper";
  #  extraGroups = [ "dialout" ];   # serial port access
  #};
  #users.groups.klipper = { };

  services.klipper = {
    enable = true;
    user = "moonraker";
    group = "moonraker";
    # Initial config, copied once; after that Mainsail's editor owns it.
    configFile = ./printer.cfg;
    mutableConfig = true;
    configDir = "/var/lib/moonraker/config";
  };

  services.moonraker = {
    enable = true;
    address = "0.0.0.0";
    allowSystemControl = true;
    settings = {
      authorization = {
        force_logins = false;
        cors_domains = [
          "http://printer.local"
          "http://*.local"
          "http://localhost"
        ];
        trusted_clients = [
          "127.0.0.0/8"
          "192.168.0.0/16"
          "10.0.0.0/8"
        ];
      };
      octoprint_compat = { };
      history = { };
    };
  };

  # Moonraker must reach Klipper's socket and config folder
  users.users.moonraker.extraGroups = [ "dialout" ];

  services.mainsail = {
    enable = true;
    hostName = "printer";   # http://printer.local or the laptop's IP
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  # Avoid ModemManager grabbing the CH340 serial port, if enabled
  systemd.services.ModemManager.enable = false;
}
