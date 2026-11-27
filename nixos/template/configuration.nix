{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/proxmox-image.nix" ];

  proxmox = {
    qemuConf = {
      name = "nixos-template";
      cores = 2;
      memory = 2048;
    };
    cloudInit.defaultStorage = "VM-pool";
  };

  # NixOS's sudoers has no sudoers.d include, so cloud-init's sudo rule would
  # be ignored: the cloud-init user gets sudo through wheel instead.
  services.cloud-init.settings.system_info = {
    distro = "nixos";
    network.renderers = [ "networkd" ];
    default_user = {
      name = "nixos";
      groups = [ "wheel" ];
      lock_passwd = true;
      shell = "/run/current-system/sw/bin/bash";
    };
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };

  services.tailscale.enable = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" ];
  };

  time.timeZone = "UTC";

  system.stateVersion = "26.05";
}
