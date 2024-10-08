job "dns" {
  type = "system"
  group "leng-dns" {
    network {
      mode = "bridge"
      port "dns" {
        static       = 53
        host_network = "ts"
      }
      port "dns-public" {
        // static = 53
      }
      port "metrics" {
        to           = 4000
        host_network = "ts"
      }
      port "http_doh" {
        host_network = "ts"
      }
    }
    update {
      max_parallel     = 1
      canary           = 1
      min_healthy_time = "30s"
      healthy_deadline = "5m"
      auto_revert      = true
      auto_promote     = true
    }


    service {
      name     = "dns-metrics"
      port     = "metrics"
      meta {
        metrics_port = "${NOMAD_HOST_PORT_metrics}"
      }
    }
    service {
      name     = "dns"
      port     = "dns"
      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.${NOMAD_TASK_NAME}.entrypoints=dns",
        // can't filter UDP
        // "traefik.udp.routers.${NOMAD_TASK_NAME}.middlewares=vpn-whitelist@file",
      ]
    }
    service {
      name     = "doh"
      port     = "http_doh"
      tags = [
        "traefik.enable=false",
        "traefik.http.routers.${NOMAD_TASK_NAME}.rule=Host(`dns.vps.dcotta.eu`) ", //" || ( Host(`138.201.153.245`) && PathPrefix(`/dns-query`) )",
        "traefik.http.routers.${NOMAD_TASK_NAME}.entrypoints=web, web_public, websecure, websecure_public",

        "traefik.http.routers.${NOMAD_TASK_NAME}.tls=true",
        # expose but for now only when on VPN
        // "traefik.http.routers.${NOMAD_TASK_NAME}.middlewares=vpn-whitelist@file",
      ]
    }
    task "leng-dns" {
      driver = "docker"
      config {
        image = "ghcr.io/cottand/leng:sha-5669792"
        args = [
          "--config", "/config.toml",
          "--update",
        ]
        volumes = [
          "local/config.toml:/config.toml",
        ]
        ports = ["dns", "metrics"]
      }
      env = {
        "environment" = "TZ=Europe/Berlin"
      }
      resources {
        cpu    = 80
        memory = 80
      }
      template {
        destination = "local/config.toml"
        change_mode = "restart"
        # see https://github.com/miekg/dns/blob/master/doc.go#L23C24-L23C58
        data = <<EOF
logconfig = "stderr@1"

# address to bind to for the DNS server
bind = "0.0.0.0:{{ env "NOMAD_PORT_dns"  }}"

# address to bind to for the API server
api = "0.0.0.0:{{ env "NOMAD_PORT_metrics"  }}"

# concurrency interval for lookups in miliseconds
interval = 200


# question cache capacity, 0 for infinite but not recommended (this is used for storing logs)
questioncachecap = 5000

metrics.enabled = true

# manual custom dns entries
customdnsrecords = [
    "proxy.manual.     3600      IN  A   100.92.69.51  ",
    "proxy.manual.     3600      IN  A   100.82.72.56",

    "nomad.traefik.         3600      IN  CNAME    proxy.manual  ",
    "consul.traefik.         3600     IN  CNAME    proxy.manual  ",

    "_http._tcp.seaweedfs-master.nomad IN SRV 0 0 80 seaweed-master.vps.dcotta.eu",

    {{ range $i, $s := nomadService "seaweedfs-webdav" }}
    "webdav.vps            3600  IN  A   {{ .Address }}",
    {{ end }}

    {{ $rr_a := sprig_list -}}
    {{- $rr_srv := sprig_list -}}
    {{- $base_domain := ".nomad" -}} {{- /* Change this field for a diferent tld! */ -}}
    {{- $ttl := 360 -}}             {{- /* Change this field for a diferent ttl! */ -}}

    {{- /* Iterate over all of the registered Nomad services */ -}}
    {{- range services -}}
        {{ $service := . }}

        {{- /* Iterate over all of the instances of a services */ -}}
        {{- range service $service.Name -}}
            {{ $svc := . }}


            {{- /* Generate a uniq label for IP */ -}}
            {{- $node := $svc.Address | md5sum | sprig_trunc 8 }}

            {{- /* Record A & SRV RRs */ -}}
            {{- $rr_a = sprig_append $rr_a (sprig_list $svc.Name $svc.Address) -}}
            {{- $rr_a = sprig_append $rr_a (sprig_list $node $svc.Address) -}}
            {{- $rr_srv = sprig_append $rr_srv (sprig_list $svc.Name $svc.Port $node) -}}
        {{- end -}}
    {{- end -}}

    {{- range services }}
    "{{ printf "%s %d  %10s %10s %s" (sprig_nospace (sprig_cat .Name ".traefik" )) $ttl "IN" "CNAME" "proxy.manual" }}",
    "{{ printf "%s %d  %10s %10s %s" (sprig_nospace (sprig_cat .Name ".tfk.nd" )) $ttl "IN" "CNAME" "proxy.manual" }}",
    {{- end -}}

    {{- /* Iterate over lists and print everything */ -}}

    {{ range $rr_srv -}}
    "{{ printf "%s %s %s %d %d %6d %s" (sprig_nospace (sprig_cat (index . 0) $base_domain ".srv")) "IN" "SRV" 0 0 (index . 1) (sprig_nospace (sprig_cat (index . 2) $base_domain )) }}",
    {{ end -}}

    {{- range $rr_a | sprig_uniq -}}
    "{{ printf "%s %4d %s %4s %s" (sprig_nospace (sprig_cat (index . 0) $base_domain)) $ttl "IN" "A" (sprig_last . ) }}",
    {{ end }}
]

[Upstream]
  nameservers = ["1.1.1.1:53", "1.0.0.1:53", "10.10.4.1:8600"]
  # query timeout for dns lookups in seconds
  timeout = 5
  # cache entry lifespan in seconds
  expire = 600
  # cache capacity, 0 for infinite
  maxcount = 0
  # manual blocklist entries
  # Dns over HTTPS provider to use.
  DoH = "https://cloudflare-dns.com/dns-query"

[DnsOverHttpServer]
	enabled = true
	bind = "0.0.0.0:{{ env "NOMAD_PORT_http_doh" }}"
	timeoutMs = 5000

	[DnsOverHttpServer.TLS]
		enabled = false

EOF
      }
    }
  }
}