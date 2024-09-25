{ name, pkgs, lib, config, ... }: {
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.system = "aarch64-linux";

  boot.loader.grub.configurationLimit = 1;

  nomadNode = {
    enable = true;
    enableSeaweedFsVolume = false;
  };

  services.nomad.settings = {
    datacenter = "frankfurt-oci";
    client = {
      node_class = "control-plane";
      node_pool = "control-plane";
      cpu_total_compute = 2 * 2000;
    };

    server = {
      enabled = true;
      server_join = {
        retry_join = [
          "inst-ad2ir-control"
          "inst-hqswv-control"
          "inst-kzsrv-control"
        ];
        retry_max = 0;
        retry_interval = "15s";
      };
    };
  };

  consulNode.server = true;

  # to figure out ARM CPU clock speed in Nomad
  environment.systemPackages = with pkgs; [ dmidecode ];

  system.stateVersion = "24.05";
}

