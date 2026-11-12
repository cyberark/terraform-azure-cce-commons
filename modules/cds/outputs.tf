output "cds" {
  value = {
    version                 = local.service_version
    entra_app_id            = azuread_application.cds_entra_app.client_id
    entra_custom_role_id    = azurerm_role_definition.cds_entra_custom_role.role_definition_resource_id
    entra_wif_user_id       = local.entra_wif_user_id
    resource_app_id         = azuread_application.cds_resource_app.client_id
    resource_custom_role_id = azurerm_role_definition.cds_resource_custom_role.role_definition_resource_id
    resource_wif_user_id    = local.resource_wif_user_id
  }
  description = "CDS shared resources (version, Entra app, resource app, custom roles, WIF users), passed to the Entra, management grou, and subscription modules as shared_resources."
}
