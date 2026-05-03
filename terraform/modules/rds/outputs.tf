output "db_host" {
  description = "RDS endpoint hostname."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS port."
  value       = aws_db_instance.this.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}
