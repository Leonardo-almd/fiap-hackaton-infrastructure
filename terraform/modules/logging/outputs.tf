output "log_group_upload" {
  description = "Upload service log group name."
  value       = aws_cloudwatch_log_group.upload.name
}

output "log_group_report" {
  description = "Report service log group name."
  value       = aws_cloudwatch_log_group.report.name
}

output "log_group_processing" {
  description = "Processing service log group name."
  value       = aws_cloudwatch_log_group.processing.name
}
