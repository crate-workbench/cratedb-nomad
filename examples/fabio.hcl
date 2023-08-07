job "fabiolb" {
  datacenters = ["*"]

  type = "system"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "lb" {


    task "fabio" {
      driver = "exec"

      artifact {
        source = "https://github.com/fabiolb/fabio/releases/download/v1.6.3/fabio-1.6.3-linux_amd64"
        destination = "/usr/local/bin/fabio"
        mode = "file"
    }

      config {
        command = "fabio"
         args = ["-proxy.addr", ":7432;proto=tcp"]
      }
    }
  }
}
