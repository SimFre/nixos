{ ... }:
{
  users  = {
    defaultUserShell = pkgs.zsh;
    users = {
      root = {
        hashedPassword = "$6$/quXloWNfT.xdLT8$lc8DODS87x0Eeq/czUsCfsTZggclWysaeEBeE8VB1mojYBtFa7t4HcdYPIFlvaONfkiPFkJn2tYV4YC/9EXwH.";
        openssh = {
          authorizedKeys = {
            keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901" ];
          };
        };
      };
      simfre = {
        hashedPassword = "$6$RIM/z/tXnTu0QRWw$hcvyMXjJR/yrpNNmciGG185We5QORraNa8W8O68Yx8HWqDTTrz106R0NZkKPY58e/gNSRaxe2N69McelsI9G1.";
        isNormalUser = true;
	description = "Simon Fredriksson";
        extraGroups = [ "wheel" "networkmanager" ];
        openssh = {
          authorizedKeys = {
            keys = [
	      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901"
            ];
          };
        };
      };
    };
  };
};
