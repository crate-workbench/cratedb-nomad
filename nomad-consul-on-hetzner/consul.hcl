datacenter = "dc1"
data_dir = "/opt/consul"
server = true
bootstrap_expect = 3

ui_config {
  enabled = true
}

client_addr = "0.0.0.0" # port 8600/ui, if this is not
advertise_addr = "10.x.x.2" # needs to be set to a local address, in my case the private ip of the server

retry_join = ["10.x.x.2", "10.x.x.3", "10.x.x.4"]

encrypt = "*****"

tls {
   defaults {
      ca_file = "/etc/consul.d/consul-agent-ca.pem"
      cert_file = "/etc/consul.d/dc1-server-consul-0.pem"
      key_file = "/etc/consul.d/dc1-server-consul-0-key.pem"

      verify_incoming = true
      verify_outgoing = true
   }
   internal_rpc {
      verify_server_hostname = true
   }
}

auto_encrypt {
  allow_tls = true
}

ports {
  grpc = 8502
  grpc_tls= 8503
#  dns = 53
}

connect {
  enabled = true
}
