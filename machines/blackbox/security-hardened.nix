{ config, pkgs, lib, ... }:

{
  # --- 1. BOOT & ENCRYPTION ---
  boot.loader.systemd-boot.enable = lib.mkForce false; 
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  boot.initrd = {
    systemd.enable = true;
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ "iwlwifi" ]; # Drivers for Intel WiFi
    packages = [ pkgs.wpa_supplicant pkgs.tor pkgs.curl ];
    secrets."/etc/wpa_supplicant/wpa_supplicant.conf" = ./secrets/wifi.conf;

    # Include necessary tools in the RAM disk
    extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.wpa_supplicant}/bin/wpa_supplicant
      copy_bin_and_libs ${pkgs.tor}/bin/tor
      copy_bin_and_libs ${pkgs.curl}/bin/curl
      
      # We create a custom script for the 'shell' above
      cat <<EOF > /bin/zfs-unlock-menu
#!/bin/sh
  echo "--- Appliance Recovery Menu ---"
  echo "1) Load ZFS keys from local TPM"
  echo "2) Enter ZFS passphrase manually"
  echo "3) Reboot"
  read -p "Selection: " choice
  case \$choice in
    1) zfs load-key -a ;; # You'd point this to your TPM-sealed key path
    2) systemd-ask-password ;;
    3) reboot ;;
  esac
EOF
      chmod +x /bin/zfs-unlock-menu
    '';
    
    # Dropbear SSH for Stage-1 Recovery
    network.ssh = {
      enable = true;
      port = 2222;
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI" ];
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      shell = "/bin/zfs-unlock-menu";
    };

    # The Script to fetch ZFS keys via Tor
    network.postCommands = ''
      echo "Starting WiFi and Tor..."
      wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
      tor --RunAsDaemon 1
      sleep 20
      curl --proxy socks5h://127.0.0.1:9050 -o /tmp/zfs.key http://your-onion-service.onion/key
      zfs load-key -a < /tmp/zfs.key
      rm /tmp/zfs.key
    '';
  };

  # --- 2. KERNEL & TTY HARDENING ---
  boot.kernelParams = [ 
    "quiet"
    "loglevel=0"
    "kbd.off=1"     # Disables the kernel-level keyboard driver entirely
    "console=ttyS0" # Redirect console to serial
    "panic=10" 
  ];
  
  # Disable local TTYs entirely
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  # Adjust 'event' based on 'acpi_listen' output for your specific machine
  services.acpid.handlers.chassis_open = {
    event = "button/lid.*"; 
    action = "systemctl start chassis-panic.service";
  };

  # --- 4. USBGUARD ---
  services.usbguard = {
    enable = true;
    defaultPolicy = "block"; 
    # Allow only your specific Yubikey or Maintenance Keyboard if desired
    # rules = "allow id 1050:0407"; 
  };
}
