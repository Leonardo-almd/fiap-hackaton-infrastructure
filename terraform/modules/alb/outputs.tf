output "alb_dns_name" {
  description = "ALB DNS name."
  value       = aws_lb.this.dns_name
}

output "upload_tg_arn" {
  description = "Upload target group ARN."
  value       = aws_lb_target_group.upload.arn
}

output "report_tg_arn" {
  description = "Report target group ARN."
  value       = aws_lb_target_group.report.arn
}
