# Example: Secrets Hub (CCE Commons + Entra)

**Onboards Secrets Hub at the Entra (root management group) scope.** The Commons module creates the shared Secrets Hub identity, and its `secrets_hub` output is passed to the Entra module, which assigns the roles and registers Secrets Hub in CCE.

## What This Example Does

* Creates the shared Secrets Hub identity within the Commons module (application, service principal, federated identity credential, custom role)
* Passes the Commons `secrets_hub` output to the **Entra module** as `secrets_hub.shared_resources`, so the Entra module assigns the roles at the root management group and registers `secrets_hub` in the Entra onboarding
* Outputs the `secrets_hub` object and the Secrets Hub application ID

## Prerequisites

* Microsoft Entra tenant and an Azure subscription (the subscription is required by the azurerm v4 provider, even for Entra-only onboarding)
* Azure CLI installed and authenticated (for example, `az login`)
* Azure permissions: Application Administrator (app, service principal, federated credential), and Owner or User Access Administrator at the root management group (custom role and role assignments)
* Idira tenant with CCE and Secrets Hub activated on the tenant
* Terraform >= 1.8.5
* Idira `idsec` provider 0.12.1 configured ([provider docs](https://registry.terraform.io/providers/cyberark/idsec/latest/docs#example-usage))

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values:

    ```hcl
    entra_id        = "00000000-0000-0000-0000-000000000000"
    subscription_id = "00000000-0000-0000-0000-000000000000"
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

### In Azure

* Microsoft Entra ID application and service principal `idira-secrets-hub-app-<t>-<e>`, tagged `secrets_hub-version:<version>`
* Federated identity credential `Idira-SecretsHub-Azure-Access`
* Custom Azure RBAC role `idira-secrets-hub-role-<t>-<e>` at the root management group
* Two role assignments at the root management group (Entra module): the custom role and `Key Vault Secrets Officer`

`<t>` and `<e>` are the last segment of the Idira tenant ID (from the idsec data source) and of the Entra ID. See the [Resources Created](../../README.md#resources-created) section of the root README.

### In CCE

* The Entra onboarding is registered with a `secrets_hub` entry for the application above

## Outputs

* `secrets_hub` — The Secrets Hub shared resources object (app_id, custom_role_id, identity_trusted_username). Pass it to downstream modules as `secrets_hub.shared_resources`.
* `secrets_hub_app_id` — The Secrets Hub application (client) ID (from the Commons `secrets_hub` output).

## Removing Secrets Hub

In `main.tf`, set `secrets_hub = { enable = false }` in both the `cce_azure_shared` (Commons) and `cce_entra` module blocks, and run one `terraform apply`, or run `terraform destroy` to remove everything. See [Removing Secrets Hub](../../README.md#removing-secrets-hub).

## Next Steps

A tenant is onboarded with Secrets Hub at one scope only. To onboard a management group instead of the Entra (root management group) scope, use the `examples/secrets_hub` example of the [`terraform-azure-cce-management-group`](https://github.com/cyberark/terraform-azure-cce-management-group) module.
