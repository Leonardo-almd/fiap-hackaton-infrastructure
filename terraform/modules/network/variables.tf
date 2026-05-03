variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
