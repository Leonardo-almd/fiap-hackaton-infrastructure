variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name."
}

variable "stage_name" {
  type        = string
  description = "API Gateway stage name."
}

variable "api_key_name" {
  type        = string
  description = "API key name."
}

variable "api_key_value" {
  type        = string
  description = "API key value."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
