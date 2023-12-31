job "fabiolb" {
  datacenters = ["*"]

  type = "system"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "lb" {

    network {
      port "fabio-prometheus" {
        static = 7999
      }
    }


    task "fabio" {
      driver = "exec"

      artifact {
        source = "https://github.com/fabiolb/fabio/releases/download/v1.6.3/fabio-1.6.3-linux_amd64"
        destination = "/usr/local/bin/fabio"
        mode = "file"
    }

      config {
        command = "fabio"
         args = [
          "-proxy.addr", ":9999;proto=http,:7432;proto=tcp,:7433;proto=tcp,:7999;proto=prometheus",
          "-metrics.target", "prometheus",
        ]
      }
    }
    service {
      name = "fabio-prometheus"
      port = "fabio-prometheus"
    }
  }
}
