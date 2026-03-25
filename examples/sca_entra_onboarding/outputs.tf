output "sca" {
  value       = module.cce_azure_shared.sca
  description = "SCA shared resources (pass to Entra, MG, Subscription modules as shared_resources)"
}
