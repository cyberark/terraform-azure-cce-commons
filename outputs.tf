output "sca" {
  value       = var.sca.enable ? module.sca[0].sca : null
  description = "SCA shared resources object (entra_app_id, entra_custom_role_id, entra_wif_user_id, resource_app_id, resource_custom_role_id, resource_wif_user_id); null if SCA disabled."
}

output "cds" {
  value       = var.cds.enable ? module.cds[0].cds : null
  description = "CDS shared resources object (entra_app_id, entra_custom_role_id, entra_wif_user_id, resource_app_id, resource_custom_role_id, resource_wif_user_id); null if CDS disabled."
}
