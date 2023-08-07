# vol.hcl  nomad volume create vol.hcl
# Created external volume 35289662 with ID crateX

type      = "csi"
id        = "crateX"
name      = "crateX"
plugin_id = "csi.hetzner.cloud"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

mount_options {
  fs_type     = "ext4"
  mount_flags = ["discard", "defaults"]
}
