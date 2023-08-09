job "grafana" {
  datacenters = ["*"]

  type = "service"

  group "grafana" {

# this is not persistent, but it is sticky
    ephemeral_disk {
      migrate = true
      size    = 5000
      sticky  = true
    }

    network {
      port "grafana" {
        to = 3000
      }
    }


    task "grafana" {
      driver = "docker"

      env {
        GF_SERVER_ROOT_URL = "http://nomad1:9999/grafana"
        GF_PATHS_DATA = "/alloc/data"
      }

      config {
        image = "grafana/grafana:10.0.3"
        ports = ["grafana"]
      }

      resources {
        cpu    = 500
        memory = 500
      }

    }

    service {
      name = "grafana"
      port = "grafana"
      tags = ["urlprefix-/grafana strip=/grafana",]

        check {
          name     = "Grafana HTTP API"
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "2s"
        }
    }
  }
}
