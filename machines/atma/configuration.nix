{
  config,
  lib,
  pkgs ? import <nixpkgs-unstable> { },
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./plymouth.nix
    ../../common/common.nix
    ../../common/desktop.nix
    ../../common/plasma6.nix
    ./ollama.nix
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
    #kernelPackages = pkgs.linuxPackages_zen;
  };
  zramSwap.enable = true;

  networking = {
    hostName = "atma";
    hostId = "a6baff0e";
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

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };

    auto-cpufreq = {
      enable = false;
      settings = {
        battery = {
          govenor = "powersave";
          turbo = "never";
        };
        charger = {
          govenor = "performance";
          turbo = "auto";
        };
      };
    };
  };

  programs = {
    steam.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gimp3
    lutris
    thunderbird
    wine
    obsidian
    ns-usbloader
    alsa-utils
    obs-studio
    vlc
    # pulsemeeter

    # Podman
    # dive # look into docker image layers
    # podman-tui # status of containers in the terminal
    # docker-compose # start group of containers for dev
    # podman-compose # start group of containers for dev

    binutils
    docker-compose
    nvidia-docker
    nvidia-container-toolkit
    libnvidia-container
    tigervnc

  ];

  #hardware.graphics = { enable = true; };
  #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest;
  #hardware.nvidia = {
  #  modesetting.enable = true;
  #  powerManagement.enable = false;
  #  powerManagement.finegrained = false;
  #  open = false;
  #  nvidiaSettings = true;
  #};

  # Enable common container config files in /etc/containers
  programs.virt-manager.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  users.groups.libvirtd.members = [ "laban" ];
  users.groups.docker.members = [ "laban" ];

  #virsh net-start default
  #Or autostart:
  #virsh net-autostart default

  virtualisation.containers.enable = true;
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
      daemon.settings.features.cdi = true;
    };
    #podman = {
    #  enable = true;

    #  # Create a `docker` alias for podman, to use it as a drop-in replacement
    #  dockerCompat = true;

    #  # Required for containers under podman-compose to be able to talk to each other.
    #  defaultNetwork.settings.dns_enabled = true;
    #};
  };

}
