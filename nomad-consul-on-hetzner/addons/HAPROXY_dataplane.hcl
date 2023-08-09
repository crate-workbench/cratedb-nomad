# https://www.haproxy.com/documentation/hapee/latest/configuration/config-sections/frontend/
config_version = 2

name = "ubuntu-8gb-hel1-1"

mode = "single"

dataplaneapi {
  host = "0.0.0.0"
  port = 5555

  user "admin" {
    insecure = true
    password = "adminpwd"
  }

  transaction {
    transaction_dir = "/tmp/haproxy"
  }

  advertised {}
}

haproxy {
  config_file = "/etc/haproxy/haproxy.cfg"
  haproxy_bin = "/usr/sbin/haproxy"

  reload {
    reload_delay    = 5
    reload_cmd      = "service haproxy reload"
    restart_cmd     = "service haproxy restart"
    reload_strategy = "custom"
  }
}

service_discovery {
  consuls = [
    {
      Address                    = "10.x.x.2"
      Description                = ""
      Enabled                    = true
      ID                         = "7920fee8-6fed-4585-a85c-cc19bb5cc1d8"
      Name                       = ""
      Namespace                  = ""
      Port                       = 8500
      RetryTimeout               = 10
      ServerSlotsBase            = 10
      ServerSlotsGrowthIncrement = 10
      ServerSlotsGrowthType      = "linear"
      Token                      = ""
    },
  ]
}
