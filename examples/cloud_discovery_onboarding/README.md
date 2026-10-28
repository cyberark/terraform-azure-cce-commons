# Example: Cloud Discovery Onboarding

Onboard your Microsoft Entra tenant to Cloud Discovery (for Cloud service entitlements) with one `terraform apply`, or onboard only specific management groups and subscriptions.

## Prerequisites

* Terraform >= 1.8.5
* Azure CLI, signed in with `az login`
* An Idira tenant with Cloud Discovery activated, and credentials for the `idsec` provider
* Appropriate Azure permissions (see [Prerequisites](../../README.md#prerequisites) in the Commons README)

## Onboard the Microsoft Entra Tenant

1. Copy `terraform.tfvars.example` to `terraform.tfvars`.
2. Set `entra_id` and `subscription_id`. Leave `cloud_discovery_commons_enable` and `cloud_discovery_entra_enable` set to `true`, and the management group and subscription flags set to `false`.
3. In `main.tf`, configure the `idsec` provider block with your Idira tenant credentials — https://registry.terraform.io/providers/cyberark/idsec/latest/docs
4. Run:

    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

This onboards every management group and subscription in the tenant.

## Onboard Specific Management Groups or Subscriptions

1. Follow steps 1–3 of [Onboard the Microsoft Entra Tenant](#onboard-the-microsoft-entra-tenant).
2. In `terraform.tfvars`, set `cloud_discovery_entra_enable = false`, then set the variables of the levels you want to onboard:
   * management group: `management_group_id`, and `cloud_discovery_management_group_enable = true`
   * subscription: `entra_tenant_name`, `subscription_name`, and `cloud_discovery_subscription_enable = true`
3. Run `terraform init`, `terraform plan` and `terraform apply`.

To onboard more management groups or subscriptions, add a module block for each one. Give each block its own enable flag so you can offboard it on its own.

## Offboard

Use the same configuration and state you onboarded with, and change only the Cloud Discovery flags in `terraform.tfvars`. This removes only Cloud Discovery. Other services onboarded with the same modules stay onboarded.

Do not remove module blocks or run `terraform destroy`. This will offboard every service, not only Cloud Discovery.

1. **Offboard each level.** Set the flag of each onboarded level to `false` and run `terraform apply`:
   * Entra tenant: `cloud_discovery_entra_enable`
   * Management groups and subscriptions: `cloud_discovery_management_group_enable` and `cloud_discovery_subscription_enable`

   To offboard only some levels, disable only their flags and stop here.
2. **Delete the shared resources.** Only after every level is offboarded (all level flags set to `false` and applied), set `cloud_discovery_commons_enable = false` and run `terraform apply`.

If you disable Commons while a level is still onboarded, nothing is deleted:

* In this configuration, the plan fails.
* If Commons and the level modules are in separate Terraform configurations, the apply fails with `RoleDefinitionHasAssignments`. Offboard the remaining levels, then apply Commons again.

## Outputs

* `cloud_discovery` - Cloud Discovery shared resources from Commons
