{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./security-hardened.nix ];

  # --- 1. NETWORKING & VPN ---
  networking.hostName = "blackbox-appliance";
  networking.hostId = "deadbeef"; # Required for ZFS
  
  services.tailscale.enable = true;

  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.xx.xx.xx/32" ];
    privateKeyFile = "/var/lib/wireguard/azire.key";
    peers = [{
      publicKey = "VPN_SERVER_PUBKEY";
      allowedIPs = [ "0.0.0.0/0" ];
      endpoint = "vpn.example.com:51820";
    }];
  };

  # Uptime Kuma (Pushing to your central monitor)
  # Since Kuma is on kuma.example.com via Tailscale, 
  # we use a "Push" monitor script.
  systemd.services.uptime-kuma-ping = {
    description = "Heartbeat to Uptime Kuma";
    after = [ "network-online.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      while true; do
        ${pkgs.curl}/bin/curl -fsS --retry 3 "https://kuma.example.com/api/push/TOKEN?status=up&msg=OK"
        sleep 60
      done
    '';
  };

  # --- 2. NO-INPUT KIOSK ---
  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${pkgs.cog}/bin/cog http://localhost:8080"; # Points to local dash
    extraArguments = [ "-d" ]; # Direct mode
    environment = { "WLR_LIBINPUT_NO_DEVICES" = "1"; };
    # By setting WLR_LIBINPUT_NO_DEVICES=1, the display server essentially doesn't
    # load the drivers required to process keystrokes. Even if a "Rubber Ducky" is
    # plugged in, the GUI will ignore it.
  };

  users.users.kiosk = { isNormalUser = true; group = "kiosk"; };
  users.groups.kiosk = {};

  # --- 3. PRIVILEGE ESCALATION ---
  security.sudo.enable = false;
  security.doas = {
    enable = true;
    extraRules = [{
      users = [ "admin" ];
      noPass = false;
    }];
  };

  system.stateVersion = "23.11";
}

