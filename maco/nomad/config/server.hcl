server {
    enabled = true
    bootstrap_expect = 2
}

data_dir  = "/var/lib/nomad"

bind_addr = "10.8.0.5"

advertise {
    #   Defaults to the first private IP address.
    http = "10.8.0.5"
    rpc  = "10.8.0.5"
    serf = "10.8.0.5:5648" # non-default ports may be specified
}

log_rotate_bytes = 1024000

ports {
    http = 4646
    rpc  = 4647
    serf = 4648
}

telemetry {
    collection_interval = "5s"
    disable_hostname = true
    prometheus_metrics = true
    publish_allocation_metrics = true
    publish_node_metrics = true
}
