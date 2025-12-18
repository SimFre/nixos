{
  config,
  pkgs,
  sops,
  ...
}:

{
  imports = [
    <sops-nix/modules/nix-os>  # or
    # If using flakes:
    # inputs.sops-nix.nixosModules.sops
  ];
  sops = {
    defaultSopsFile = ./secrets.enc.yaml;
    age = {
      keyFile = "/root/.config/sops/age/keys.txt";
    };
    # Generate this with: age-keygen -o keys.txt
    generatedKey = {
      # Optional: Automatically generate and manage age key
      enable = true;
      path = "/root/.config/sops/age/keys.txt";
    };
    secrets = {
      "znapzend/reporturl" = { };
      "lan2kdns/key" = { };
    };
  };
}
