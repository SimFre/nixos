{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      firefox
      brave
      discord
      owncloud-client
      spotify
      ghostty
      kitty
      keepassxc
      libreoffice-fresh
      vscode.fhs
      nixfmt-rfc-style

    ];
  };

  powerManagement = {
    enable = true;
  };

  fonts.packages = with pkgs; [
    meslo-lgs-nf
  ];
  services = {
    xserver = {
      xkb = {
        layout = "se";
        variant = "";
      };
    };
    pulseaudio = {
      enable = false;
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = {
        enable = true;
      };
    };
  };

  programs = {
    xwayland.enable = true;
    direnv.enable = true;
  };

  # GNOME
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # DEEPIN
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.deepin.enable = true;


}
