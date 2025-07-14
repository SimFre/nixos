{ pkgs, ... }:
{
  #imports = [ ./users.nix ./stylix.nix ];
  imports = [ ./users.nix ];  
  time = {
    timeZone = "Europe/Stockholm";
  };
  networking = {
    timeServers = [ "sth1.ntp.se" "sth2.ntp.se" "gbg1.ntp.se" "gbg2.ntp.se" ];
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_DK.UTF-8";
      LC_IDENTIFICATION = "en_DK.UTF-8";
      LC_MEASUREMENT = "en_DK.UTF-8";
      LC_MONETARY = "en_DK.UTF-8";
      LC_NAME = "en_DK.UTF-8";
      LC_NUMERIC = "en_DK.UTF-8";
      LC_PAPER = "en_DK.UTF-8";
      LC_TELEPHONE = "en_DK.UTF-8";
      LC_TIME = "en_DK.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
  };
  users  = {
    defaultUserShell = pkgs.zsh;
  };
  security = {
    sudo = {
      wheelNeedsPassword = false;
    };
  };
  environment = {
    systemPackages = with pkgs; [
      neovim
      wget
      btop
      dysk
      unzip
      screen
      nmap
      zsh
      zsh-fzf-tab
      zsh-powerlevel10k
      zsh-fzf-history-search
      fzf-zsh
      oh-my-posh
      neofetch
      sops
      git
      ipcalc
      nh
      dust
    ];
  };
  programs = {
    mtr = {
      enable = true;
    };
    neovim = {
      defaultEditor = true;
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    zsh = {
      enable = true;
      promptInit = "eval \"$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/blue-owl.omp.json')\"";
      syntaxHighlighting = {
        enable = true;
      };
      histSize = 10000;
      #history = {
      #  size = 10000;
      #  share = true;
      #};
      enableLsColors = true;
      enableCompletion = true;
      #autosuggestion.enable = true;
    };
    fzf = {
      #enable = true;
      keybindings = true;
      fuzzyCompletion = true;
      #enableZshIntegration = true;
    };
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
      flake = "/home/laban/nixos";
    };
    #git = {
    #  enable = true;
    #  userName = "Simon Fredriksson";
    #  userEmail = "simon@lan2k.org";
    #};
    #oh-my-posh = {
    #  enable = true;
    #  enableZshIntegration = true;
    #  useTheme = "blue-owl";
    #};
  };
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
