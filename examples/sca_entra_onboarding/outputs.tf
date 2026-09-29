output "sca" {
  value       = module.cce_azure_shared.sca
  description = "SCA shared resources (pass to Microsoft Entra tenant, management group, subscription modules as shared_resources)."
}
