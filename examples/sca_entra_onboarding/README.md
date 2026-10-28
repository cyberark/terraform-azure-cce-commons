
# Example: SCA Entra Onboarding (CCE Commons + Entra)

**Gets data from Commons and uses it in the Entra module** — runs Commons (creates SCA shared resources), then passes the Commons `sca` output into the Entra module so SCA is onboarded at Entra scope (role assignment, idsec registration).

This example demonstrates: create SCA shared resources with the Commons module, then use that output in the **Entra** module for full SCA Entra onboarding.

## What This Example Does

* Creates the shared SCA resources within the Commons module (Entra app, Entra custom role, Resource app, Resource custom role, federated credentials)
* Passes the Commons `sca` output to the **Entra module** as `shared_resources`, so the Entra module performs SCA role assignment at Entra scope and registers the tenant with idsec
* Outputs the `sca` object for use elsewhere (for example, management group or subscription modules) if needed

## Prerequisites

* Azure subscription and Microsoft Entra tenant
* Idira tenant with CCE and idsec provider configured
* Terraform >= 1.8.5
* Idira `idsec` provider configured — https://registry.terraform.io/providers/cyberark/idsec/latest/docs#example-usage
* Appropriate Azure permissions (Application Administrator, User Access Administrator or Owner)
* The `terraform-azure-cce-entra` module available locally (or set `entra_module_source` in tfvars)

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values:

    ```hcl
    entra_id = "0b659685-1a00-43cd-b994-555bac390ecf"
    ```

2. Configure the idsec provider (for example, via environment variables or a provider block) with your Idira tenant credentials.

3. Initialize Terraform:

    ```bash
    terraform init
    ```

4. Review the plan:

    ```bash
    terraform plan
    ```

5. Apply the configuration:

    ```bash
    terraform apply
    ```

## What Gets Created

### In Azure (when SCA is enabled)

**SCA Entra (when sca_entra_onboarding = true):**
* Microsoft Entra ID application for SCA Entra
* Custom Azure RBAC role definition at tenant scope (identity scope, empty actions)
* Federated identity credentials for SCA Entra app
* Microsoft Graph API permissions (Directory, RoleManagement, User, Group) with admin consent

**SCA Resource:**
* Microsoft Entra ID application for SCA Resource
* Custom Azure RBAC role definition at tenant scope (subscriptions, management groups, Resource Graph, role assignments)
* Service principal and federated identity credentials for SCA Resource app

**Optional AKS permissions:** Set `add_permissions_to_manage_cluster = true` in Commons `sca.parameters` to create a K8s custom role (pass through `sca` output to Entra/management group/subscription for scope assignment).

**Note:** The Commons module does not create role assignments; they are handled by downstream modules. The Entra app assignment is managed by the Entra module, while the Resource app assignment is managed by the management group and subscription modules. Pass this example's `sca` output into those modules as `shared_resources`.

## Outputs

This example outputs:

* `sca` — The SCA shared resources object (entra_app_id, entra_custom_role_id, entra_wif_user_id, resource_app_id, resource_custom_role_id, resource_wif_user_id). Pass to downstream modules as `sca.shared_resources`.

## Next Steps

After successful deployment, the Entra scope is already onboarded to SCA by this example. To onboard management group or subscription to SCA, use the same pattern: pass the `sca` output (from Commons) to the management group or subscription module as `sca = { enable = true, shared_resources = module.cce_azure_shared.sca }` — see the [sca_partial_onboarding](../sca_partial_onboarding) example.
