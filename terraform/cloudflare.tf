# nico.dcotta.eu

variable "zone_id" {
  type = string
}

variable "pub_ip4" {
  type = map(string)
}

variable "pub_ip6" {
  type = map(string)
}

locals {
  mesh_ip4 = {
    cosmo  = "10.10.0.1"
    elvis  = "10.10.1.1"
    maco   = "10.10.2.1"
    ari    = "10.10.3.1"
    miki   = "10.10.4.1"
    ziggy  = "10.10.5.1"
    bianco = "10.10.0.2"
  }
}


## Discovery

module "node_miki" {
  cf_zone_id  = var.zone_id
  source      = "./modules/node"
  name        = "miki"
  ip4_mesh    = local.mesh_ip4.miki
  ip4_pub     = var.pub_ip4.miki
  ip6_pub     = var.pub_ip6.miki
  is_web_ipv4 = true
  is_web_ipv6 = true
}
module "node_maco" {
  cf_zone_id  = var.zone_id
  source      = "./modules/node"
  name        = "maco"
  ip4_mesh    = local.mesh_ip4.maco
  ip4_pub     = var.pub_ip4.maco
  ip6_pub     = var.pub_ip6.maco
  is_web_ipv4 = true
  is_web_ipv6 = true
}
module "node_cosmo" {
  cf_zone_id  = var.zone_id
  source      = "./modules/node"
  name        = "cosmo"
  ip4_mesh    = local.mesh_ip4.cosmo
  ip4_pub     = var.pub_ip4.cosmo
  ip6_pub     = var.pub_ip6.cosmo
  is_web_ipv4 = true
  is_web_ipv6 = true
}




# Websites


resource "cloudflare_record" "nico-cname-web" {
  zone_id = var.zone_id
  name    = "nico"
  type    = "CNAME"
  value   = "web.dcotta.eu"
  ttl     = 1
  comment = "tf managed"
  proxied = true
}

resource "cloudflare_record" "lemmy-cname-web" {
  zone_id = var.zone_id
  name    = "r"
  type    = "CNAME"
  value   = "web.dcotta.eu"
  ttl     = 1
  comment = "tf managed"
  proxied = true
}