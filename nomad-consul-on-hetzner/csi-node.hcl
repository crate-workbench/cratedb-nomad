# hcloud-csi-node.hcl
job "hcloud-csi-node" {
  datacenters = ["dc1"]
  namespace   = "default"
  type        = "system"

  group "node" {
    task "plugin" {
      driver = "docker"

      config {
        # Check version on https://hub.docker.com/r/hetznercloud/hcloud-csi-driver/tags
        image      = "hetznercloud/hcloud-csi-driver:v2.3.2"
        command    = "bin/hcloud-csi-driver-node"
        privileged = true
      }

      env {
        CSI_ENDPOINT   = "unix://csi/csi.sock"
        ENABLE_METRICS = true
        HCLOUD_TOKEN = "<HETZNER-API-TOKEN-RW>"
      }

      csi_plugin {
        id        = "csi.hetzner.cloud"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
