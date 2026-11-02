output "secrets_hub" {
  value       = module.cce_azure_shared.secrets_hub
  description = "Secrets Hub shared resources (pass to the Entra or Management Group module as shared_resources)."
}

output "secrets_hub_app_id" {
  value       = module.cce_azure_shared.secrets_hub.app_id
  description = "The Secrets Hub application (client) ID (from the Commons output)."
}
