# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

#{ config, lib, pkgs, ... }:
{ config, lib, pkgs ? import <nixpkgs-unstable> {}, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./common.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  zramSwap.enable = true;

  networking.hostName = "atma"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.hostId = "a6baff0e";

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services = {
    # Enable touchpad support (enabled default in most desktopManager).
    libinput.enable = true;
    
    # Enable the OpenSSH daemon.
    openssh.enable = true;

    tailscale = {
      enable = true;
      authKeyParameters.baseURL = "https://vpn.lan2k.org/";
      extraSetFlags = [

      ];
    };

    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];

      xkb = {
        layout = "se";
        variant = "";
      };

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
    pulseaudio = {
      enable = false;
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = {
        enable = true;
      };
    };
  };
  console.keyMap = "sv-latin1";
  security.rtkit.enable = true;
  users.users.laban = {
    isNormalUser = true;
    description = "Simon Fredriksson";
    extraGroups = [ "networkmanager" "wheel" ];
    hashedPassword = "$y$j9T$jmMv6ZMHjYgb5PQGTGpMC1$zRH291CADo7bpBU/QFKc054x2YI0G4HM.CsfqffmDL/";
    #packages = with unstablePkgs; [
    #  discord
    #  chromium
    #  ghostty
    #  spotify
    #  brave
    #];
  };
  programs = {
    firefox.enable = true;
    steam.enable = true;
    xwayland.enable = true;
    ssh.startAgent = true;
    direnv.enable = true;
  };

  environment.systemPackages = with pkgs; [
    neovim
    brave
    discord
    spotify
    gimp3
    lutris
    thunderbird
    wine
    obsidian
    keepassxc
    owncloud-client
    libreoffice-fresh
    ns-usbloader
    vscode.fhs
    ghostty
    nixfmt-rfc-style
    #budgie-desktop-with-plugins
    #budgie-desktop-view
    #budgie-backgrounds

    # Podman
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    #docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
  ];
  fonts.packages = with pkgs; [
    meslo-lgs-nf
  ];
  powerManagement = {
    enable = true;
  };

  #hardware.graphics = { enable = true; };
  #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest;
  #hardware.nvidia = {
  #  modesetting.enable = true;
  #  powerManagement.enable = false;
  #  powerManagement.finegrained = false;
  #  open = false;
  #  nvidiaSettings = true;
  #};

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

# PLASMA
services.displayManager.sddm.enable = true;
services.displayManager.sddm.autoNumlock = true;
services.displayManager.sddm.wayland.enable = true;
services.xserver.desktopManager.plasma6.enable = true;


# COSMIC
# services.displayManager.cosmic-greeter.enable = true;
# services.desktopManager.cosmic.xwayland.enable = true;
# services.desktopManager.cosmic.enable = true;
# environment.systemPackages = with pkgs; [
  #cosmic-bg
  #cosmic-osd
  #cosmic-term
  #cosmic-idle
  #cosmic-edit
  #cosmic-comp
  #cosmic-store
  #cosmic-randr
  #cosmic-panel
  #cosmic-icons
  #cosmic-files
  #cosmic-player
  #cosmic-session
  #cosmic-greeter
  #cosmic-applets
  #cosmic-settings
  #cosmic-launcher
  #cosmic-protocols
  #cosmic-wallpapers
  #cosmic-screenshot
  #cosmic-ext-tweaks
  #cosmic-applibrary
  #cosmic-notifications
  #cosmic-ext-calculator
  #cosmic-settings-daemon
  #cosmic-workspaces-epoch
# ];

# GNOME
# services.xserver.displayManager.gdm.enable = true;
# services.xserver.desktopManager.gnome.enable = true;

# DEEPIN
# services.xserver.displayManager.lightdm.enable = true;
# services.xserver.desktopManager.deepin.enable = true;

# BUDGIE
# services.xserver.displayManager.lightdm.enable = true;
# services.xserver.desktopManager.budgie.enable = true;

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

}
