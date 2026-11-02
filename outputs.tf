output "sca" {
  value       = var.sca.enable ? module.sca[0].sca : null
  description = "SCA shared resources object (entra_app_id, entra_custom_role_id, entra_wif_user_id, resource_app_id, resource_custom_role_id, resource_wif_user_id); null if SCA disabled."
}

output "secrets_hub" {
  value       = var.secrets_hub.enable ? module.secrets_hub[0].secrets_hub : null
  description = "Secrets Hub shared resources object (app_id, custom_role_id, identity_trusted_username); null if Secrets Hub disabled."
}

output "cds" {
  value       = var.cds.enable ? module.cds[0].cds : null
  description = "CDS shared resources object (entra_app_id, entra_custom_role_id, entra_wif_user_id, resource_app_id, resource_custom_role_id, resource_wif_user_id); null if CDS disabled."
}
