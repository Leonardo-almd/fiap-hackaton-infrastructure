variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "retention_days" {
  type        = number
  description = "Log retention in days."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
