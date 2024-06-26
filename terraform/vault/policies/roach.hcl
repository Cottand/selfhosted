path "secret/data/nomad/job/{{identity.entity.aliases.auth_jwt_f5c14826.metadata.nomad_job_id}}/*" {
  capabilities = ["read"]
}

path "secret/data/nomad/job/{{identity.entity.aliases.auth_jwt_f5c14826.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}

path "secret/metadata/job/*" {
  capabilities = ["list"]
}

path "secret/metadata/*" {
  capabilities = ["list"]
}

path "secret/data/nomad/infra/root_ca/*" {
  capabilities = ["read"]
}

path "secret/data/nomad/infra/root_ca" {
  capabilities = ["read"]
}

# roach part for all workloads
path "secret/data/nomad/job/roach/users/*" {
  capabilities = ["read"]
}