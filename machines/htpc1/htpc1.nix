{ config, pkgs, lib, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    #./disko-config.nix
  ];

  system.stateVersion = "24.11";
  system.copySystemConfiguration = true;

  boot.tmp.cleanOnBoot = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  zramSwap.enable = true;
  networking.hostId = "43f33e12";
  networking.hostName = "htpc1";
  networking.domain = "lan2k.org";

  # Configure disk partitions
  fileSystems."/" = {
    device = "/dev/disk/by-label/system"; # Adjust label or use device path
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot"; # Adjust label or use device path
    fsType = "ext4";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/home"; # Separate partition for /home
    fsType = "ext4";
    options = [ "defaults" ];
  };

  swapDevices = [{
    device = "/dev/disk/by-label/swap"; # Optional swap partition
  }];

  # Enable OpenSSH and fetch Woody's public key from GitHub
  services.openssh.enable = true;
  nixpkgs.config.allowUnfree = true;
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901"
    ];
    hashedPassword =
      "$6$/quXloWNfT.xdLT8$lc8DODS87x0Eeq/czUsCfsTZggclWysaeEBeE8VB1mojYBtFa7t4HcdYPIFlvaONfkiPFkJn2tYV4YC/9EXwH.";
  };
  users.users.laban = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [ tree ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901"
    ];
    hashedPassword =
      "$6$RIM/z/tXnTu0QRWw$hcvyMXjJR/yrpNNmciGG185We5QORraNa8W8O68Yx8HWqDTTrz106R0NZkKPY58e/gNSRaxe2N69McelsI9G1.";
  };

  users.users.woody = {
    isNormalUser = true;
    initialPassword = "Bzzbzzbzz43"; # Securely change this
    extraGroups = [ "wheel" ]; # Allows sudo access
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901"
    ];

    #openssh.authorizedKeys.keys = builtins.readFile
    #  (pkgs.fetchurl { url = "https://github.com/SimFre.keys"; });
  };

  # Set keyboard layout to Swedish
  services.xserver.xkb.layout = "se";

  # Set the timezone
  time.timeZone = "Europe/Stockholm";

  # Enable sound
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Set up Gnome with dark theme and auto login
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "woody";

  # Enable dark theme
  environment.sessionVariables.GTK_THEME = "Adwaita-dark";

  # Enable WiFi and configure it to connect to the predefined network
  networking.firewall.enable = false;
  #networking.wireless.enable = true;
  #networking.wireless.networks."Tleilaxu" = { psk = "nonova2006"; };

  # Install required software
  environment.systemPackages = with pkgs; [
    jellyfin-media-player
    vscodium # Open-source alternative to VS Code
    tailscale
    chromium
    rustdesk
    jitsi-meet-electron
    neofetch
    wget
    vim
    firefox
    mtr
    pv
  ];

  # Configure Tailscale using UUID-based authentication key retrieval
  systemd.services.tailscale-autoconnect = {
    enable = true;
    script = ''
      UUID=$(cat /sys/class/dmi/id/product_uuid)
      AUTH_KEY=$(curl -s "https://vpn.lan2k.org/register/$UUID")
      ${pkgs.tailscale}/bin/tailscale up --authkey=$AUTH_KEY --login-server=https://vpn.lan2k.org
    '';
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  # Configure Rustdesk with specified relay server
  systemd.services.rustdesk = {
    enable = true;
    script = ''
      ${pkgs.rustdesk}/bin/rustdesk --relay-server=rustdesk.lan2k.org --unattended
    '';
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  # Generate SSH keypair for Woody on first boot using ECDSA
  systemd.services.generate-ssh-key = {
    enable = true;
    script = ''
      if [ ! -f /home/woody/.ssh/id_ecdsa ]; then
        mkdir -p /home/woody/.ssh
        ssh-keygen -t ecdsa -N "" -f /home/woody/.ssh/id_ecdsa
        chown -R woody:users /home/woody/.ssh
        chmod 700 /home/woody/.ssh
      fi
    '';
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  # Report UUID via curl every 10 minutes (IPv4 and IPv6)
  systemd.services.Lan2kDNSUpdate = {
    enable = true;
    script = ''
      while true; do
        UUID=$(cat /sys/class/dmi/id/product_uuid)
        curl -4 -s "https://update.lan2k.org/?key=$UUID"
        curl -6 -s "https://update.lan2k.org/?key=$UUID"
        sleep 600 # Every 10 minutes
      done
    '';
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  # Periodically refresh Woody's SSH keys from GitHub every hour
  systemd.services.refresh-ssh-keys = {
    enable = true;
    script = ''
      mkdir -p /home/woody/.ssh
      curl -s https://github.com/SimFre.keys > /home/woody/.ssh/authorized_keys
      chown woody:users /home/woody/.ssh/authorized_keys
      chmod 600 /home/woody/.ssh/authorized_keys
    '';
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.timers.refresh-ssh-keys = {
    enable = true;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/60"; # Runs every 60 minutes
      Persistent = true;
    };
  };
}
