provider "aws" {
  region = var.aws_region
}

module "network" {
  source               = "./modules/network"
  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "security" {
  source            = "./modules/security"
  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  alb_allowed_cidrs = var.alb_allowed_cidrs
  tags              = local.common_tags
}

module "storage" {
  source       = "./modules/storage"
  name_prefix  = local.name_prefix
  bucket_name  = var.s3_bucket_name
  tags         = local.common_tags
}

module "messaging" {
  source       = "./modules/messaging"
  name_prefix  = local.name_prefix
  queue_name   = var.sqs_queue_name
  dlq_name     = var.sqs_dlq_name
  tags         = local.common_tags
}

module "rds" {
  source               = "./modules/rds"
  name_prefix          = local.name_prefix
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name_upload       = var.db_name_upload
  db_name_report       = var.db_name_report
  create_report_db     = var.create_report_db
  db_username          = var.db_username
  db_password          = var.db_password
  subnet_ids           = module.network.private_subnet_ids
  lambda_subnet_ids    = module.network.private_subnet_ids
  lambda_security_group_id = module.security.lambda_sg_id
  security_group_id    = module.security.rds_sg_id
  tags                 = local.common_tags
}

module "ecr" {
  source      = "./modules/ecr"
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "logging" {
  source          = "./modules/logging"
  name_prefix     = local.name_prefix
  retention_days  = var.log_retention_days
  tags            = local.common_tags
}

module "iam" {
  source          = "./modules/iam"
  name_prefix     = local.name_prefix
  bucket_arn      = module.storage.bucket_arn
  queue_arn       = module.messaging.queue_arn
  db_secret_arn   = module.rds.db_secret_arn
  aws_region      = var.aws_region
  bedrock_model_id = var.bedrock_model_id
  tags            = local.common_tags
}

module "alb" {
  source          = "./modules/alb"
  name_prefix     = local.name_prefix
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.public_subnet_ids
  alb_sg_id       = module.security.alb_sg_id
  tags            = local.common_tags
}

module "ecs" {
  source                = "./modules/ecs"
  name_prefix           = local.name_prefix
  aws_region            = var.aws_region
  subnet_ids            = module.network.public_subnet_ids
  ecs_sg_id             = module.security.ecs_sg_id
  cpu                   = var.ecs_cpu
  memory                = var.ecs_memory
  upload_image          = var.upload_image
  report_image          = var.report_image
  processing_image      = var.processing_image
  ai_adapter            = var.ai_adapter
  bedrock_model_id      = var.bedrock_model_id
  bedrock_region        = var.bedrock_region
  upload_tg_arn          = module.alb.upload_tg_arn
  report_tg_arn          = module.alb.report_tg_arn
  execution_role_arn    = module.iam.execution_role_arn
  upload_task_role_arn  = module.iam.upload_role_arn
  report_task_role_arn  = module.iam.report_role_arn
  processing_task_role_arn = module.iam.processing_role_arn
  log_group_upload      = module.logging.log_group_upload
  log_group_report      = module.logging.log_group_report
  log_group_processing  = module.logging.log_group_processing
  s3_bucket_name        = module.storage.bucket_name
  sqs_queue_url         = module.messaging.queue_url
  db_host               = module.rds.db_host
  db_port               = module.rds.db_port
  db_name_upload        = var.db_name_upload
  db_name_report        = var.db_name_report
  db_secret_arn         = module.rds.db_secret_arn
  alb_dns_name          = module.alb.alb_dns_name
  tags                  = local.common_tags
}

module "apigw" {
  source        = "./modules/apigw"
  name_prefix   = local.name_prefix
  aws_region    = var.aws_region
  alb_dns_name  = module.alb.alb_dns_name
  stage_name    = var.api_gw_stage
  api_key_name  = var.api_key_name
  api_key_value = var.api_key_value
  tags          = local.common_tags
}
