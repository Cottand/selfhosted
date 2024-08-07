locals {
  mesh_ip4 = {
    cosmo  = "10.10.0.1"
    elvis  = "10.10.1.1"
    maco   = "10.10.2.1"
    ari    = "10.10.3.1"
    miki   = "10.10.4.1"
    ziggy  = "10.10.5.1"
    xps2   = "10.10.6.1"
    bianco = "10.10.0.2"

    hez = {
      "hez1" = "10.10.11.1"
      "hez2" = "10.10.12.1"
      "hez3" = "10.10.13.1"
    }
  }
  zoneIds     = jsondecode(data.bitwarden-secrets_secret.zoneIds.value)
  zoneIdsList = [local.zoneIds["eu"], local.zoneIds["com"]]
  pubIp       = jsondecode(data.bitwarden-secrets_secret.pubIps.value)
}


## Discovery

module "node_miki" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "miki"
  ip4_mesh    = local.mesh_ip4.miki
  ip4_pub     = local.pubIp["ip4"]["miki"]
  ip6_pub     = local.pubIp["ip6"]["miki"]
  is_web_ipv4 = false
  is_web_ipv6 = false
}
module "node_maco" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "maco"
  ip4_mesh    = local.mesh_ip4.maco
  ip4_pub     = local.pubIp["ip4"]["maco"]
  ip6_pub     = local.pubIp["ip6"]["maco"]
  is_web_ipv4 = false
  is_web_ipv6 = false
}
module "node_cosmo" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "cosmo"
  ip4_mesh    = local.mesh_ip4.cosmo
  ip4_pub     = local.pubIp["ip4"]["cosmo"]
  ip6_pub     = local.pubIp["ip6"]["cosmo"]
  is_web_ipv4 = false
  is_web_ipv6 = false
}

module "node_elvis" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "elvis"
  ip4_mesh    = local.mesh_ip4.elvis
  ip4_pub     = null
  ip6_pub     = local.pubIp["ip6"]["elvis"]
  is_web_ipv4 = false
  is_web_ipv6 = false
}
module "node_ari" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "ari"
  ip4_mesh    = local.mesh_ip4.ari
  ip4_pub     = null
  ip6_pub     = local.pubIp["ip6"]["ari"]
  is_web_ipv4 = false
  is_web_ipv6 = false
}
module "node_xps2" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "xps2"
  ip4_mesh    = local.mesh_ip4.xps2
  ip4_pub     = null
  ip6_pub     = local.pubIp["ip6"]["xps2"]
  is_web_ipv4 = false
  is_web_ipv6 = false
}
module "node_ziggy" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "ziggy"
  ip4_mesh    = local.mesh_ip4.ziggy
  ip4_pub     = null
  ip6_pub     = local.pubIp["ip6"]["ziggy"]
  is_web_ipv4 = false
  is_web_ipv6 = false
}
module "node_bianco" {
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = "bianco"
  ip4_mesh    = local.mesh_ip4.bianco
  ip4_pub     = null
  ip6_pub     = null
  is_web_ipv4 = false
  is_web_ipv6 = false
}

module "nodes_hz" {
  for_each    = data.terraform_remote_state.metal.outputs["server_ips"]
  cf_zone_ids = local.zoneIdsList
  source      = "../modules/node"
  name        = each.key
  ip4_mesh    = local.mesh_ip4.hez[each.key]
  ip4_pub     = each.value["ipv4"]
  ip6_pub     = each.value["ipv6"]
  is_web_ipv4 = true
  is_web_ipv6 = true
}

# Websites



# resource "cloudflare_record" "vault-cname-mesh" {
#   zone_id = local.zoneIds["eu"]
#   name    = "vault.mesh"
#   type    = "CNAME"
#   value   = "hez1.mesh.dcotta.eu"
#   ttl     = 1
#   comment = "tf managed"
#   proxied = true
# }

resource "cloudflare_record" "nico-cname-web" {
  zone_id = local.zoneIds["eu"]
  name    = "nico"
  type    = "CNAME"
  value   = "hez1.vps.dcotta.eu"
  ttl     = 1
  comment = "tf managed"
  proxied = true
}

resource "cloudflare_record" "lemmy-cname-web" {
  zone_id = local.zoneIds["eu"]
  name    = "r"
  type    = "CNAME"
  value   = "web.dcotta.eu"
  ttl     = 1
  comment = "tf managed"
  proxied = true
}
