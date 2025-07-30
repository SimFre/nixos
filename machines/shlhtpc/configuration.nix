{
  config,
  lib,
  pkgs ? import <nixpkgs-unstable> { },
  ...
}:
let
  kodi-with-addons = pkgs.kodi-wayland.withPackages (kodiPkgs: with kodiPkgs; [
    inputstream-adaptive
    bluetooth-manager
  ]);
in
{
  imports = [
    ./hardware-configuration.nix
    ../../common/common.nix
    ../../common/desktop.nix
    #../../common/plasma6.nix
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
    kernelPackages = pkgs.linuxPackages_zen;
  };
  zramSwap.enable = true;

  networking = {
    hostName = "shlhtpc";
    hostId = "eff2b131";
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
    extraGroups = [ "video" "audio" "input" "networkmanager" ];
  };

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
  nixpkgs.config.allowBroken = true;
  environment.systemPackages = with pkgs; [
    jitsi-meet-electron
    rustdesk
    jellyfin-media-player
    kodi-cli
    kodi-with-addons
    (python3.withPackages (ps: with ps; [ pillow ]))
	#(kodi.withPackages (kodiPkgs: with kodiPkgs; [
	#	jellycon
	#	pvr-iptvsimple
	#	netflix
	#	svtplay
	#	youtube
	#]))
  ];

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

  nixpkgs.config.permittedInsecurePackages = [
    "python3.12-youtube-dl-2021.12.17"
  ];


  # Enable VNC for visual remote control. A random password
  # is generated on first boot and stored in a file.
  # View it with `cat /var/lib/vnc/vnc-password.txt`
  services.xrdp.enable = true;
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

  services.cage.user = "htpc";
  services.cage.extraArguments = [ "-m" "last" ];
  services.cage.program = "${kodi-with-addons}/bin/kodi-standalone";
  services.cage.enable = true;

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
        ssh-keygen -t ecdsa -N "" -f /home/htpc/.ssh/id_ecdsa
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
        volumes = [ "/var/lib/hass:/config" ];
        environment.TZ = config.time.timeZone;
        image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
        extraOptions = [ 
          "--network=host"
          #"--device=/dev/ttyACM0:/dev/ttyACM0"  # Example, change this to match your own hardware
        ];
        # restart = "always";
      };
    };
  };
}
