{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nixfiles/nixos
  ];

  system.stateVersion = "23.05";
  home-manager.sharedModules = [{
    home.stateVersion = "23.05";
  }];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      extraEntries."0.ubuntu.conf" = ''
        title Ubuntu
        efi /EFI/ubuntu/grubx64.efi
      '';
    };
    timeout = 30;
  };

  networking.hostName = "infinity";

  time.timeZone = "Melbourne/Australia";
  i18n.defaultLocale = "en_AU.UTF-8";

  services.xserver.enable = true;

  nova = {
    profile = "shared";
    substituters.nova.password = "tFH6J!#HhrYc3&^m";
  };

  # NVIDIA
  hardware.nvidia = {
    modesetting.enable = true;

    prime = {
      offload = {
        enable = false;
        enableOffloadCmd = false;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";

      sync.enable = false;
    };
  };

  specialisation = {
    nvidia.configuration = {
      system.nixos.tags = [ "nvidia" ];
      services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
      hardware.nvidia.prime = {
        sync.enable = lib.mkForce true;
      };
    };
  };

  services.xserver.videoDrivers = [ "modesetting" ];
  services.switcherooControl.enable = true;
  # GDM seems to have weird issues on Wayland when the NVIDIA driver is enabled.
  # - The login screen restarts once after logging in
  # - VSCode(ium) hangs unless it is ran on the NVIDIA GPU
  nova.desktop.wayland.enable = false;

  # Hardware video acceleration and compute
  hardware.opengl.extraPackages = with pkgs; [ intel-media-driver intel-compute-runtime ];

  nixpkgs.config.cudaSupport = false;
  nix.settings = lib.mkIf config.nixpkgs.config.cudaSupport {
    substituters = [ "https://cuda-maintainers.cachix.org" ];
    trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=" ];
  };

  hardware.enableAllFirmware = true;

  # services.xserver.screenSection = ''
  #   Option "metamodes" "DP-1: 1920x1080_240 +1920+0, HDMI: 1920x1080_60 +0+0"
  # '';


  home-manager.users.nova = {
    programs.vscode.enable = lib.mkForce false;

    dconf.settings."org/gnome/shell".favorite-apps = [ "code.desktop" ];

    home.packages = with pkgs; [
      vscode
      jetbrains.pycharm-professional
      slack
      obs-studio
      google-chrome
      vim
      lshw
      spotify
    ];
  };
}
