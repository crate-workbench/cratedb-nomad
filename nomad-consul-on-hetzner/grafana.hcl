job "grafana" {
  datacenters = ["*"]

  type = "service"

  group "grafana" {

    network {
      port "grafana" {
        to = 3000
      }
    }


    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"
        ports = ["grafana"]
      }

    }

    service {
      name = "grafana"
      port = "grafana"
      #tags = ["urlprefix-/prometheus strip=/prometheus}",]

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
