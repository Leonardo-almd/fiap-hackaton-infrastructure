variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "queue_name" {
  type        = string
  description = "Main SQS queue name."
}

variable "dlq_name" {
  type        = string
  description = "Dead letter queue name."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
