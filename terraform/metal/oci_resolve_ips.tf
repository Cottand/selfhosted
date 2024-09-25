data "oci_core_instance_pool_instances" "pool1" {
  compartment_id   = local.ociRoot
  instance_pool_id = oci_core_instance_pool.control.id
}

data "oci_core_instance" "pool1_instances" {
  count       = local.oci_control_pool_size
  instance_id = data.oci_core_instance_pool_instances.pool1.instances[count.index].id
}

data "oci_core_vnic_attachments" "pool1_vnics" {
  count          = local.oci_control_pool_size
  compartment_id = local.ociRoot
  instance_id    = data.oci_core_instance_pool_instances.pool1.instances[count.index].id
}

data "oci_core_vnic" "pool1_vnics" {
  count   = local.oci_control_pool_size
  vnic_id = data.oci_core_vnic_attachments.pool1_vnics[count.index].vnic_attachments[0].vnic_id
}


locals {
  oci_servers_ips = {
    #     for i in data.oci_core_instance.pool1_instances :
    for index in range(local.oci_control_pool_size) :
    data.oci_core_instance_pool_instances.pool1.instances[index].display_name => {
      name = data.oci_core_instance_pool_instances.pool1.instances[index].display_name
      ipv4 = data.oci_core_vnic.pool1_vnics[index].public_ip_address
      ipv6 = data.oci_core_vnic.pool1_vnics[index].ipv6addresses[0]
    }
  }
  oci_servers_ips_list = [
    #     for i in data.oci_core_instance.pool1_instances :
    for index in range(local.oci_control_pool_size) : {
      name = data.oci_core_instance_pool_instances.pool1.instances[index].display_name
      ipv4 = data.oci_core_vnic.pool1_vnics[index].public_ip_address
      ipv6 = data.oci_core_vnic.pool1_vnics[index].ipv6addresses[0]
    }
  ]
}

resource "local_file" "oci_control_records" {
  filename = "oci_control.json"
  content  = jsonencode([for index in range(local.oci_control_pool_size) : local.oci_servers_ips_list[index].name])
}