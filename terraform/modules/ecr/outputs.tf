output "upload_repo_url" {
  description = "Upload service ECR repository URL."
  value       = aws_ecr_repository.upload.repository_url
}

output "report_repo_url" {
  description = "Report service ECR repository URL."
  value       = aws_ecr_repository.report.repository_url
}

output "processing_repo_url" {
  description = "Processing service ECR repository URL."
  value       = aws_ecr_repository.processing.repository_url
}
