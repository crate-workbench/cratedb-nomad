
datacenter = "dc1"
data_dir = "/opt/nomad"
#bind_addr = "10.33.0.2"
bind_addr = "0.0.0.0"

server {
  enabled = true
  bootstrap_expect = 3
}

client {
  enabled = true

  host_volume "crate-config" {
    path      = "/opt/crate/config"
    read_only = false
  }
}

retry_join = ["10.33.0.2:4647", "10.33.0.3:4647", "10.33.0.4:4647"]

advertise {
  http = "10.33.0.2:4646"  # Replace with the IP address of Node 1
  rpc  = "10.33.0.2:4647"  # Replace with the IP address of Node 1
  serf = "10.33.0.2:4648"  # Replace with the IP address of Node 1
}

consul {
  address = "10.33.0.2:8500"  # Use a different Consul server address for each client!
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics = true
  prometheus_metrics = true
}

# Enable the UI for the Nomad server
ui {
  enabled = true
}

# Enable logging to a file
log_level = "INFO"
log_file  = "/var/log/nomad/nomad.log"

plugin "raw_exec" {
  config {
    enabled = true
  }
}
