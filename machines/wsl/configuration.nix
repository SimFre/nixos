# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
   ../../common/common.nix
  ];
  networking = {
    hostName = "wsl";
  };
  environment = {
    systemPackages = with pkgs; [
      wslu
      socat
      nodejs_22
    ];
  };
  wsl = {
    enable = true;
    defaultUser = "simfre";
  };
  programs.nix-ld.enable = true;
  services.openssh.ports = [ 22 9022 ];
  system.stateVersion = "24.11";

}
