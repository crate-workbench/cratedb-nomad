job "crate-single-node" {
  datacenters = ["dc1"]

  group "crate" {

     count = 1

    network {
      mode = "bridge"
      port "http-rest" {
      to     = 4200
      }
      port "pg" {
      to     = 5432
      }
      port "disco" {
      to     = 4300
      }
    }

    task "crate" {
      driver = "docker"

      kill_signal = "SIGTERM"
      kill_timeout = "120s"

      config {
        image = "crate/crate:latest"
        args    = ["-Cdiscovery.type=single-node", ]
     }


      resources {
        cpu    = 2000
        memory = 2048
      }

      service {
        provider = "consul"
        name = "http-rest-name-in-consul"
        port = "http-rest"

      }
    }
  }
}
