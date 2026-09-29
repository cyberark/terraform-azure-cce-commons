# Constant output shape: same fields always; null when Entra-level skipped or value passed through
output "sca" {
  value = {
    entra_app_id                      = local.create_entra_app ? azuread_application.sca_entra_app[0].client_id : local.params.sca_entra_app_id
    entra_custom_role_id              = local.create_entra_role ? azurerm_role_definition.sca_entra_custom_role[0].role_definition_resource_id : local.params.sca_entra_custom_role_id
    entra_wif_user_id                 = local.entra_wif_user_id
    resource_app_id                   = local.create_resource_app ? azuread_application.sca_resource_app[0].client_id : local.params.sca_resource_app_id
    resource_custom_role_id           = local.create_resource_role ? azurerm_role_definition.sca_resource_custom_role[0].role_definition_resource_id : local.params.sca_resource_custom_role_id
    resource_wif_user_id              = local.resource_wif_user_id
    add_permissions_to_manage_cluster = local.add_permissions_to_manage_cluster
    resource_k8s_custom_role_id = (
      local.add_permissions_to_manage_cluster
      ? (
        local.create_resource_k8s_role
        ? azurerm_role_definition.sca_resource_k8s_custom_role[0].role_definition_resource_id
        : local.params.sca_resource_k8s_custom_role_id
      )
      : null
    )
  }
  description = "SCA shared resources (created or passed through); Microsoft Entra tenant fields null when sca_entra_onboarding is false; resource_k8s_custom_role_id set when AKS/cluster permissions are enabled."
}
