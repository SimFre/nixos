{ ... }:
{
  users  = {
    users = {
      laban = {
        isNormalUser = true;
	description = "Simon Fredriksson";
        extraGroups = [ "wheel" "networkmanager" ];
        openssh = {
          authorizedKeys = {
            keys = [
	      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI"
            ];
          };
        };
      };
    };
  };
}
