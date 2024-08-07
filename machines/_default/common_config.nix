{ pkgs, lib, flakeInputs, ... }:
{

  security.pki.certificateFiles = [
    "${flakeInputs.self}/certs/root_2024_ca.crt"
  ];


  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    gc.automatic = true;
    gc.options = "--delete-older-than 15d";
    gc.dates = "daily";
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "@wheel" ];
      trusted-users = [ "root" "@wheel" ];
    };
  };

  users.users.cottand = {
    isNormalUser = true;
    description = "nico";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };

  # noop, but here for future reference in case I want to do binary caches again
  cottand.seaweedBinaryCache = {
    uploadPostBuild = false;
    useSubstituter = false;
    cacheUrl = "s3://nix-cache?profile=cache-upload&endpoint=10.10.0.1:13210&scheme=http";
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 1 * 1024;
  }];

  services.openssh.enable = true;
  services.sshguard.enable = true;
  networking.enableIPv6 = true;
  programs.zsh.enable = true;

  # Enable Oh-my-zsh
  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "fishy";
    plugins = [ "git" "sudo" "docker" "systemadmin" ];
  };

  users.users."cottand".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGes99PbsDcHDl3Jwg4GYqYRkzd6tZPH4WX4/ThP//BN"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJ7FM2wEuWoUuxRkWnP6PNEtG+HOcwcZIt6Qg/Y1jhk nico.dc@outlook.com"
    # nico-xps key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3AKGuE56RZiMURZ4ygV/BrSwrq6Ozp46VVm30PouPQ"
  ];

  programs.fish.enable = true;
  users.users.root.shell = pkgs.fish;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJ7FM2wEuWoUuxRkWnP6PNEtG+HOcwcZIt6Qg/Y1jhk nico.dc@outlook.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3AKGuE56RZiMURZ4ygV/BrSwrq6Ozp46VVm30PouPQ"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcVLH2EH/aAkul8rNWrDoBTjUTL3Y+6vvlVw5FSh8Gt nico.dc@outlook.com-m3"
  ];

  environment.systemPackages = with pkgs; [
    wireguard-tools
    python3 # required for sshuttle
    seaweedfs # makes 'weed' bin available
    pciutils # for setpci, lspci
    dig
    iw
    vim
    htop
    s-tui # power top
    nmap
    traceroute

    vault-bin # for retrieving secrets
  ];

  # Set your time zone.
  time.timeZone = lib.mkDefault "Europe/London";
  networking.timeServers = [ "time.google.com" ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # see https://blog.thalheim.io/2022/12/31/nix-ld-a-clean-solution-for-issues-with-pre-compiled-executables-on-nixos/
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      zlib
      nss
      openssl
      curl
      wget
      expat
    ];
  };
}
