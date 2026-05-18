variable "tfc_organization" {
  type        = string
  description = "Terraform Cloud organization name."
}

variable "tfc_workspace" {
  type        = string
  description = "Terraform Cloud workspace name."
  default     = "fiap-hackaton-prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources."
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Project slug used for naming."
  default     = "fiap-hackaton"
}

variable "environment" {
  type        = string
  description = "Environment name used for naming."
  default     = "prod"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets."
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "RDS allocated storage in GB."
  default     = 20
}

variable "db_name_upload" {
  type        = string
  description = "Primary database name for upload-service."
  default     = "upload_db"
}

variable "db_name_report" {
  type        = string
  description = "Logical database name for report-service."
  default     = "report_db"
}

variable "create_report_db" {
  type        = bool
  description = "Whether to create the report database after RDS is available."
  default     = true
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

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket for diagram uploads."
  default     = "fiap-hackaton-prod-diagrams"
}

variable "sqs_queue_name" {
  type        = string
  description = "SQS queue name for diagram analysis."
  default     = "fiap-hackaton-prod-diagram-analysis"
}

variable "sqs_dlq_name" {
  type        = string
  description = "SQS DLQ name for diagram analysis."
  default     = "fiap-hackaton-prod-diagram-analysis-dlq"
}

variable "api_gw_stage" {
  type        = string
  description = "API Gateway stage name."
  default     = "prod"
}

variable "api_key_name" {
  type        = string
  description = "API Gateway API key name."
  default     = "fiap-hackaton-prod-apikey"
}

variable "api_key_value" {
  type        = string
  description = "API key value required for API Gateway."
  sensitive   = true
}

variable "ecs_cpu" {
  type        = number
  description = "CPU units for ECS tasks."
  default     = 256
}

variable "ecs_memory" {
  type        = number
  description = "Memory (MiB) for ECS tasks."
  default     = 512
}

variable "upload_image" {
  type        = string
  description = "Container image for upload-service."
}

variable "report_image" {
  type        = string
  description = "Container image for report-service."
}

variable "processing_image" {
  type        = string
  description = "Container image for processing-service."
}

variable "ai_adapter" {
  type        = string
  description = "AI adapter to use in processing-service."
  default     = "bedrock"
}

variable "bedrock_model_id" {
  type        = string
  description = "Base Amazon Bedrock model ID (without cross-region prefix)."
  default     = "anthropic.claude-sonnet-4-5-20250929-v1:0"
}

variable "bedrock_model_id_prefix" {
  type        = string
  description = "Cross-region prefix for the Bedrock model ID (e.g., global, us)."
  default     = "global"
}

variable "bedrock_region" {
  type        = string
  description = "Amazon Bedrock region used by processing-service."
  default     = "us-east-1"
}

variable "alb_allowed_cidrs" {
  type        = list(string)
  description = "Allowed CIDRs to access the ALB."
  default     = ["0.0.0.0/0"]
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days."
  default     = 3
}

variable "tags" {
  type        = map(string)
  description = "Additional tags for all resources."
  default     = {}
}
