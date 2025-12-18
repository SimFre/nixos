{
  config,
  pkgs,
  sops,
  ...
}:

{
  sops = {
    defaultSopsFile = ./sops.yaml;
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
