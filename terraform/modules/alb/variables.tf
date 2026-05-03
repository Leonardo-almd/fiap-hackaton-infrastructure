variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB."
}

variable "alb_sg_id" {
  type        = string
  description = "ALB security group ID."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
