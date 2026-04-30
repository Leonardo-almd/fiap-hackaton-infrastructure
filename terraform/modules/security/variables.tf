variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "alb_allowed_cidrs" {
  type        = list(string)
  description = "Allowed CIDRs for ALB access."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
