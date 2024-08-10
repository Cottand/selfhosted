let
  lib = import ../../jobs/lib;
  version = "c865dfa";
  name = "s-portfolio-stats";
  cpu = 120;
  mem = 500;
  ports = {
    http = 8888;
    upDb = 5432;
    upS3 = 3333;
  };
  sidecarResources = with builtins; mapAttrs (_: ceil) {
    cpu = 0.20 * cpu;
    memoryMB = 0.25 * mem;
    memoryMaxMB = 0.25 * mem + 100;
  };
  otlpPort = 9001;
  bind = lib.localhost;
in
lib.mkJob name {
  update = {
    maxParallel = 1;
    autoRevert = true;
    autoPromote = true;
    canary = 1;
  };

  group.${name} = {
    count = 1;
    network = {
      mode = "bridge";
      dynamicPorts = [
        { label = "health"; }
      ];
      reservedPorts = [
      ];
    };

    service.${name} = {
      connect.sidecarService = {
        proxy = {
          upstream."tempo-otlp-grpc-mesh".localBindPort = otlpPort;

          config = lib.mkEnvoyProxyConfig {
            otlpService = "proxy-${name}";
            otlpUpstreamPort = otlpPort;
            protocol = "http";
          };
        };
      };
      connect.sidecarTask.resources = sidecarResources;
      # TODO implement http healthcheck
      port = toString ports.http;
      #      tags = [
      #        "traefik.enable=true"
      #        "traefik.consulcatalog.connect=true"
      #        "traefik.http.routers.\${NOMAD_GROUP_NAME}-http.entrypoints=web,websecure"
      #        "traefik.http.routers.\${NOMAD_GROUP_NAME}-http.tls=true"
      #        "traefik.http.routers.\${NOMAD_GROUP_NAME}-http.middlewares=mesh-whitelist@file"
      #      ];
    };
    task.${name} = {
      driver = "docker";
      vault = { };

      config = {
        image = "ghcr.io/cottand/selfhosted/${name}:${version}";
        # ports = ["http" "grpc", "metrics", "webdav"];
#        args = [
#          "--config"
#          "/local/config.toml"
#          "--listen"
#          "${bind}:${toString ports.http}"
#        ];
      };
      resources = {
        cpu = cpu;
        memoryMb = mem;
        memoryMaxMb = builtins.ceil (2 * mem);
      };
    };
  };
}