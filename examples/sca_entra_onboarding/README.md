
# Example: SCA Entra Onboarding (CCE Commons + Entra)

**Gets data from Commons and uses it in the Entra module** — runs Commons (creates SCA shared resources), then passes the Commons `sca` output into the Entra module so SCA is onboarded at Entra scope (role assignment, idsec registration).

This example demonstrates: create SCA shared resources with the Commons module, then use that output in the **Entra** module for full SCA Entra onboarding.

## What This Example Does

* Creates SCA shared resources in the Commons module (Entra app, Entra custom role, Resource app, Resource custom role, federated credentials, and role assignment at tenant scope)
* Passes the Commons `sca` output to the **Entra module** as `shared_resources`, so the Entra module performs SCA role assignment at Entra scope and registers the tenant with idsec
* Outputs the `sca` object for use elsewhere (e.g. MG or Subscription modules) if needed

## Prerequisites

* Azure subscription and Microsoft Entra tenant
* CyberArk tenant with CCE and idsec provider configured
* Terraform >= 1.8.5
* CyberArk `idsec` provider configured — https://registry.terraform.io/providers/cyberark/idsec/latest/docs#example-usage
* Appropriate Azure permissions (Application Administrator, User Access Administrator or Owner)
* The `terraform-azure-cce-entra` module available locally (or set `entra_module_source` in tfvars)

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values:

    ```hcl
    entra_id                 = "0b659685-1a00-43cd-b994-555bac390ecf"
    identity_cloud_tenant_num = "46747"  # Optional: match your Identity suffix for SCA usernames
    ```

2. Configure the idsec provider (e.g. environment variables or provider block) with your CyberArk credentials.

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
* Role assignment of SCA Resource app to the resource custom role at tenant scope

**Note:** Entra-level role assignment (SCA Entra app → Entra custom role) is done by the Entra module. Use this module's `sca` output as `shared_resources` in Entra, Management Group, and Subscription modules.

## Outputs

This example outputs:

* `sca` — The SCA shared resources object (entra_app_id, entra_custom_role_id, entra_wif_user_id, resource_app_id, resource_custom_role_id, resource_wif_user_id). Pass to downstream modules as `sca.shared_resources`.

## Next Steps

After successful deployment, the Entra scope is already onboarded to SCA by this example. To onboard Management Group or Subscription to SCA, use the same pattern: pass the `sca` output (from Commons) to the MG or Subscription module as `sca = { enable = true, shared_resources = module.cce_azure_shared.sca }` — see the [partial_onboarding](../partial_onboarding) example.
