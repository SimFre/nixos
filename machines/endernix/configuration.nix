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
    octoprint
    prusa-slicer
    cura-appimage
  ];


}
