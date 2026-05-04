variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class."
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage in GB."
}

variable "db_name_upload" {
  type        = string
  description = "Primary database name."
}

variable "db_name_report" {
  type        = string
  description = "Logical database name for report-service."
}

variable "create_report_db" {
  type        = bool
  description = "Whether to create the report database after RDS is available."
}

variable "db_username" {
  type        = string
  description = "Master DB username."
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Master DB password."
  sensitive   = true
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for RDS."
}

variable "lambda_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the Lambda running DB initialization."
}

variable "lambda_security_group_id" {
  type        = string
  description = "Security group ID for the Lambda running DB initialization."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for RDS."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
