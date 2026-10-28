variable "entra_id" {
  description = "The Microsoft Entra tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID for the azurerm provider (and the subscription module, for partial onboarding)."
  type        = string
}

variable "cloud_discovery_commons_enable" {
  description = "Enable Cloud Discovery in Commons (creates the two Cloud Discovery applications and their custom roles). When offboarding, set it to false only after every level flag in use (cloud_discovery_entra_enable, or cloud_discovery_management_group_enable and cloud_discovery_subscription_enable) has been set to false and applied."
  type        = bool
  default     = true
}

variable "cloud_discovery_entra_enable" {
  description = "Enable Cloud Discovery for the Microsoft Entra tenant (Entra module). Requires cloud_discovery_commons_enable = true. Set it to false and apply first when offboarding."
  type        = bool
  default     = true
}

# Partial onboarding: used by the management group and subscription modules in main.tf

variable "management_group_id" {
  description = "The Azure management group ID (for the management group module). Required when cloud_discovery_management_group_enable = true."
  type        = string
  default     = null
}

variable "entra_tenant_name" {
  description = "The Microsoft Entra tenant name (for the subscription module). Required when cloud_discovery_subscription_enable = true."
  type        = string
  default     = null
}

variable "subscription_name" {
  description = "The Azure subscription display name (for the subscription module). Required when cloud_discovery_subscription_enable = true."
  type        = string
  default     = null
}

variable "cloud_discovery_management_group_enable" {
  description = "Enable Cloud Discovery for the management group (management group module). Requires cloud_discovery_commons_enable = true. Set it to false and apply first when offboarding."
  type        = bool
  default     = false
}

variable "cloud_discovery_subscription_enable" {
  description = "Enable Cloud Discovery for the subscription (subscription module). Requires cloud_discovery_commons_enable = true. Set it to false and apply first when offboarding."
  type        = bool
  default     = false
}
