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
    ];
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

}
