output "cloud_discovery" {
  value       = module.cce_azure_shared.cds
  description = "Cloud Discovery shared resources from Commons (passed to the Entra, management group or subscription modules)"
}
