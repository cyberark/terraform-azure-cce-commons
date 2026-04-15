# CyberArk Azure CCE Commons Module

## Overview

The `terraform-azure-cce-commons` module provides common resources for Azure CCE (Cloud Control and Enumeration) modules, supporting SCA (Secure Cloud Access) service integration. This module serves as a shared resource layer that can be used by other Azure CCE modules (Entra, Subscription, Management Group) to manage SCA service resources.

## Features

- **Conditional SCA Service Resource Creation**: Enable or disable SCA service integration
- **Flexible Resource Management**: Support for both full resource creation and using existing resources
- **Modular Architecture**: Clean separation between root module and service-specific submodules
- **Reusable Across Azure CCE Modules**: Designed to be consumed by other terraform-azure-cce-* modules

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.8.5
3. **Azure Permissions**:
   - Permission to create Azure AD applications and service principals
   - Permission to create custom role definitions
   - Permission to assign roles at appropriate scopes
4. **Appropriate Azure RBAC roles** such as:
   - Application Administrator (for Azure AD app registration)
   - User Access Administrator or Owner (for role assignments)

## Usage

### SCA Entra Onboarding Example (SCA Full/Entra Onboarding)

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
    }
  }
}
```

### Using Existing Resources

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

### SCA Disabled

```hcl
module "cce_azure_shared" {
  source   = "path/to/terraform-azure-cce-commons"
  entra_id = "280a06f4-3f9b-4910-8967-053a914e314e"

  sca = {
    enable = false
  }
}
```

### Accessing Outputs

```hcl
# Access SCA outputs (pass to Entra, MG, Subscription modules as shared_resources)
output "sca" {
  value = module.cce_azure_shared.sca
}

# Or individual fields for downstream modules
output "sca_resource_app_id" {
  value = module.cce_azure_shared.sca != null ? module.cce_azure_shared.sca.resource_app_id : null
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `entra_id` | The Azure Entra ID (tenant ID) | `string` | n/a | yes |
| `sca.enable` | Enable SCA service integration | `bool` | `false` | no |
| `sca.parameters.sca_entra_onboarding` | Create Entra-level SCA app and role (true) or use existing IDs (false) | `bool` | `false` | no |
| `sca.parameters.sca_entra_app_id` | Existing Entra application ID (when sca_entra_onboarding=false) | `string` | `null` | no |
| `sca.parameters.sca_entra_custom_role_id` | Existing Entra custom role ID (when sca_entra_onboarding=false) | `string` | `null` | no |
| `sca.parameters.sca_entra_wif_username` | Existing Entra WIF username (when sca_entra_onboarding=false) | `string` | `null` | no |
| `sca.parameters.sca_resource_app_id` | Existing Resource application ID (when not creating resource app) | `string` | `null` | no |
| `sca.parameters.sca_resource_custom_role_id` | Existing Resource custom role ID (when not creating resource role) | `string` | `null` | no |
| `sca.parameters.sca_resource_wif_username` | Existing Resource WIF username (when not creating resource app) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `sca` | SCA shared resources object (null if SCA is disabled). Pass to Entra, Management Group, and Subscription modules as `shared_resources`. |

**`sca` object fields** (when SCA is enabled):

| Field | Description |
|-------|-------------|
| `entra_app_id` | The SCA Entra application (client) ID |
| `entra_custom_role_id` | The SCA Entra custom role definition resource ID |
| `entra_wif_user_id` | The SCA Entra trusted username (WIF subject) |
| `resource_app_id` | The SCA Resource application (client) ID |
| `resource_custom_role_id` | The SCA Resource custom role definition resource ID |
| `resource_wif_user_id` | The SCA Resource trusted username (WIF subject) |

## What Gets Created

### When SCA is Enabled (full onboarding)

**Entra-level (when `sca_entra_onboarding = true`):**
- Microsoft Entra ID application for SCA Entra
- Custom Azure RBAC role definition at tenant scope (empty permissions; identity scope)
- Federated identity credentials for SCA Entra app
- Microsoft Graph API permissions (Directory, RoleManagement, User, Group) with admin consent

**Resource-level:**
- Microsoft Entra ID application for SCA Resource
- Custom Azure RBAC role definition at tenant scope (permissions for subscriptions, management groups, Resource Graph, role assignments)
- Service principal and federated identity credentials for SCA Resource app
- Role assignment of SCA Resource app to the resource custom role at tenant scope

**Note:** Entra-level role assignment of the SCA Entra app to the Entra custom role is performed by the **Entra module** (`terraform-azure-cce-entra`). Management Group and Subscription modules use `shared_resources` to assign the SCA Resource app at their respective scopes.

## Module Structure

```
terraform-azure-cce-commons/
├── main.tf              # Root module with conditional SCA module call
├── variables.tf         # Input variables
├── outputs.tf           # Module outputs
├── README.md            # This file
├── examples/
│   ├── sca_entra_onboarding/   # Commons → use output in Entra module
│   └── partial_onboarding/    # Commons → use output in MG and Subscription modules
└── services_modules/
    └── sca/
        ├── main.tf      # SCA service resource definitions
        ├── variables.tf # SCA service variables
        └── outputs.tf   # SCA service outputs
```

## Examples

| Example | What it demonstrates |
|--------|------------------------|
| **[sca_entra_onboarding](./examples/sca_entra_onboarding)** | **Commons + Entra.** Get SCA shared resources from Commons and use the output in the **Entra** module (Commons → Entra). |
| **[partial_onboarding](./examples/partial_onboarding)** | **Commons + MG + Subscription.** Get SCA shared resources from Commons and use the output in the **Management Group** and **Subscription** modules (Commons → MG and Subscription). |

Both examples show the same pattern: run Commons, then pass `module.cce_azure_shared.sca` as `shared_resources` into the downstream module(s).

## Documentation

For more information about the CyberArk Identity Security Platform and Azure CCE integration:
- [CyberArk Documentation](https://docs.cyberark.com/)
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
