output "secrets_hub" {
  value = {
    version                   = local.service_version
    app_id                    = azuread_service_principal.secrets_hub_app_sp.client_id
    custom_role_id            = azurerm_role_definition.secrets_hub_custom_role.role_definition_resource_id
    identity_trusted_username = azuread_application_federated_identity_credential.secrets_hub_credentials.subject
  }
  description = "Secrets Hub shared resources (version, app_id, custom_role_id, identity_trusted_username)."
}
