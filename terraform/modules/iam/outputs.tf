output "execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = aws_iam_role.execution.arn
}

output "upload_role_arn" {
  description = "Upload task role ARN."
  value       = aws_iam_role.upload.arn
}

output "report_role_arn" {
  description = "Report task role ARN."
  value       = aws_iam_role.report.arn
}

output "processing_role_arn" {
  description = "Processing task role ARN."
  value       = aws_iam_role.processing.arn
}
