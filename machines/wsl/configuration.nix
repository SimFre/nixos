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
  environment = {
    systemPackages = with pkgs; [
      wslu
      socat
    ];
  };
  wsl = {
    enable = true;
    defaultUser = "simfre";
  };
  system.stateVersion = "24.11";

}
