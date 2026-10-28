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
  tenant_id_suffix = element(split("-", var.tenant_id), length(split("-", var.tenant_id)) - 1)
  entra_id_suffix  = element(split("-", var.entra_id), length(split("-", var.entra_id)) - 1)
  unique_id        = "${local.tenant_id_suffix}-${local.entra_id_suffix}"

  entra_app_display_name     = substr("Idira-cds-app-entra-${local.unique_id}", 0, 63)
  resource_app_display_name  = substr("Idira-cds-app-resource-${local.unique_id}", 0, 63)
  entra_role_display_name    = "Idira-CDS-ENTRA-ROLE-${local.unique_id}"
  resource_role_display_name = "Idira-CDS-RESOURCES-ROLE-${local.unique_id}"

  role_definition_scope = "/providers/Microsoft.Management/managementGroups/${var.entra_id}"

  # CDS reads the ENTRA / RESOURCES suffix of the WIF subject, so the format must not change
  entra_wif_user_id    = upper("CDS_ISOLATED_SYSTEM_USER_FOR_AZURE_${var.entra_id}_ENTRA")
  resource_wif_user_id = upper("CDS_ISOLATED_SYSTEM_USER_FOR_AZURE_${var.entra_id}_RESOURCES")

  service_version = "2.1.0"
  service_tags    = ["cds-version:${local.service_version}"]

  microsoft_graph_app_id = "00000003-0000-0000-c000-000000000000"
  entra_permissions = {
    "AuditLog.Read.All"  = "b0afded3-3588-46d8-8b3d-9842eff778da"
    "Directory.Read.All" = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
    "User.ReadBasic.All" = "97235f07-e226-4f63-ace3-39588e11d3a1"
  }
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

resource "azuread_application" "cds_entra_app" {
  display_name = local.entra_app_display_name
  tags         = local.service_tags

  required_resource_access {
    resource_app_id = local.microsoft_graph_app_id
    dynamic "resource_access" {
      for_each = local.entra_permissions
      content {
        id   = resource_access.value
        type = "Role"
      }
    }
  }

  # Keep the version tag the app was created with
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azuread_service_principal" "cds_entra_app_sp" {
  client_id = azuread_application.cds_entra_app.client_id
  tags      = local.service_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azuread_app_role_assignment" "msgraph_entra" {
  for_each            = local.entra_permissions
  app_role_id         = each.value
  principal_object_id = azuread_service_principal.cds_entra_app_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_application_federated_identity_credential" "cds_entra_credentials" {
  application_id = azuread_application.cds_entra_app.id
  display_name   = local.entra_app_display_name
  description    = "federated credential with Identity token"
  issuer         = var.identity_issuer
  subject        = local.entra_wif_user_id
  audiences      = [var.identity_audience]

  # Writing the credential and the service principal in parallel can fail with 409 Directory_ConcurrencyViolation
  depends_on = [azuread_service_principal.cds_entra_app_sp]

  lifecycle {
    precondition {
      condition     = var.identity_issuer != null && var.identity_issuer != "" && var.identity_audience != null && var.identity_audience != ""
      error_message = "CDS workload identity federation data is missing: the idsec provider returned no identity_app_issuer / identity_app_audience for the \"cds\" service. Make sure CDS is activated on the Idira tenant."
    }
  }
}

resource "azurerm_role_definition" "cds_entra_custom_role" {
  name        = local.entra_role_display_name
  scope       = local.role_definition_scope
  description = "CDS Custom role for Azure Entra | cds-version:${local.service_version}"
  # No permissions block: Azure returns none for a role without actions, so an empty block would drift
  assignable_scopes = [local.role_definition_scope]

  # On offboarding, keeps the Entra side until the resources role is deleted (through cds_entra_at_root_mg)
  depends_on = [
    azuread_application.cds_entra_app,
    azuread_service_principal.cds_entra_app_sp,
    azuread_app_role_assignment.msgraph_entra,
    azuread_application_federated_identity_credential.cds_entra_credentials,
  ]

  # Keep the version the role was created with
  lifecycle {
    ignore_changes = [description]
  }
}

resource "azurerm_role_assignment" "cds_entra_at_root_mg" {
  scope              = local.role_definition_scope
  role_definition_id = azurerm_role_definition.cds_entra_custom_role.role_definition_resource_id
  principal_id       = azuread_service_principal.cds_entra_app_sp.object_id
}

resource "azuread_application" "cds_resource_app" {
  display_name = local.resource_app_display_name
  tags         = local.service_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azuread_service_principal" "cds_resource_app_sp" {
  client_id = azuread_application.cds_resource_app.client_id
  tags      = local.service_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azuread_application_federated_identity_credential" "cds_resource_credentials" {
  application_id = azuread_application.cds_resource_app.id
  display_name   = local.resource_app_display_name
  description    = "federated credential with Identity token"
  issuer         = var.identity_issuer
  subject        = local.resource_wif_user_id
  audiences      = [var.identity_audience]

  # Same 409 race as cds_entra_credentials
  depends_on = [azuread_service_principal.cds_resource_app_sp]

  lifecycle {
    precondition {
      condition     = var.identity_issuer != null && var.identity_issuer != "" && var.identity_audience != null && var.identity_audience != ""
      error_message = "CDS workload identity federation data is missing: the idsec provider returned no identity_app_issuer / identity_app_audience for the \"cds\" service. Make sure CDS is activated on the Idira tenant."
    }
  }
}

resource "azurerm_role_definition" "cds_resource_custom_role" {
  name        = local.resource_role_display_name
  scope       = local.role_definition_scope
  description = "CDS Custom role for Azure Resources | cds-version:${local.service_version}"
  permissions {
    actions = [
      "Microsoft.Authorization/*/read"
    ]
    not_actions = []
  }
  assignable_scopes = [local.role_definition_scope]

  # On offboarding, deleted first: while a scope still assigns it, Azure refuses (RoleDefinitionHasAssignments)
  # and the apply stops before either app is touched
  depends_on = [
    azuread_application.cds_resource_app,
    azuread_service_principal.cds_resource_app_sp,
    azuread_application_federated_identity_credential.cds_resource_credentials,
    azurerm_role_assignment.cds_entra_at_root_mg,
  ]

  lifecycle {
    ignore_changes = [description]
  }
}
