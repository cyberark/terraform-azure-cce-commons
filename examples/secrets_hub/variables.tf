variable "entra_id" {
  description = "The Microsoft Entra tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID for the provider (azurerm v4 requires it, even for Entra-only onboarding)."
  type        = string
}
