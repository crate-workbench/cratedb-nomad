# please adjust hostname & interface
job "coredns" {
  datacenters = ["dc1"]

  type = "system"

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "ubuntu-8gb-hel1-1"
  }

  group "dns" {

    network {
      port "coredns" {
        static = 53
      }
    }

    task "coredns" {
      driver = "raw_exec"

      template {
        change_mode = "noop"
        destination = "local/coredns.cfg"

        data = <<EOH
.:53 {
    bind enp7s0
    forward consul 10.x.x.2:8600
    forward . /etc/resolv.conf
    log
    errors
}

EOH
      }

      template {
        change_mode = "noop"
        destination = "local/resolv.conf"

        data = <<EOH
nameserver 127.0.0.53
options edns0 trust-ad
search .

EOH
      }

      artifact {
        source = "https://github.com/coredns/coredns/releases/download/v1.10.1/coredns_1.10.1_linux_amd64.tgz"
        destination = "local/coredns"
        mode = "file"
    }

      config {
        command = "local/coredns"
         args = [
          "-conf", "local/coredns.cfg",
        ]
      }
    }
    service {
      name = "coredns"
      port = "coredns"
    }
  }
}
