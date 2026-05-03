output "api_gateway_invoke_url" {
  description = "Invoke URL for API Gateway."
  value       = module.apigw.invoke_url
}

output "api_gateway_api_key_name" {
  description = "API Gateway API key name."
  value       = module.apigw.api_key_name
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.alb_dns_name
}

output "s3_bucket_name" {
  description = "S3 bucket name."
  value       = module.storage.bucket_name
}

output "sqs_queue_url" {
  description = "SQS queue URL."
  value       = module.messaging.queue_url
}

output "rds_endpoint" {
  description = "RDS endpoint address."
  value       = module.rds.db_host
}
