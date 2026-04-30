variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "bucket_arn" {
  type        = string
  description = "S3 bucket ARN."
}

variable "queue_arn" {
  type        = string
  description = "SQS queue ARN."
}

variable "db_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for DB credentials."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
