terraform {
  required_version = ">= 1.8.5"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  # Unique ID and naming (same as the Secrets Hub 0.0.4 onboarding script)
  tenant_id_suffix = element(split("-", var.tenant_id), length(split("-", var.tenant_id)) - 1)
  entra_id_suffix  = element(split("-", var.entra_id), length(split("-", var.entra_id)) - 1)
  unique_id        = "${local.tenant_id_suffix}-${local.entra_id_suffix}"

  app_display_name          = "idira-secrets-hub-app-${local.unique_id}"
  role_name                 = substr("idira-secrets-hub-role-${local.unique_id}", 0, 63)
  federated_credential_name = "Idira-SecretsHub-Azure-Access"

  # Built locally because identity_params["secrets_hub"]["identity_user_id"] is only a placeholder, not the real subject.
  identity_trusted_username = upper("SECRETS_HUB_ISOLATED_SYSTEM_USER_FOR_AZURE_${local.tenant_id_suffix}_${local.entra_id_suffix}")

  # The Entra tenant ID is also the root management group ID, so the role is defined and assignable at the root.
  role_definition_scope = "/providers/Microsoft.Management/managementGroups/${var.entra_id}"

  service_tags = ["secrets_hub-version:0.0.4"]
}

resource "azuread_application" "secrets_hub_app" {
  display_name = local.app_display_name
  tags         = local.service_tags
}

resource "azuread_service_principal" "secrets_hub_app_sp" {
  client_id = azuread_application.secrets_hub_app.client_id
  tags      = local.service_tags

  # Microsoft Graph rejects concurrent writes on the same application with a 409 (Directory_ConcurrencyViolation).
  # This dependency serializes the two resources: the federated credential is created first and deleted last.
  depends_on = [azuread_application_federated_identity_credential.secrets_hub_credentials]
}

resource "azuread_application_federated_identity_credential" "secrets_hub_credentials" {
  application_id = azuread_application.secrets_hub_app.id
  display_name   = local.federated_credential_name
  description    = "Federated credential for Secrets Hub that trusts identity tokens from the Idira tenant"
  issuer         = var.identity_issuer
  subject        = local.identity_trusted_username
  audiences      = [var.identity_audience]
}

resource "azurerm_role_definition" "secrets_hub_custom_role" {
  name        = local.role_name
  scope       = local.role_definition_scope
  description = "Custom role for Secrets Hub access to Key Vault and Resource Graph | secrets_hub-version:0.0.4"
  permissions {
    actions = [
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/secrets/read",
      "Microsoft.KeyVault/vaults/secrets/write",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resources/read",
      "Microsoft.ResourceGraph/resources/read",
    ]
    not_actions      = []
    data_actions     = []
    not_data_actions = []
  }
  assignable_scopes = [local.role_definition_scope]
}

# Role assignments are created in the scope modules (terraform-azure-cce-entra, terraform-azure-cce-management-group),
# as in the SCA module.
