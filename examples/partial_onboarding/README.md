# Example: Partial Onboarding (Management Group + Subscription)

**Gets data from Commons and uses it in the MG and Subscription modules** — runs Commons (creates SCA shared resources), then passes the Commons `sca` output into both the Management Group and Subscription modules so SCA is onboarded at those scopes.

This example demonstrates the same pattern as [sca_entra_onboarding](../sca_entra_onboarding) but with **Management Group and Subscription** instead of Entra. It uses the Commons module to create SCA shared resources, then passes them to the Management Group and Subscription modules so the SCA Resource app is assigned at each scope.

## What This Example Does

* Creates SCA shared resources via the Commons module (same as the [SCA Entra onboarding example](../sca_entra_onboarding))
* Onboards one Management Group to SCA using `shared_resources` from Commons
* Onboards one Subscription to SCA using the same `shared_resources`

**Note:** This example does not run the Entra module. For full SCA Entra onboarding (Entra app + role assignment at Entra scope), use the [sca_entra_onboarding](../sca_entra_onboarding) example first, then add Entra module in your root configuration.

## Prerequisites

* Same as [sca_entra_onboarding](../sca_entra_onboarding), plus:
* The `terraform-azure-cce-management-group` and `terraform-azure-cce-subscription` modules available locally (or set `mg_module_source` and `subscription_module_source` to your paths)

## Usage

1. Set the module source paths in `terraform.tfvars` (or use the defaults if the MG and Subscription modules are siblings of `terraform-azure-cce-commons`):

    ```hcl
    mg_module_source        = "../../../terraform-azure-cce-management-group"
    subscription_module_source = "../../../terraform-azure-cce-subscription"
    ```

2. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `entra_id`, `subscription_id`, `management_group_id`, `entra_tenant_name`, `subscription_name`, and optional `identity_cloud_tenant_num`.

3. Configure the idsec provider and run:

    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

## Outputs

* `sca` - SCA shared resources from Commons (for use with Entra or other modules)
