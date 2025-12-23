{ config, lib, pkgs, ... }:

let secrets = import ./secrets.nix;
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../common/common.nix
    ];

  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-25.11";
    dates = "weekly";  # Specify update frequency
    allowReboot = false;  # Set to true if you want automatic reboots
  };

  boot.tmp.cleanOnBoot = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  zramSwap.enable = true;
  networking.hostId = "43ffee12";
  networking.hostName = "caius";
  networking.domain = "lan2k.org";
  networking.firewall.allowedTCPPorts = [ 22 80 443 3001 ];
  networking.hosts = { "fd7a:115c:a1e0::4" = [ "gau" ]; };
  services.openssh.enable = true;
  system.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
      curl -4 "https://update.lan2k.org/?key=${secrets.lan2kdns_key}"
      curl -6 "https://update.lan2k.org/?key=${secrets.lan2kdns_key}"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  environment.systemPackages = with pkgs; [
    nginx
    uptime-kuma
  ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  services.uptime-kuma.enable = true;
  services.nginx = {
    enable = true;
  #  recommendedProxySettings = true;
  #  recommendedTlsSettings = true;
   virtualHosts."uptime.lan2k.org" =  {
     serverName = "uptime.lan2k.org";
     listen = [
       { addr = "0.0.0.0"; port = 80; }
       { addr = "0.0.0.0"; port = 443; ssl = true; }
       { addr = "[::]"; port = 80; }
       { addr = "[::]"; port = 443; ssl = true; }
     ];
     enableACME = true;
     forceSSL = true;
     locations."/" = {
       proxyPass = "http://127.0.0.1:3001";
       proxyWebsockets = true; # needed if you need to use WebSocket
       extraConfig =
         # required when the target is also TLS server with multiple hosts
         "proxy_ssl_server_name on;" +
         # required when the server wants to use HTTP Authentication
         "proxy_pass_header Authorization;"
         ;
     };
   };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "noreply@example.com";
  };

  users.users.nginx.extraGroups = [ "acme" ];
  users.users.nginx.group = "nginx";
  users.users.nginx.isSystemUser = true;
  users.groups.nginx = {};

  # nix.buildMachines = [
  #   {
  #     hostName = "nixbuild.lan2k.org";
  #     sshUser = "remotebuild";
  #     sshKey = "/root/.ssh/remotebuild";
  #     system = "x86_64-linux"; # Adjust according to your system
  #     supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
  #   }
  # ];
  # nix.settings.builders-use-substitutes = true;

  services.tailscale.enable = true;
  services.znapzend = {
    enable = true;
    autoCreation = true;
    zetup = {
      "rpool" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y%m%d%H%M%SZ";
        destinations = {
          "gau" = {
            dataset = "arc2/caius";
            plan = "1w=>1d";
            host = "zfscaius@gau";
            postsend = "/run/current-system/sw/bin/curl -s ${secrets.znapzend_reporturl}";
          };
        };
      };
    };
  };
}

