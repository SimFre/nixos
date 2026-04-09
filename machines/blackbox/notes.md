
# 

# The "In the Wild" To-Do List

## Create TPM keys

On a clean machine, run;
```bash
nix-shell -p sbctl
# Create a directory for your new Secure Boot PKI
mkdir -p ~/my-secure-boot-keys
cd ~/my-secure-boot-keys

# Generate the keys (this creates PK, KEK, and db keys)
sbctl create-keys

This will generate a set of files in /var/lib/sbctl (by default). You want to copy the entire folder to your secure USB drive.

Move: /var/lib/sbctl/* → USB_DRIVE/secureboot/

Now, plug the USB into your target "In the Wild" appliance.

Step 1: Move keys to the system
NixOS's Lanzaboote module expects the keys to live in /etc/secureboot by default.
Bash

sudo mkdir -p /etc/secureboot
sudo cp -r /run/media/user/USB/secureboot/* /etc/secureboot/
sudo chmod 700 /etc/secureboot

Step 2: Enter Setup Mode
Reboot your Lenovo/Dell and enter the BIOS. Look for Secure Boot settings and select "Reset to Setup Mode" or "Delete Platform Key". This puts the hardware in a state where it's "begging" for a new owner.

Step 3: Enroll the keys
Back in NixOS on the target machine:
Bash

# Verify the machine is in Setup Mode
sbctl status

# Enroll the keys you brought over on the USB
sudo sbctl enroll-keys --microsoft


```

## Phase 1: Hardware Preparation

 - [ ] Update BIOS/firmware to enable TPM 2.0
 - [ ] BIOS Settings:
       Set a strong Supervisor Password.
       Disable F12 Boot Menu and all USB boot options.
       Enable Secure Boot (Custom Mode / Expert Mode).
       Enable Chassis Intrusion (set to "Halt on Intrusion" or "On-Log").
       Enable TME (Total Memory Encryption)
       Disable the AMT/ME features in the BIOS and set a strong, unique ME password.
   [ ] Physical: Unplug the internal speaker if you want total silence.

## Phase 2: NixOS Installation
 - [ ] Boot a standard NixOS installer.
 - [ ] ZFS Setup: Create your pool with -O encryption=aes-256-gcm -O keyformat=passphrase.
 - [ ] Lanzaboote: Run `sbctl create-keys` and enroll them in the UEFI.
 - [ ] Secrets: Create the /etc/wpa_supplicant.conf and Wireguard keys before the first boot.

## Phase 3: The "Seal"
 - [ ] Perform your first boot.
 - [ ] TPM Sealing: Bind your ZFS key to the hardware state:
       `systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 /dev/nvme0n1p2`
 - [ ] Test: Run acpi_listen, flip the chassis lid, and ensure the machine
       powers off instantly.
 - [ ] Test: Test SSH to port 2222 to see if it's possible to release the lock
       via either TPM or manually enter pass phrase.
 - Audit the Nix Store: Run `nix-store --query --references /run/current-system` to
   ensure no plain-text secrets are accidentally world-readable in the store.

# Todo / FIXME
Investigate me_cleaner and Intel AMT WebUI
vPro gives me Hardware KVM access. I can see the screen and inject keyboard
events below the level where your NixOS "No-Input" rules live. I can force a
reboot and redirect the boot process to a remote ISO I host on the network.

Inside your Lenovo’s chipset is a tiny, independent processor called the Intel Management Engine (ME).
Independent Power: It runs as long as the power cable is plugged in, even if the PC is "off."
Direct Hardware Hooks: It has a "side-car" connection to the network card and the integrated GPU. This allows it to "tap" the video signal and inject keyboard/mouse inputs directly into the hardware stream.

When you enable KVM redirection in the vPro settings (often called the MEBx menu), the Intel ME starts a mini VNC server.
Out-of-Band (OOB): You can connect to the machine's IP address on port 16994 (or 5900) using a tool like MeshCommander or a VNC viewer.

    BIOS Access: You can see the screen from the moment the power is pressed, allowing you to change BIOS settings or select a boot device remotely.

    ISO Redirection (IDE-R): Much like IPMI, you can "mount" an ISO file from your laptop onto the remote Lenovo, making the Lenovo think you’ve plugged in a physical USB thumb drive.

The "Headless" Gotcha

If you plan to run this Lenovo without a monitor plugged in, you might hit a snag. Because vPro "taps" the integrated GPU's signal, some older versions of the firmware won't initialize the video buffer if it doesn't detect a physical monitor.

    The Fix: You may need a small "HDMI Dummy Plug" (also called a Ghost Plug) to trick the GPU into thinking a monitor is attached so you can see the KVM output.


# Recovery

In a "Trust No One" architecture, the line between secure and permanently locked
out is razor-thin. If your onion service goes down or your ISP blocks Tor, that
machine becomes a brick unless you have a "Break Glass" procedure. To keep this secure,
you need to separate your Operational Key (Tor) from your Recovery Key (Physical).

## 1. The Recovery Strategy: TPM-Sealed Local Key

Rather than typing a 64-character password (which we've disabled by killing the TTY
anyway), you should use the TPM 2.0 chip as a secondary unlock mechanism that only
works if the hardware is untampered.

### How it works:

  - You store a secondary, high-entropy key file in a small, unencrypted "Recovery"
    partition or even within the signed initrd.

  - You seal that key to the TPM using specific PCR registers (0, 2, 7, 12).

  - The Catch: The TPM will only release this key if the BIOS, Secure Boot state,
    and Kernel have not changed.

If Tor fails: The initrd script tries the onion service. If it fails, it asks
the TPM for the local recovery key. If the box hasn't been opened or tampered
with, the TPM hands over the key, and the system boots.

## 2. Backing Up the "Master" ZFS Key

Since you are using Native ZFS Encryption, you must have a physical backup of the raw key.

  - Generate it offline: Create the key on a secure machine, not the appliance.
  - Physical Copy: Print the key as a QR Code or Hex string and put it in a physical safe.
  - Digital Copy: Store it in a LUKS-encrypted USB drive or a dedicated Password Manager.

## 3. The "Break Glass" Procedure

If the appliance is "in the wild" and refuses to boot (Tor is down AND the TPM is locked
because someone tried to open the case), you need a way to recover it without wiping the data.

### Step 1: The Maintenance Key

In your NixOS config, you can define a "Maintenance Mode" that only triggers if
a specific, signed USB drive is inserted.

  - You carry a USB drive containing a GPG-signed script.
  - The initrd verifies the signature.
  - If valid, it ignores the "No Keyboard" rule and lets you type a recovery password.

### Step 2: The SSH "Initrd" Backdoor

NixOS allows you to run a tiny SSH server (dropbear) inside the initrd before the disk is even decrypted.

```nix
boot.initrd.network.ssh = {
  enable = true;
  port = 2222;
  authorizedKeys = [ "ssh-ed25519 AAAAC3..." ];
  hostKeys = [ "/etc/secrets/initrd_ssh_host_ed25519_key" ];
};
```

If the automated Tor fetch fails, you can SSH into the boot process via a local
laptop, manually provide the key, and watch the system finish booting.


# Why doas over sudo?

For an appliance, `doas` (originally from OpenBSD) is preferred. It has a
significantly smaller codebase than sudo, meaning a smaller attack surface.
In a "hardened" build, reducing the lines of C-code running with
setuid root is a huge win.

