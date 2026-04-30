resource "aws_cloudwatch_log_group" "upload" {
  name              = "/ecs/${var.name_prefix}-upload"
  retention_in_days = var.retention_days

  tags = merge(var.tags, {
    Name = "/ecs/${var.name_prefix}-upload"
  })
}

resource "aws_cloudwatch_log_group" "report" {
  name              = "/ecs/${var.name_prefix}-report"
  retention_in_days = var.retention_days

  tags = merge(var.tags, {
    Name = "/ecs/${var.name_prefix}-report"
  })
}

resource "aws_cloudwatch_log_group" "processing" {
  name              = "/ecs/${var.name_prefix}-processing"
  retention_in_days = var.retention_days

  tags = merge(var.tags, {
    Name = "/ecs/${var.name_prefix}-processing"
  })
}
