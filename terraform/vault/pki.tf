# for pki stuff see https://github.com/hashicorp-education/learn-vault-pki-engine/blob/main/terraform/main.tf

resource "vault_mount" "pki" {
  path        = "pki"
  type        = "pki"
  description = "PKI root mount"

  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 315360000
}

resource "vault_pki_secret_backend_root_cert" "root_2023" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "dcotta.eu root"
  ttl         = 315360000
  issuer_name = "root-2023"
}

# output "vault_pki_secret_backend_root_cert_root_2023" {
#   value = vault_pki_secret_backend_root_cert.root_2023.certificate
# } 
resource "local_file" "root_2023_cert" {
  content  = vault_pki_secret_backend_root_cert.root_2023.certificate
  filename = "tmp/root_2023_ca.crt"
}

# used to update name and properties
# manages lifecycle of existing issuer
resource "vault_pki_secret_backend_issuer" "root_2023" {
  backend                        = vault_mount.pki.path
  issuer_ref                     = vault_pki_secret_backend_root_cert.root_2023.issuer_id
  issuer_name                    = vault_pki_secret_backend_root_cert.root_2023.issuer_name
  revocation_signature_algorithm = "SHA256WithRSA"
}

# vault write pki/roles/2023-servers allow_any_name=true
resource "vault_pki_secret_backend_role" "role" {
  backend          = vault_mount.pki.path
  name             = "2023-servers-role"
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allow_subdomains = true
  allow_any_name   = true
}

resource "vault_pki_secret_backend_config_urls" "config-urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["${var.vault_addr}/v1/pki/ca"]
  crl_distribution_points = ["${var.vault_addr}/v1/pki/crl"]
}

## intermediate CA ##

resource "vault_mount" "pki_int" {
  path        = "pki_int"
  type        = "pki"
  description = "Intermediate PKI mount"

  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 157680000
}

resource "vault_pki_secret_backend_intermediate_cert_request" "csr-request" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = "dcotta.eu Intermediate Authority"
}

resource "local_file" "csr_request_cert" {
  content  = vault_pki_secret_backend_intermediate_cert_request.csr-request.csr
  filename = "tmp/pki_intermediate.csr"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend     = vault_mount.pki.path
  common_name = "dcotta.eu mesh intermediate"
  csr         = vault_pki_secret_backend_intermediate_cert_request.csr-request.csr
  format      = "pem_bundle"
  ttl         = 75480000
  issuer_ref  = vault_pki_secret_backend_root_cert.root_2023.issuer_id
}


resource "local_file" "intermediate_ca_cert" {
  content  = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
  filename = "tmp/intermediate.cert.pem"
}

# step 2.5
# vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

# manage the issuer created for the set signed
resource "vault_pki_secret_backend_issuer" "intermediate" {
  backend     = vault_mount.pki_int.path
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate.imported_issuers[0]
  issuer_name = "dcotta-dot-eu-intermediate"
}



## intermediate CA role ##

resource "vault_pki_secret_backend_role" "intermediate_role" {
  backend          = vault_mount.pki_int.path
  issuer_ref       = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  name             = "dcotta-dot-eu"
  ttl              = 2086400
  max_ttl          = 2592000
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allowed_domains  = ["dcotta.eu"]
  allow_subdomains = true
}

# new cert

resource "vault_pki_secret_backend_cert" "dcotta-dot-eu" {
  issuer_ref  = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  backend     = vault_pki_secret_backend_role.intermediate_role.backend
  name        = vault_pki_secret_backend_role.intermediate_role.name
  common_name = "vault.mesh.dcotta.eu"

  alt_names = ["*.mesh.dcotta.eu"]

  ip_sans = [
    "10.10.0.1",
    "10.10.1.1",
    "10.10.2.1",
    "10.10.3.1",
    "10.10.4.1",
    "10.10.5.1",
  ]
  ttl    = 86400000
  revoke = true
}

#$  terraform output -raw vault_pki_secret_backend_cert_dcotta-dot-eu_cert >> ../secret/pki/vault/cert.pem
# output "vault_pki_secret_backend_cert_dcotta-dot-eu_cert" {
#   value = vault_pki_secret_backend_cert.dcotta-dot-eu.certificate
# }

# output "vault_pki_secret_backend_cert_dcotta-dot-eu_issuing_ca" {
#   value = vault_pki_secret_backend_cert.dcotta-dot-eu.issuing_ca
# }

# output "vault_pki_secret_backend_cert_dcotta-dot-eu_serial_number" {
#   value = vault_pki_secret_backend_cert.dcotta-dot-eu.serial_number
#   sensitive = true
# }

# output "vault_pki_secret_backend_cert_dcotta-dot-eu_private_key" {
#   value = vault_pki_secret_backend_cert.dcotta-dot-eu.private_key
#   sensitive = true
# }

resource "local_sensitive_file" "dcotta-dot-eu_private_key" {
  content  = vault_pki_secret_backend_cert.dcotta-dot-eu.private_key
  filename = "../../secret/pki/vault/key.rsa"
}

resource "local_file" "dcotta-dot-eu_issuing_ca" {
  content  = vault_pki_secret_backend_cert.dcotta-dot-eu.issuing_ca
  filename = "../../certs/mesh-ca.pem"
}

resource "local_file" "dcotta-dot-eu_cert" {
  content  = vault_pki_secret_backend_cert.dcotta-dot-eu.certificate
  filename = "../../certs/mesh-cert.pem"
}

resource "local_file" "dcotta-dot-eu_cert-chain" {
  content  = "${vault_pki_secret_backend_cert.dcotta-dot-eu.certificate}\n${vault_pki_secret_backend_cert.dcotta-dot-eu.ca_chain}"
  filename = "../../certs/mesh-cert-chain.pem"
}