{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #./disko-config.nix
    ];

  #swapDevices =
  #  [ { device = "/dev/disk/by-uuid/c8acb6af-d6bf-49b6-ba3a-95177724ee87"; }
  #  ];

  boot.tmp.cleanOnBoot = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  zramSwap.enable = true;
  networking.hostId = "43ffee12";
  networking.hostName = "barret";
  networking.domain = "lan2k.org";
  services.openssh.enable = true;
  system.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.users.root = {
    openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901'' ];
    hashedPassword = "$6$/quXloWNfT.xdLT8$lc8DODS87x0Eeq/czUsCfsTZggclWysaeEBeE8VB1mojYBtFa7t4HcdYPIFlvaONfkiPFkJn2tYV4YC/9EXwH.";
  };
  users.users.laban = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901'' ];
    hashedPassword = "$6$RIM/z/tXnTu0QRWw$hcvyMXjJR/yrpNNmciGG185We5QORraNa8W8O68Yx8HWqDTTrz106R0NZkKPY58e/gNSRaxe2N69McelsI9G1.";
  };
    
  systemd.timers.Lan2kDNSUpdate = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30m";
        OnUnitActiveSec = "30m";
        Unit = "Lan2kDNSUpdate.service";
    };
  };

  systemd.services.Lan2kDNSUpdate = {
    path = [
      pkgs.curl
    ];
    script = ''
      set -eu
      curl -4 "https://update.lan2k.org/?key=LM6LIKDE6VWECYCLMLJOAZ4BBKF45TI5VNDT3A4DAO1WECY4SFE1UXMFIMK8YRVD"
      curl -6 "https://update.lan2k.org/?key=LM6LIKDE6VWECYCLMLJOAZ4BBKF45TI5VNDT3A4DAO1WECY4SFE1UXMFIMK8YRVD"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    neofetch
    wget
    mc
    lfs
    pv
    #cockpit
    #pkgs.nginx
  ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  services.uptime-kuma.enable = true;
  #services.uptime-kuma.settings = {
  #  UPTIME_KUMA_SSL_KEY = "/etc/ssl/lan2k.org-full.key";
  #  UPTIME_KUMA_SSL_CERT = "/etc/ssl/lan2k.org-full.pem";
  #};

  services.nginx = {
    enable = true;
  #  recommendedProxySettings = true;
  #  recommendedTlsSettings = true;
  #  virtualHosts."uptime.lan2k.org" =  {
  #    enableACME = true;
  #    #useACMEHost = "uptime.lan2k.org";
  #    forceSSL = true;
  #    locations."/" = {
  #      proxyPass = "https://127.0.0.1:3001";
  #      proxyWebsockets = true; # needed if you need to use WebSocket
  #      extraConfig =
  #        # required when the target is also TLS server with multiple hosts
  #        "proxy_ssl_server_name on;" +
  #        # required when the server wants to use HTTP Authentication
  #        "proxy_pass_header Authorization;"
  #        ;
  #    };
  #  };
  };

  #security.acme = {
  #  acceptTerms = true;
  #  defaults.email = "simon@palidor.se";
  #  certs."uptime.lan2k.org" = {
  #    group = "nginx";
  #    listenHTTP = "0.0.0.0:80";
  #    webroot = null;
  #  };
  #};

  users.users.nginx.extraGroups = [ "acme" ];
  users.users.nginx.group = "nginx";
  users.users.nginx.isSystemUser = true;
  users.groups.nginx = {};

  #services.cockpit = {
  #  enable = true;
  #  port = 9090;
  #  settings = {
  #    WebService = {
  #      AllowUnencrypted = true;
  #    };
  #  };
  #};  

}

