variable "entra_id" {
  description = "The Microsoft Entra tenant ID."
  type        = string
}

variable "tenant_id" {
  description = "The Idira tenant ID from idsec provider."
  type        = string
}

variable "identity_issuer" {
  description = "The Identity issuer for federated credentials."
  type        = string
}

variable "identity_audience" {
  description = "The Identity audience for federated credentials."
  type        = string
}
