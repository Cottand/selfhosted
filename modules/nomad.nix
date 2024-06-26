# sets up a Nomad node with options to run specifically in the mesh.dcotta.eu fleet
# binds specifically to wg-mesh interface

# TODO add assertion for checking for wg-mesh

{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.nomadNode;
  seaweedVolumePath = "/seaweed.d/volume";
in
{

  ## interface
  options = {
    nomadNode = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      enableSeaweedFsVolume = mkOption {
        type = types.bool;
        description = "Whether to make this nomad client capable of hosting a SeaweedFS volume";
      };

      extraSettingsText = mkOption {
        type = types.str;
        default = "";
        description = "Extra settings as HCL";
        example = ''
          server {
              enabled = false
              bootstrap_expect = 3
              server_join {
                  retry_join = [ "10.10.0.1", "10.10.2.1" ]
                  retry_max = 3
                  retry_interval = "15s"
              }
          }
        '';
      };
    };
  };
  ## implementation
  config = mkIf cfg.enable {
    environment.etc = {
      "nomad/config/client.hcl".text = (builtins.readFile ./defaultNomadConfig/client.hcl);
      "nomad/config/server.hcl".text = (builtins.readFile ./defaultNomadConfig/server.hcl);
      "nomad/config/extraSettings.hcl".text = cfg.extraSettingsText;

      # necessary in order to copy files over to etc/ssl/certs (not symlink) so that volumes can mount these dirs
      "ssl/certs/ca-certificates.crt".mode = "0644";
      "ssl/certs/ca-bundle.crt".mode = "0644";
      "pki/tls/certs/ca-bundle.crt".mode = "0644";
    };


    systemd.tmpfiles.rules = mkIf cfg.enableSeaweedFsVolume [
      "d ${seaweedVolumePath} 1777 root root -"
    ];

    systemd.services.nomad.restartTriggers = [
      config.environment.etc."nomad/config/client.hcl".text
      config.environment.etc."nomad/config/server.hcl".text
      config.environment.etc."nomad/config/extraSettings.hcl".text
    ];
    systemd.services.nomad.after = [
      "wg-quick-wg-mesh.service"
    ];

    vaultSecrets =
      let
        destDir = "/opt/nomad/tls";
        secretPath = "nomad/infra/tls";
      in
      {
        "nomad.crt.pem" = {
          inherit destDir secretPath;
          field = "cert";
        };
        "nomad.ca.pem" = {
          inherit destDir secretPath;
          field = "ca";
        };
        "nomad.key.rsa" = {
          inherit destDir secretPath;
          field = "private_key";
        };
      };

    networking.firewall.trustedInterfaces = [ "nomad" "docker0" ];
    services.nomad = {
      enable = true;
      package = pkgs.nomad_1_7;
      enableDocker = true;
      dropPrivileges = false;
      extraPackages = with pkgs; [ cni-plugins getent wget curl consul ];
      extraSettingsPlugins = [ pkgs.nomad-driver-podman ];
      extraSettingsPaths = [
        "/etc/nomad/config/server.hcl"
        "/etc/nomad/config/client.hcl"
        "/etc/nomad/config/extraSettings.hcl"
      ];
      settings = {
        client = {
          network_interface = "wg-mesh";

          cni_path = "${pkgs.cni-plugins}/bin";

          host_volume = mkIf cfg.enableSeaweedFsVolume {
            "seaweedfs-volume" = {
              path = seaweedVolumePath;
              read_only = false;
            };
          };

          meta = mkIf cfg.enableSeaweedFsVolume {
            seaweedfs_volume = true;
          };
        };

        # Require TLS
        tls = {
          rpc_upgrade_mode = true;
          http = true;
          rpc = true;

          ca_file = config.vaultSecrets."nomad.ca.pem".path;
          cert_file = config.vaultSecrets."nomad.crt.pem".path;
          key_file = config.vaultSecrets."nomad.key.rsa".path;
          verify_https_client = false;

          verify_server_hostname = true;

        };
        consul =
          if config.consulNode.enable then {
            grpc_address = "127.0.0.1:${toString config.services.consul.extraConfig.ports.grpc_tls}";
            grpc_ca_file = config.vaultSecrets."consul.ca.pem".path;

            ca_file = config.vaultSecrets."consul.ca.pem".path;
            cert_file = config.vaultSecrets."consul.crt.pem".path;
            key_file = config.vaultSecrets."consul.key.rsa".path;
            address = "127.0.0.1:${toString config.services.consul.extraConfig.ports.https}";
            ssl = true;
            # share_ssl = true; default is true
          } else null;
      };
    };
  };
}
