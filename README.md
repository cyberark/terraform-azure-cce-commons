# CCE Azure Commons Module

## Overview

The `terraform-azure-cce-commons` module creates the Azure resources that SCA (Secure Cloud Access) and Cloud Discovery (for Cloud service entitlements) share across Azure CCE (Connect cloud environments) onboarding. The Microsoft Entra tenant, subscription, and management group modules consume its outputs, so these resources are created once and reused.

## Features

- **Conditional SCA Service Resource Creation**: Enable or disable SCA service integration
- **Conditional Cloud Discovery Resource Creation**: Enable or disable Cloud Discovery. Its shared resources are created once per Microsoft Entra tenant and used by every onboarded level
- **Flexible Resource Management**: Support for both full resource creation and using existing resources
- **Modular Architecture**: Clean separation between root module and service-specific submodules
- **Reusable Across Azure CCE Modules**: Designed to be consumed by other terraform-azure-cce-* modules
- **Optional AKS cluster permissions**: When `add_permissions_to_manage_cluster` is true, creates a K8s custom role (unless `sca_resource_k8s_custom_role_id` is provided) for downstream Entra/management group/subscription assignment

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.8.5
3. **Idira tenant** with the services enabled and activated (SCA, Cloud Discovery), and credentials for the `idsec` provider — https://registry.terraform.io/providers/cyberark/idsec/latest/docs
4. **Azure Permissions**:
   - Permission to create Azure AD applications and service principals
   - Permission to create custom role definitions
   - Permission to assign roles at appropriate scopes
5. **Appropriate Azure RBAC roles** such as:
   - Application Administrator (for Azure AD app registration)
   - User Access Administrator or Owner (for role assignments)

## Usage

### SCA

#### Entra Onboarding (Create New Resources)

```hcl
module "cce_azure_shared" {
  source   = "path/to/terraform-azure-cce-commons"
  entra_id = "280a06f4-3f9b-4910-8967-053a914e314e"

  sca = {
    enable = true
    parameters = {
      sca_entra_onboarding        = true
      sca_entra_app_id            = null
      sca_entra_custom_role_id    = null
      sca_entra_wif_username      = null
      sca_resource_app_id         = null
      sca_resource_custom_role_id = null
      sca_resource_wif_username   = null
      # Optional: grant AKS-related RBAC (creates K8s custom role when sca_resource_k8s_custom_role_id is null)
      # add_permissions_to_manage_cluster   = true
      # sca_resource_k8s_custom_role_id     = null
    }
  }
}
```

#### Using Existing Resources

```hcl
module "cce_azure_shared" {
  source   = "path/to/terraform-azure-cce-commons"
  entra_id = "280a06f4-3f9b-4910-8967-053a914e314e"

  sca = {
    enable = true
    parameters = {
      sca_entra_onboarding        = false
      sca_entra_app_id            = "existing-entra-app-id"
      sca_entra_custom_role_id    = "existing-entra-role-id"
      sca_entra_wif_username      = "existing-entra-wif-username"
      sca_resource_app_id         = "existing-resource-app-id"
      sca_resource_custom_role_id = "existing-resource-role-id"
      sca_resource_wif_username   = "existing-resource-wif-username"
    }
  }
}
```

#### SCA Disabled

```hcl
module "cce_azure_shared" {
  source   = "path/to/terraform-azure-cce-commons"
  entra_id = "280a06f4-3f9b-4910-8967-053a914e314e"

  sca = {
    enable = false
  }
}
```

### Cloud Discovery

#### Onboarding

```hcl
module "cce_azure_shared" {
  source   = "path/to/terraform-azure-cce-commons"
  entra_id = "280a06f4-3f9b-4910-8967-053a914e314e"

  cds = {
    enable = true
  }
}
```

Then pass `module.cce_azure_shared.cds` as `cds.shared_resources` to the Entra module, or to the management group and subscription modules for partial onboarding, and run `terraform apply`. For the full steps, see the [cloud_discovery_onboarding](./examples/cloud_discovery_onboarding) example.

#### Offboarding

Use the same configuration and state you onboarded with, and change only the `cds.enable` values. This removes only Cloud Discovery. Other services onboarded with the same modules stay onboarded.

Do not remove module blocks or run `terraform destroy`. This will offboard every service, not only Cloud Discovery.

1. **Offboard each level.** Set `cds.enable = false` on every Entra, management group and subscription module that uses Cloud Discovery, and run `terraform apply`. To keep Cloud Discovery on some modules, set `cds.enable = false` only on the modules you want to offboard, run `terraform apply`, and skip step 2. The shared resources must stay while any module still uses Cloud Discovery.
2. **Delete the shared resources.** Only after every level is offboarded (all of them set to `false` and applied), set `cds.enable = false` on this module and run `terraform apply`.

If you disable Cloud Discovery here while a level is still onboarded, nothing is deleted:

- In the same Terraform configuration, the plan fails.
- In separate Terraform configurations, the apply fails with `RoleDefinitionHasAssignments`. Offboard the remaining levels, then apply Commons again.

### Accessing Outputs

```hcl
# Access SCA outputs (pass to Entra, management group, subscription modules as shared_resources)
output "sca" {
  value = module.cce_azure_shared.sca
}

# Access Cloud Discovery outputs (pass to Entra, management group, subscription modules as cds.shared_resources)
output "cds" {
  value = module.cce_azure_shared.cds
}

# Or individual fields for downstream modules
output "sca_resource_app_id" {
  value = module.cce_azure_shared.sca != null ? module.cce_azure_shared.sca.resource_app_id : null
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `entra_id` | The Microsoft Entra tenant ID | `string` | n/a | yes |
| `sca.enable` | Enable SCA service integration | `bool` | `false` | no |
| `sca.parameters.sca_entra_onboarding` | Create Entra-level SCA app and role (true) or use existing IDs (false) | `bool` | `false` | no |
| `sca.parameters.sca_entra_app_id` | Existing Entra application ID (when sca_entra_onboarding=false) | `string` | `null` | no |
| `sca.parameters.sca_entra_custom_role_id` | Existing Entra custom role ID (when sca_entra_onboarding=false) | `string` | `null` | no |
| `sca.parameters.sca_entra_wif_username` | Existing Entra WIF username (when sca_entra_onboarding=false) | `string` | `null` | no |
| `sca.parameters.sca_resource_app_id` | Existing Resource application ID (when not creating resource app) | `string` | `null` | no |
| `sca.parameters.sca_resource_custom_role_id` | Existing Resource custom role ID (when not creating resource role) | `string` | `null` | no |
| `sca.parameters.sca_resource_wif_username` | Existing Resource WIF username (when not creating resource app) | `string` | `null` | no |
| `sca.parameters.add_permissions_to_manage_cluster` | When true, enables optional AKS cluster RBAC (custom role + assignment at tenant scope) | `bool` | `false` | no |
| `sca.parameters.sca_resource_k8s_custom_role_id` | Existing K8s custom role definition id; when null and flag is true, commons creates the role | `string` | `null` | no |
| `cds.enable` | Enable Cloud Discovery (creates its shared resources, once per Microsoft Entra tenant) | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `sca` | SCA shared resources object (null if SCA is disabled). Pass to Entra, management group, and subscription modules as `shared_resources`. |
| `cds` | Cloud Discovery shared resources object (null if Cloud Discovery is disabled). Pass to Entra, management group, and subscription modules as `cds.shared_resources`. |

### `sca` Object Fields

When SCA is enabled:

| Field | Description |
|-------|-------------|
| `entra_app_id` | The SCA Entra application (client) ID |
| `entra_custom_role_id` | The SCA Entra custom role definition resource ID |
| `entra_wif_user_id` | The SCA Entra trusted username (WIF subject) |
| `resource_app_id` | The SCA Resource application (client) ID |
| `resource_custom_role_id` | The SCA Resource custom role definition resource ID |
| `resource_wif_user_id` | The SCA Resource trusted username (WIF subject) |
| `add_permissions_to_manage_cluster` | Whether AKS/cluster permissions are enabled |
| `resource_k8s_custom_role_id` | K8s custom role definition id (null when flag is false) |

### `cds` Object Fields

When Cloud Discovery is enabled:

| Field | Description |
|-------|-------------|
| `entra_app_id` | The Cloud Discovery Entra application (client) ID |
| `entra_custom_role_id` | The Cloud Discovery Entra custom role definition resource ID |
| `entra_wif_user_id` | The Cloud Discovery Entra trusted username (WIF subject) |
| `resource_app_id` | The Cloud Discovery Resource application (client) ID |
| `resource_custom_role_id` | The Cloud Discovery Resource custom role definition resource ID |
| `resource_wif_user_id` | The Cloud Discovery Resource trusted username (WIF subject) |

## What Gets Created

### When SCA is Enabled (Full Onboarding)

#### Entra Level (when `sca_entra_onboarding = true`)

- Microsoft Entra ID application for SCA Entra
- Custom Azure RBAC role definition at tenant scope (empty permissions; identity scope)
- Federated identity credentials for SCA Entra app
- Microsoft Graph API permissions (Directory, RoleManagement, User, Group) with admin consent

#### Resource Level

- Microsoft Entra ID application for SCA Resource
- Custom Azure RBAC role definition at tenant scope (permissions for subscriptions, management groups, Resource Graph, role assignments)
- Service principal and federated identity credentials for SCA Resource app

#### AKS Cluster Permissions (when `add_permissions_to_manage_cluster = true`)

- Custom Azure RBAC role for AKS/cluster management (unless `sca_resource_k8s_custom_role_id` is supplied)
- Role assignment of the SCA Resource app to the K8s custom role at tenant scope

**Note:** This module does not create role assignments. The **Entra module** (`terraform-azure-cce-entra`) assigns the SCA Entra application to the custom Entra role. The **management group** and **subscription** modules use `shared_resources` to assign the SCA Resource application to the custom Azure roles at each onboarded scope.

### When Cloud Discovery is Enabled

#### Entra App (Microsoft Graph Reads)

- Microsoft Entra ID application and service principal for Cloud Discovery Entra
- Federated identity credential for the Cloud Discovery Entra app
- Microsoft Graph API permissions (AuditLog.Read.All, Directory.Read.All, User.ReadBasic.All) with admin consent
- Custom Azure RBAC role definition at the root management group (empty permissions)
- Role assignment of the Cloud Discovery Entra app to its custom role at the root management group

#### Resource App (Azure RBAC Reads)

- Microsoft Entra ID application and service principal for Cloud Discovery Resource
- Federated identity credential for the Cloud Discovery Resource app
- Custom Azure RBAC role definition at the root management group (`Microsoft.Authorization/*/read`)

**Note:** Cloud Discovery uses both applications at every onboarded level, so the Entra app's root management group assignment is created here, once per tenant. The **Entra**, **management group** and **subscription** modules use `cds.shared_resources` to assign the Cloud Discovery Resource application to its custom role at each onboarded level.

## Module Structure

```
terraform-azure-cce-commons/
├── main.tf              # Root module with conditional SCA and Cloud Discovery module calls
├── variables.tf         # Input variables
├── outputs.tf           # Module outputs
├── README.md            # This file
├── examples/
│   ├── sca_entra_onboarding/   # Commons → use output in Entra module
│   ├── sca_partial_onboarding/ # Commons → use output in management group and subscription modules
│   └── cloud_discovery_onboarding/ # Commons → use Cloud Discovery output in Entra (or management group and subscription) modules
└── modules/
    ├── sca/
    │   ├── main.tf      # SCA service resource definitions
    │   ├── variables.tf # SCA service variables
    │   └── outputs.tf   # SCA service outputs
    └── cds/
        ├── main.tf      # Cloud Discovery resource definitions
        ├── variables.tf # Cloud Discovery variables
        └── outputs.tf   # Cloud Discovery outputs
```

## Examples

| Example | What it demonstrates |
|--------|------------------------|
| **[sca_entra_onboarding](./examples/sca_entra_onboarding)** | **Commons + Entra.** Get SCA shared resources from Commons and use the output in the **Entra** module (Commons → Entra). |
| **[sca_partial_onboarding](./examples/sca_partial_onboarding)** | **Commons + management group + subscription.** Get SCA shared resources from Commons and use the output in the **management group** and **subscription** modules (Commons → management group and subscription). |
| **[cloud_discovery_onboarding](./examples/cloud_discovery_onboarding)** | **Commons + Entra (or management group + subscription).** Get Cloud Discovery shared resources from Commons and use the output in the **Entra** module, or in the **management group** and **subscription** modules for partial onboarding, including the offboarding steps. |

All examples show the same pattern: run Commons, then pass `module.cce_azure_shared.sca` (or `.cds`) as `sca.shared_resources` (or `cds.shared_resources`) into the downstream module(s).

## Documentation

For more information about the Idira Identity Security Platform and Azure CCE integration:
- [CCE Documentation](https://docs.cyberark.com/)
- Related modules:
  - `terraform-azure-cce-entra`
  - `terraform-azure-cce-subscription`
  - `terraform-azure-cce-management-group`

## Licensing

This repository is subject to the following licenses:
- **CyberArk Privileged Access Manager**: Licensed under the [CyberArk Software EULA](https://www.cyberark.com/EULA.pdf).
- **Terraform templates**: Licensed under the Apache License, Version 2.0 ([LICENSE](LICENSE.txt)).

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for more details.

## About

CyberArk is a global leader in **Identity Security**, providing powerful solutions for managing privileged access. Learn more at [www.cyberark.com](https://www.cyberark.com).
