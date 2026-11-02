variable "entra_id" {
  description = "The Microsoft Entra tenant ID."
  type        = string
}

variable "tenant_id" {
  description = "The Idira tenant ID from idsec provider."
  type        = string
}

variable "identity_issuer" {
  description = "The Secrets Hub Identity issuer for the federated credential."
  type        = string
  nullable    = true
}

variable "identity_audience" {
  description = "The Secrets Hub Identity audience for the federated credential."
  type        = string
  nullable    = true
}
