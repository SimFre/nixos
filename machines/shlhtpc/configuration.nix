{ config, lib, pkgs, ... }:
let
  secrets = import ./secrets.nix;
  extvpnSubnet4 = "10.89.0.0/24";     # your stable Podman subnet
  extvpnIfName  = "podman-extvpn";
  lanSubnets4 = [ "192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12" ];
  tailscaleSubnets4 = [ "100.64.0.0/10" ];

  # IPv6: include your LAN ULA (if any) + Tailscale ULA (you already have fd7a:115c:a1e0::/48)
  lanSubnets6 = [ "fd00::/8" "fe80::/10" ];
  tailscaleSubnets6 = [ "fd7a:115c:a1e0::/48" ];

  vpnTable = 51820;
  pbrMark = "0x1";
in
{
  # WireGuard interface. NixOS module supports allowedIPsAsRoutes + fwMark + table.
  # https://mynixos.com/options/networking.wireguard.interfaces.%3Cname%3E)
  # https://wiki.nixos.org/wiki/WireGuard
  networking.wireguard.interfaces.wg-extvpn = {
    ips = [
      secrets.vpnAddress4
      secrets.vpnAddress6
    ];

    #listenPort = 51820; # optional; can be omitted for client
    privateKey = secrets.vpnPrivateKey;

    # Don't let NixOS add AllowedIPs routes automatically to main table
    # https://mynixos.com/options/networking.wireguard.interfaces.%3Cname%3E
    allowedIPsAsRoutes = false;
    peers = [
      {
        publicKey = secrets.vpnPublicKey;
        endpoint  = secrets.vpnEndpoint;
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        persistentKeepalive = 25;
      }
    ];
  };

  # (Optional) give the route table a name in /etc/iproute2/rt_tables.d/
  networking.iproute2.enable = true;
  networking.iproute2.rttablesExtraConfig = ''
    ${toString vpnTable} extvpn
  '';

  # Set up the Podman network
  systemd.services.podman-network-extvpn = {
    description = "Create podman network for external VPN with stable subnet";
    wantedBy = [ "multi-user.target" ];
    after = [ "podman.service" "network-online.target" ];
    wants = [ "podman.service" "network-online.target" ];

    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.podman}/bin/podman network exists extvpn-net || \
        ${pkgs.podman}/bin/podman network create \
          --subnet ${extvpnSubnet4} \
          --interface-name podman-extvpn \
          extvpn-net
    '';
  };

  # Create policy routes + rules once WG is up
  systemd.services.extvpn-pbr = {
    description = "Policy based routing: egress via WireGuard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "wireguard-wg-extvpn.service" ];
    wants = [ "network-online.target" "wireguard-wg-extvpn.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail
      # Default route in the VPN routing table goes via wg-extvpn
      ${pkgs.iproute2}/bin/ip route replace default dev wg-extvpn table ${toString vpnTable}
      ${pkgs.iproute2}/bin/ip -6 route replace default dev wg-extvpn table ${toString vpnTable}

      # Packets with mark 0x1 use the VPN table
      # Make rule idempotent: delete if exists, then add.
      ${pkgs.iproute2}/bin/ip rule del fwmark ${pbrMark} lookup ${toString vpnTable} priority 1000 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule add fwmark ${pbrMark} lookup ${toString vpnTable} priority 1000
      ${pkgs.iproute2}/bin/ip -6 rule del fwmark ${pbrMark} lookup ${toString vpnTable} priority 1000 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip -6 rule add fwmark ${pbrMark} lookup ${toString vpnTable} priority 1000
    '';

    preStop = ''
      # Clean up (safe even if not present)
      ${pkgs.iproute2}/bin/ip rule del fwmark ${pbrMark} lookup ${toString vpnTable} priority 1000 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip -6 rule del fwmark ${pbrMark} lookup ${toString vpnTable} priority 1000 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip route del default dev wg-extvpn table ${toString vpnTable} 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip -6 route del default dev wg-extvpn table ${toString vpnTable} 2>/dev/null || true
    '';
  };

  # nftables rules:
  # - mark traffic arriving from podman-extvpn interface
  # - EXCEPT if destination is LAN or Tailscale
  # - NAT marked traffic out wg-extvpn
  # nftables can match iifname/oifname and set meta mark.
  # https://wiki.nftables.org/wiki-nftables/index.php/Matching_packet_metainformation
  networking.nftables.enable = true;
  networking.nftables.ruleset = ''
    table inet extvpn_pbr {
      set lan4 {
        type ipv4_addr;
        flags interval;
        elements = { ${lib.concatStringsSep ", " lanSubnets4} }
      }
      set ts4 {
        type ipv4_addr;
        flags interval;
        elements = { ${lib.concatStringsSep ", " tailscaleSubnets4} }
      }
      set pod4 {
        type ipv4_addr;
        flags interval;
        elements = { ${extvpnSubnet4} }
      }

      set lan6 {
        type ipv6_addr;
        flags interval;
        elements = { ${lib.concatStringsSep ", " lanSubnets6} }
      }
      set ts6 {
        type ipv6_addr;
        flags interval;
        elements = { ${lib.concatStringsSep ", " tailscaleSubnets6} }
      }

      chain prerouting {
        type filter hook prerouting priority mangle; policy accept;

        # Only consider packets coming from the extvpn bridge
        meta iifname "${extvpnIfName}" ip daddr @lan4 return
        meta iifname "${extvpnIfName}" ip daddr @ts4  return
	meta iifname "${extvpnIfName}" ip daddr @pod4 return
        meta iifname "${extvpnIfName}" ip6 daddr @lan6 return
        meta iifname "${extvpnIfName}" ip6 daddr @ts6  return
        meta iifname "${extvpnIfName}" meta mark set ${pbrMark}
      }

      chain forward {
        type filter hook forward priority filter; policy accept;
        # Kill-switch: if it's marked VPN traffic but not going to wg-extvpn, drop it (prevents leaks).
        meta mark ${pbrMark} meta oifname != "wg-extvpn" drop
      }

      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;

        # NAT only marked traffic out of the WG interface
        meta mark ${pbrMark} meta oifname "wg-extvpn" masquerade
      }
    }
  '';

  imports = [
    ./hardware-configuration.nix
    ./plymouth.nix
    ../../common/common.nix
    ../../common/desktop.nix
    #../../common/plasma6.nix
  ];

  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-25.05";
    dates = "weekly";  # Specify update frequency
    allowReboot = false;  # Set to true if you want automatic reboots
  };

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
    #kernelPackages = pkgs.linuxPackages_lts;
  };
  zramSwap.enable = true;

  networking = {
    hostName = "shlhtpc";
    hostId = "eff2b131";
    hosts = { "fd7a:115c:a1e0::4" = [ "gau" ]; };
    firewall.enable = false;
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
        "--accept-dns=false"
      ];
    };
  };

  # User configuration
  users.users.htpc = {
    description = "HTPC";
    isNormalUser = true;
    extraGroups = [ "video" "render" "audio" "input" "networkmanager" ];
    linger = true;
  };

  environment.systemPackages = with pkgs; [
     libva-utils
     intel-gpu-tools
  ];

  # Enable Kodi
  #services.kodi.enable = true;
  #services.kodi.pvrIptvSimple.enable = true;
  #services.kodi.plugins = [
  #  "plugin.video.netflix"
  #  "plugin.video.svtplay"
  #  "plugin.video.youtube"
  #  "plugin.video.jellycon"
  #  "plugin.video.pvr.iptvsimple"
  #];

  # Install kodi-cli
  #nixpkgs.config.allowBroken = true;
  #environment.systemPackages = with pkgs; [
  #  #jitsi-meet-electron
  #  #rustdesk
  #  #jellyfin-media-player
  #  #kodi-cli
  #  #kodi-with-addons
  #  alsa-utils
  #  pavucontrol
  #  #(python3.withPackages (ps: with ps; [ pillow ]))
  #  chromium
  #  unclutter
  #	#(kodi.withPackages (kodiPkgs: with kodiPkgs; [
  #	#	jellycon
  #	#	pvr-iptvsimple
  #	#	netflix
  #	#	svtplay
  #	#	youtube
  #	#]))
  #];

  # Autostart Kodi
  #services.xserver.enable = true;
  #services.xserver.displayManager.startx.enable = true;
  #services.xserver.desktopManager.kodi.enable = true;
  #services.xserver.displayManager.lightdm.greeter.enable = false;
  #services.displayManager.autoLogin.user = "htpc";
  #systemd.user.services.kodi = {
  #  description = "Kodi Media Center";
  #  wantedBy = [ "default.target" ];
  #  serviceConfig = {
  #    ExecStart = "${pkgs.kodi}/bin/kodi";
  #    Restart = "always";
  #  };
  #};

  #nixpkgs.config.permittedInsecurePackages = [
  #  "python3.12-youtube-dl-2021.12.17"
  #];


  # Home Assistant dashboard
  services.cage.user = "htpc";
  services.cage.extraArguments = [ "-m" "last" ];
  services.cage.program = "/run/current-system/sw/bin/chromium --app=http://localhost:8123 --kiosk --no-first-run --disable-infobars --disable-translate --disable-pinch";
  services.cage.enable = true;

  # services.xserver.enable = true;
  # services.displayManager.autoLogin.enable = true;
  # services.displayManager.autoLogin.user = "htpc";
  # services.xserver.libinput.enable = true;
  # services.xserver.libinput.mouse.disableWhileTyping = true;
  # services.xserver.windowManager.openbox.enable = true;
  # services.xserver.displayManager.sessionCommands = ''
  #   xset s off
  #   xset -dpms
  #   xset s noblank
  #   unclutter &
  #     chromium --app=https://homeassistant.local:8123 --kiosk --no-first-run --disable-infobars --disable-translate --disable-pinch
  # '';


  # Enable VNC for visual remote control. A random password
  # is generated on first boot and stored in a file.
  # View it with `cat /var/lib/vnc/vnc-password.txt`
  #services.xrdp.enable = true;
  #services.xserver.vnc.enable = true;
  #services.xserver.vnc.port = 5900;
  #services.xserver.vnc.passwordFile = "/var/lib/vnc/vnc-password.txt";
  #systemd.services.generate-vnc-password = {
  #  description = "Generate VNC password if missing";
  #  wantedBy = [ "multi-user.target" ];
  #  serviceConfig = {
  #    Type = "oneshot";
  #    ExecStart = ''
  #      if [ ! -f /var/lib/vnc/vnc-password.txt ]; then
  #        pw=$(head -c 12 /dev/urandom | base64)
  #        mkdir -p /var/lib/vnc
  #        echo "$pw" > /var/lib/vnc/vnc-password.txt
  #        chmod 600 /var/lib/vnc/vnc-password.txt
  #      fi
  #    '';
  #  };
  #};

  # Enable Bluetooth manager
  hardware.bluetooth.enable = true; 
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # For Home Manager
  # home.file.widevine-lib.source = "${pkgs.unfree.widevine-cdm}/share/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so";
  # home.file.widevine-lib.target = ".kodi/cdm/libwidevinecdm.so";
  # home.file.widevine-manifest.source = "${pkgs.unfree.widevine-cdm}/share/google/chrome/WidevineCdm/manifest.json";
  # home.file.widevine-manifest.target = ".kodi/cdm/manifest.json";

  #services.cage.user = "htpc";
  #services.cage.extraArguments = [ "-m" "last" ];
  #services.cage.program = "${kodi-with-addons}/bin/kodi-standalone";
  #services.cage.enable = true;

  # Unmute HDMI audio at startup
  systemd.services.unmute-hdmi = {
    enable = true;
    description = "Unmute HDMI audio at startup";
    wantedBy = [ "multi-user.target" ];

    unitConfig = {
      After = [ "sound.target" ];
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.runtimeShell} -c \"sleep 15 && ${pkgs.alsa-utils}/bin/amixer -c 0 set 'IEC958',0 unmute\"";
    };
  };

  # Generate SSH keypair for HTPC on first boot using ECDSA
  systemd.services.generate-ssh-key = {
    enable = true;
    script = ''
      if [ ! -f /home/htpc/.ssh/id_ecdsa ]; then
        mkdir -p /home/htpc/.ssh
        ${pkgs.openssh}/bin/ssh-keygen -t ecdsa -N "" -f /home/htpc/.ssh/id_ecdsa
        chown -R htpc:users /home/htpc/.ssh
        chmod 700 /home/htpc/.ssh
      fi
    '';
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

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
        volumes = [
          "/var/lib/hass:/config"
          "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket" # Mount DBus socket
          "/etc/machine-id:/etc/machine-id" # Mount machine ID for DBus
        ];
        environment = {
          TZ = config.time.timeZone;
          DBUS_SYSTEM_BUS_ADDRESS = "unix:path=/var/run/dbus/system_bus_socket"; # Set DBus address
        };
        image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
        extraOptions = [ 
          "--network=host"
          #"--device=/dev/ttyACM0:/dev/ttyACM0"  # Example, change this to match your own hardware
        ];
        # restart = "always";
      };
      containers.dispatcharr = {
        volumes = [
          "/var/lib/dispatcharr:/data"
        ];
        environment = {
	  DISPATCHARR_ENV = "aio";
	  REDIS_HOST = "localhost";
          CELERY_BROKER_URL = "redis://localhost:6379/0";
	  DISPATCHARR_LOG_LEVEL = "info";
	  LIBVA_DRIVER_NAME = "iHD";
        };
        ports = [
          "9191:9191/tcp"
        ];
	#devices = {
	#  "/dev/dri/renderD128": "/dev/dri/renderD128"
	#  "/dev/kfd": "/dev/kfd"
	#};
        image = "ghcr.io/dispatcharr/dispatcharr:latest"; # Warning: if the tag does not change, the image will not be updated
        extraOptions = [
          #"--network=host"
	  "--network=extvpn-net"
	  "--device=/dev/dri:/dev/dri"
	  "--group-add=render"
	  "--group-add=video"
          #"--device=/dev/ttyACM0:/dev/ttyACM0"  # Example, change this to match your own hardware
        ];
        # restart = "always";
      };
    };
  };
  systemd.services."podman-dispatcharr".after = [ "podman-network-extvpn.service" "extvpn-pbr.service" ];
  systemd.services."podman-dispatcharr".wants = [ "podman-network-extvpn.service" "extvpn-pbr.service" ];

  #home = {
  #  username = "htpc";
  #  homeDirectory = "/home/htpc";
  #  stateVersion = "25.05";
  #};

  # Kodi GBM service
  #systemd.user.enable = true;
  #systemd.user.services.kodi = {
  #  Unit.Description = "Kodi media center";
  #  Install = {
  #    WantedBy = ["default.target"];
  #  };
  #  Service = {
  #    Type = "simple";
  #    ExecStart = "${kodi-with-addons}/bin/kodi-standalone";
  #    Restart = "always";
  #    TimeoutStopSec = "15s";
  #    TimeoutStopFailureMode = "kill";
  #  };
  #};

  #programs.kodi = {
  #  enable = true;
  #  package = kodi-with-addons;
  #  # addonSettings = {};
  #  settings = {
  #    services = {
  #      devicename = "viewscreen";
  #      esallinterfaces = "true";
  #      webserver = "true";
  #      webserverport = "8080";
  #      webserverauthentication = "false";
  #      zeroconf = "true";
  #    };
  #  };
  #};

  #programs.home-manager.enable = true;

  services.znapzend = {
    enable = true;
    autoCreation = true;
    zetup = {
      "npool" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y%m%d%H%M%SZ";
        destinations = {
          "gau" = {
            dataset = "bigdata/backups/shlhtpc";
            plan = "1w=>1d";
            host = "zfsshlhtpc@gau";
            postsend = "/run/current-system/sw/bin/curl -s ${secrets.znapzend_reporturl}";
          };
        };
      };
    };
  };


}
