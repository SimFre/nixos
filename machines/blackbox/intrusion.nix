# 1. Enable the ACPI daemon to listen for hardware events
services.acpid.enable = true;

# 2. Define the 'Panic' script
systemd.services.chassis-panic = {
  description = "Emergency ZFS Key Unload on Hardware Intrusion";
  serviceConfig = {
    Type = "oneshot";
    # The 'Nuclear Option'
    ExecStart = pkgs.writeShellScript "zfs-panic" ''
      echo "HARDWARE INTRUSION DETECTED. PURGING KEYS." | systemd-cat -p crit
      
      # Forcefully unmount all ZFS datasets and unload keys
      # -f forces unmount even if files are open
      ${pkgs.zfs}/bin/zfs unmount -f -a
      ${pkgs.zfs}/bin/zfs unload-key -a
      
      # Clear the keys from RAM (ZFS does this on unload-key, but we'll be sure)
      sync; echo 3 > /proc/sys/vm/drop_caches
      
      # Shut down the machine to prevent Cold Boot attacks
      ${pkgs.systemd}/bin/poweroff
    '';
  };
};

# 3. Link the ACPI event to the service
services.acpid.handlers = {
  chassis_open = {
    event = "button/lid.*"; # ACPI event string varies; check 'acpi_listen'
    action = "systemctl start chassis-panic.service";
  };
};
