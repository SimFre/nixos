{ ... }:
{
  users  = {
    users = {
      root = {
        hashedPassword = "$6$/quXloWNfT.xdLT8$lc8DODS87x0Eeq/czUsCfsTZggclWysaeEBeE8VB1mojYBtFa7t4HcdYPIFlvaONfkiPFkJn2tYV4YC/9EXwH.";
        openssh = {
          authorizedKeys = {
            keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLo+YygGuShRdm6fsOJmESqwfMecX7Kr+zJFNMk6rZI SF20220901" ];
          };
        };
      };
      
      laban = {
        hashedPassword = "$y$j9T$jmMv6ZMHjYgb5PQGTGpMC1$zRH291CADo7bpBU/QFKc054x2YI0G4HM.CsfqffmDL/";
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

      simfre = {
        hashedPassword = "$y$j9T$jmMv6ZMHjYgb5PQGTGpMC1$zRH291CADo7bpBU/QFKc054x2YI0G4HM.CsfqffmDL/";
        isNormalUser = true;
	description = "SimFre";
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
}
