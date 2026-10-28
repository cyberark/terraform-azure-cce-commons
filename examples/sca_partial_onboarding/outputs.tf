output "sca" {
  value       = module.cce_azure_shared.sca
  description = "SCA shared resources from Commons (for use with Microsoft Entra tenant or other modules)"
}
