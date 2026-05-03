output "queue_url" {
  description = "Main queue URL."
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "Main queue ARN."
  value       = aws_sqs_queue.main.arn
}

output "dlq_arn" {
  description = "DLQ ARN."
  value       = aws_sqs_queue.dlq.arn
}
