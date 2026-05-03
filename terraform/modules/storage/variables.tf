variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
