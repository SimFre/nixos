#{ config, lib, pkgs ? import <nixpkgs-unstable> {}, ... }:
{ config, lib, pkgs, ... }:
{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../common/common.nix
      ../../common/desktop.nix
      ../../common/plasma6.nix
      ./plymouth.nix
      ./klipper.nix
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
    hostName = "endernix"; 
    hostId = "fe00ab31";
    networkmanager = {
      enable = true;
    };
  };
  security.rtkit.enable = true;
  powerManagement = {
    enable = true;
  };
  system = {
    stateVersion = "25.11";
  };


  environment.systemPackages = with pkgs; [
    # octoprint
    # python314Packages.pip
    # prusa-slicer
    # cura-appimage
    orca-slicer
  ];

  #services.octoprint = {
  #  enable = true;
  #  user = "laban";
  #  port = 5000;
  #  openFirewall = true;
  #};

  services.tailscale = {
    enable = true;
  };

  #services.fprintd.enable = true;
  #services.fprintd.tod.enable = true;
  #services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  # driver is broken

}
