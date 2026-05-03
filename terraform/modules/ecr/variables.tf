variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
