# vol.hcl  nomad volume create vol.hcl
# Created external volume 35289662 with ID crateX

type      = "csi"
id        = "vol[0]"
name      = "vol-0"
plugin_id = "csi.hetzner.cloud"
capacity_max = "11GiB"
capacity_min = "11GiB"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

mount_options {
  fs_type     = "ext4"
  mount_flags = ["discard", "defaults"]
}
