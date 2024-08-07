

id        = "immich-pictures"
name      = "immich-pictures"
type      = "csi"

plugin_id = "seaweedfs"

# dont try to set this to less than 1GiB
capacity_min = "200GiB"
capacity_max = "200GiB"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

mount_options {
  fs_type     = "ext4"
  mount_flags = ["rw"]
}

# documented at https://github.com/seaweedfs/seaweedfs-csi-driver
parameters {
  replication = "010"
}