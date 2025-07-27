{
  config,
  lib,
  pkgs ? import <nixpkgs-unstable> { },
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../common/common.nix
    ../../common/desktop.nix
    #../../common/plasma6.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    zfs = {
      requestEncryptionCredentials = true;
    };
    initrd = {
      supportedFilesystems = [ "zfs" ];
    };
    supportedFilesystems = [ "zfs" ];
    kernelPackages = pkgs.linuxPackages_zen;
  };
  zramSwap.enable = true;

  networking = {
    hostName = "shlhtpc";
    hostId = "eff2b131";
    networkmanager = {
      enable = true;
    };
  };
  security.rtkit.enable = true;
  powerManagement = {
    enable = true;
  };
  system = {
    stateVersion = "25.05";
  };

  services = {
    tailscale = {
      enable = true;
      authKeyParameters.baseURL = "https://vpn.lan2k.org/";
      extraSetFlags = [

      ];
    };
  };

  services.xserver.enable = true;
  services.xserver.desktopManager.kodi.enable = true;
  services.displayManager.autoLogin.user = "htpc";
  services.xserver.displayManager.lightdm.greeter.enable = false;
  users.extraUsers.htpc = {}.isNormalUser = true;

  # Define a user account
  services.cage.user = "htpc";
  services.cage.program = "${pkgs.kodi-wayland}/bin/kodi-standalone";
  services.cage.enable = true;

  # For Home Manager
  # home.file.widevine-lib.source = "${pkgs.unfree.widevine-cdm}/share/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so";
  # home.file.widevine-lib.target = ".kodi/cdm/libwidevinecdm.so";
  # home.file.widevine-manifest.source = "${pkgs.unfree.widevine-cdm}/share/google/chrome/WidevineCdm/manifest.json";
  # home.file.widevine-manifest.target = ".kodi/cdm/manifest.json";

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        volumes = [ "home-assistant:/config" ];
        environment.TZ = "Europe/Stockholm";
        image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
        extraOptions = [ 
          "--network=host"
          "--device=/dev/ttyACM0:/dev/ttyACM0"  # Example, change this to match your own hardware
        ];
      };
    };
  };
}
