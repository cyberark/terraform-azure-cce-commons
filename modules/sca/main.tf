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
  params = var.parameters

  # Entra-level only when sca_entra_onboarding is true
  create_entra = coalesce(local.params.sca_entra_onboarding, false)

  # Create Entra app/role only when param is null (and for Entra app, only when create_entra)
  create_entra_app  = local.create_entra && local.params.sca_entra_app_id == null
  create_entra_role = local.create_entra && local.params.sca_entra_custom_role_id == null
  # Resource-level always (when param is null)
  create_resource_app  = local.params.sca_resource_app_id == null
  create_resource_role = local.params.sca_resource_custom_role_id == null

  # Unique ID and naming (same as entra SCA module)
  tenant_id_suffix = element(split("-", var.tenant_id), length(split("-", var.tenant_id)) - 1)
  entra_id_suffix  = element(split("-", var.entra_id), length(split("-", var.entra_id)) - 1)
  unique_id        = "${local.tenant_id_suffix}-${local.entra_id_suffix}"

  entra_app_display_name             = "sca-app-entra-${local.unique_id}"
  entra_role_display_name            = "sca-role-entra-${local.unique_id}"
  resource_app_display_name          = "sca-app-resource-${local.unique_id}"
  resource_role_display_name         = "sca-role-resource-${local.unique_id}"
  entra_federated_credential_name    = "sca-app-entra-user-${local.unique_id}"
  resource_federated_credential_name = "sca-app-resource-user-${local.unique_id}"

  role_definition_scope = "/providers/Microsoft.Management/managementGroups/${var.entra_id}"

  microsoft_graph_app_id = "00000003-0000-0000-c000-000000000000"
  entra_permissions = {
    "RoleManagement.Read.Directory" = "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8"
    "Group.ReadWrite.All"           = "62a82d76-70ea-41e2-9197-370581804d09"
    "User.ReadBasic.All"            = "97235f07-e226-4f63-ace3-39588e11d3a1"
  }
  resource_permissions = {
    "Group.ReadWrite.All"       = "62a82d76-70ea-41e2-9197-370581804d09"
    "User.ReadBasic.All"        = "97235f07-e226-4f63-ace3-39588e11d3a1"
    "GroupMember.ReadWrite.All" = "dbaae8cf-10b5-4b86-a4a1-f871c94c6695"
    "Group.Create"              = "bf7b1a76-6e77-406b-b258-bf5c7720e98f"
  }

  tenant_id_hex = upper(local.tenant_id_suffix)
  entra_id_hex  = upper(local.entra_id_suffix)

  computed_entra_username    = "SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_${local.tenant_id_hex}_${local.entra_id_hex}_ENTRA"
  computed_resource_username = "SCA_ISOLATED_SYSTEM_USER_FOR_AZURE_${local.tenant_id_hex}_${local.entra_id_hex}_RESOURCE"
  # Output values: use provided or computed; Entra fields null when not create_entra
  entra_wif_user_id    = local.create_entra ? coalesce(local.params.sca_entra_wif_username, local.computed_entra_username) : null
  resource_wif_user_id = coalesce(local.params.sca_resource_wif_username, local.computed_resource_username)

  add_permissions_to_manage_cluster = coalesce(try(local.params.add_permissions_to_manage_cluster, null), false)
  resource_k8s_role_display_name    = "sca-k8s-access-resource-${local.unique_id}"
  create_resource_k8s_role = (
    local.add_permissions_to_manage_cluster &&
    try(local.params.sca_resource_k8s_custom_role_id, null) == null
  )
}

# Data source for Microsoft Graph
data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

# ----- Entra-level app (only when sca_entra_onboarding && sca_entra_app_id null) -----
resource "azuread_application" "sca_entra_app" {
  count        = local.create_entra_app ? 1 : 0
  display_name = local.entra_app_display_name
  required_resource_access {
    resource_app_id = local.microsoft_graph_app_id
    resource_access {
      id   = local.entra_permissions["RoleManagement.Read.Directory"]
      type = "Role"
    }
    resource_access {
      id   = local.entra_permissions["Group.ReadWrite.All"]
      type = "Role"
    }
    resource_access {
      id   = local.entra_permissions["User.ReadBasic.All"]
      type = "Role"
    }
  }
  web {
    redirect_uris = []
  }
}

resource "azuread_service_principal" "sca_entra_app_sp" {
  count     = local.create_entra_app ? 1 : 0
  client_id = azuread_application.sca_entra_app[0].client_id
}

resource "azuread_app_role_assignment" "msgraph_rolemanagement" {
  count               = local.create_entra_app ? 1 : 0
  app_role_id         = local.entra_permissions["RoleManagement.Read.Directory"]
  principal_object_id = azuread_service_principal.sca_entra_app_sp[0].object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "msgraph_entra_group_readwrite" {
  count               = local.create_entra_app ? 1 : 0
  app_role_id         = local.entra_permissions["Group.ReadWrite.All"]
  principal_object_id = azuread_service_principal.sca_entra_app_sp[0].object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "msgraph_entra_user_readbasic" {
  count               = local.create_entra_app ? 1 : 0
  app_role_id         = local.entra_permissions["User.ReadBasic.All"]
  principal_object_id = azuread_service_principal.sca_entra_app_sp[0].object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_application_federated_identity_credential" "sca_entra_credentials" {
  count          = local.create_entra_app && var.identity_issuer != null && var.identity_audience != null ? 1 : 0
  application_id = azuread_application.sca_entra_app[0].id
  display_name   = local.entra_federated_credential_name
  description    = "Federated credential for SCA Entra level"
  issuer         = var.identity_issuer
  subject        = local.entra_wif_user_id
  audiences      = [var.identity_audience]
}

# ----- Entra custom role (only when sca_entra_onboarding && sca_entra_custom_role_id null) -----
resource "azurerm_role_definition" "sca_entra_custom_role" {
  count       = local.create_entra_role ? 1 : 0
  name        = local.entra_role_display_name
  scope       = local.role_definition_scope
  description = "SCA Custom role for Azure Entra"
  permissions {
    actions     = []
    not_actions = []
  }
  assignable_scopes = [local.role_definition_scope]

  depends_on = [
    azuread_application.sca_entra_app,
    azuread_service_principal.sca_entra_app_sp,
    azuread_app_role_assignment.msgraph_rolemanagement,
    azuread_app_role_assignment.msgraph_entra_group_readwrite,
    azuread_app_role_assignment.msgraph_entra_user_readbasic,
    azuread_application_federated_identity_credential.sca_entra_credentials,
  ]

  # when only representation changes (e.g. provider schema); we never change them here.
  lifecycle {
    ignore_changes = [permissions]
  }
}

# Entra-level role assignment is done in the Entra module (terraform-azure-cce-entra/modules/sca)
# so that assignment-at-scope is consistent with MG and Subscription.

# ----- Resource-level app (always when sca_resource_app_id null) -----
resource "azuread_application" "sca_resource_app" {
  count        = local.create_resource_app ? 1 : 0
  display_name = local.resource_app_display_name
  required_resource_access {
    resource_app_id = local.microsoft_graph_app_id
    resource_access {
      id   = local.resource_permissions["Group.ReadWrite.All"]
      type = "Role"
    }
    resource_access {
      id   = local.resource_permissions["User.ReadBasic.All"]
      type = "Role"
    }
    resource_access {
      id   = local.resource_permissions["GroupMember.ReadWrite.All"]
      type = "Role"
    }
    resource_access {
      id   = local.resource_permissions["Group.Create"]
      type = "Role"
    }
  }
  web {
    redirect_uris = []
  }
}

resource "azuread_service_principal" "sca_resource_app_sp" {
  count     = local.create_resource_app ? 1 : 0
  client_id = azuread_application.sca_resource_app[0].client_id
}

resource "azuread_app_role_assignment" "msgraph_group_readwrite" {
  count               = local.create_resource_app ? 1 : 0
  app_role_id         = local.resource_permissions["Group.ReadWrite.All"]
  principal_object_id = azuread_service_principal.sca_resource_app_sp[0].object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}
resource "azuread_app_role_assignment" "msgraph_user_read" {
  count               = local.create_resource_app ? 1 : 0
  app_role_id         = local.resource_permissions["User.ReadBasic.All"]
  principal_object_id = azuread_service_principal.sca_resource_app_sp[0].object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}
resource "azuread_app_role_assignment" "msgraph_groupmember_readwrite" {
  count               = local.create_resource_app ? 1 : 0
  app_role_id         = local.resource_permissions["GroupMember.ReadWrite.All"]
  principal_object_id = azuread_service_principal.sca_resource_app_sp[0].object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}
resource "azuread_app_role_assignment" "msgraph_group_create" {
  count               = local.create_resource_app ? 1 : 0
  app_role_id         = local.resource_permissions["Group.Create"]
  principal_object_id = azuread_service_principal.sca_resource_app_sp[0].object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_application_federated_identity_credential" "sca_resource_credentials" {
  count          = local.create_resource_app && var.identity_issuer != null && var.identity_audience != null ? 1 : 0
  application_id = azuread_application.sca_resource_app[0].id
  display_name   = local.resource_federated_credential_name
  description    = "Federated credential for SCA Resource level"
  issuer         = var.identity_issuer
  subject        = local.resource_wif_user_id
  audiences      = [var.identity_audience]
}

# ----- Resource custom role (always when sca_resource_custom_role_id null) -----
resource "azurerm_role_definition" "sca_resource_custom_role" {
  count       = local.create_resource_role ? 1 : 0
  name        = local.resource_role_display_name
  scope       = local.role_definition_scope
  description = "SCA Custom role for Azure Resources"
  permissions {
    actions = [
      "Microsoft.Authorization/roleAssignments/read",
      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Authorization/roleAssignments/delete",
      "Microsoft.Authorization/roleDefinitions/read",
      "Microsoft.Authorization/roleManagementPolicies/read",
      "Microsoft.Authorization/permissions/read",
      "Microsoft.ResourceGraph/operations/read",
      "Microsoft.ResourceGraph/resources/read",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourcegroups/resources/read",
      "Microsoft.Resources/subscriptions/providers/read",
      "Microsoft.Resources/subscriptions/resources/read",
      "Microsoft.Resources/subscriptions/operationresults/read",
      "Microsoft.Resources/resources/read",
      "Microsoft.Management/managementGroups/read",
      "Microsoft.Management/managementGroups/subscriptions/read"
    ]
    not_actions = []
  }
  assignable_scopes = [local.role_definition_scope]

  depends_on = [
    azuread_application.sca_resource_app,
    azuread_service_principal.sca_resource_app_sp,
    azuread_app_role_assignment.msgraph_group_readwrite,
    azuread_app_role_assignment.msgraph_user_read,
    azuread_app_role_assignment.msgraph_groupmember_readwrite,
    azuread_app_role_assignment.msgraph_group_create,
    azuread_application_federated_identity_credential.sca_resource_credentials,
  ]
}

resource "azurerm_role_definition" "sca_resource_k8s_custom_role" {
  count       = local.create_resource_k8s_role ? 1 : 0
  name        = local.resource_k8s_role_display_name
  scope       = local.role_definition_scope
  description = "SCA Custom role for Azure Kubernetes access"
  permissions {
    actions = [
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action"
    ]
    not_actions = []
  }
  assignable_scopes = [local.role_definition_scope]

  lifecycle {
    ignore_changes = [permissions]
  }
}