
# Disk setup

# Wipe everything
zpool labelclear -f /dev/disk/by-id/DISKNAME
wipefs -a /dev/disk/by-id/DISKNAME
sgdisk --zap-all /dev/disk/by-id/DISKNAME

cfdisk

# partition 1: 2GB EFI
# partition 2: 4GB Swap (debatable)
# partition 3: ZFS

# Format the EFI partition
mkfs.vfat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2

# Setting up the ZFS pool
zpool create -o ashift=12 -o autotrim=on tank /dev/disk/by-id/ata-KINGSTON_SUV400S37240G_50026B776B0060D2-part3
zfs set aclmode=passthrough tank
zfs set compression=lz4 tank
zfs set xattr=sa tank
zfs set atime=off tank
zfs set mountpoint=none tank

# Create the root dataset encrypted with passphrase
zfs create \
  -o encryption=on \
  -o keyformat=passphrase \
  -o acltype=posix \
  -o xattr=sa \
  -o atime=off \
  -o overlay=off \
  -o mountpoint=legacy \
  tank/sys

zfs create \
  -o encryption=on \
  -o keyformat=passphrase \
  -o acltype=posix \
  -o xattr=sa \
  -o atime=off \
  -o overlay=off \
  -o mountpoint=legacy \
  tank/var

zfs create \
  -o encryption=on \
  -o keyformat=passphrase \
  -o acltype=posix \
  -o xattr=sa \
  -o atime=off \
  -o overlay=off \
  -o mountpoint=legacy \
  tank/nix

zfs create \
  -o encryption=on \
  -o keyformat=passphrase \
  -o acltype=posix \
  -o xattr=sa \
  -o atime=off \
  -o overlay=off \
  -o mountpoint=legacy \
  tank/home

mount -t zfs tank/sys /mnt
mkdir /mnt/{nix,var,home,boot}
mount /dev/sda1 /mnt/boot
mount -t zfs tank/var /mnt/var
mount -t zfs tank/nix /mnt/nix
mount -t zfs tank/home /mnt/home

# Create the basic config
nixos-generate-config --root /mnt
