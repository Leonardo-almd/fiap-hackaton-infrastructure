resource "aws_sqs_queue" "dlq" {
  name                      = var.dlq_name
  message_retention_seconds = 1209600

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-diagram-analysis-dlq"
  })
}

resource "aws_sqs_queue" "main" {
  name                      = var.queue_name
  visibility_timeout_seconds = 60
  message_retention_seconds = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-diagram-analysis"
  })
}
