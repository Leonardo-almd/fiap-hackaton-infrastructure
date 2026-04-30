variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ECS services."
}

variable "ecs_sg_id" {
  type        = string
  description = "Security group ID for ECS."
}

variable "cpu" {
  type        = number
  description = "CPU units for ECS tasks."
}

variable "memory" {
  type        = number
  description = "Memory for ECS tasks."
}

variable "upload_image" {
  type        = string
  description = "Upload service image."
}

variable "report_image" {
  type        = string
  description = "Report service image."
}

variable "processing_image" {
  type        = string
  description = "Processing service image."
}

variable "upload_tg_arn" {
  type        = string
  description = "Upload target group ARN."
}

variable "report_tg_arn" {
  type        = string
  description = "Report target group ARN."
}

variable "execution_role_arn" {
  type        = string
  description = "ECS execution role ARN."
}

variable "upload_task_role_arn" {
  type        = string
  description = "Upload task role ARN."
}

variable "report_task_role_arn" {
  type        = string
  description = "Report task role ARN."
}

variable "processing_task_role_arn" {
  type        = string
  description = "Processing task role ARN."
}

variable "log_group_upload" {
  type        = string
  description = "Log group for upload service."
}

variable "log_group_report" {
  type        = string
  description = "Log group for report service."
}

variable "log_group_processing" {
  type        = string
  description = "Log group for processing service."
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name."
}

variable "sqs_queue_url" {
  type        = string
  description = "SQS queue URL."
}

variable "db_host" {
  type        = string
  description = "RDS hostname."
}

variable "db_port" {
  type        = number
  description = "RDS port."
}

variable "db_name_upload" {
  type        = string
  description = "Upload database name."
}

variable "db_name_report" {
  type        = string
  description = "Report database name."
}

variable "db_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for DB credentials."
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name for internal service calls."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
