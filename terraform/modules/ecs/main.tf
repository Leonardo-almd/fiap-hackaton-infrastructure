resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cluster"
  })
}

resource "aws_ecs_task_definition" "upload" {
  family                   = "${var.name_prefix}-td-upload"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.upload_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "upload-service"
      image = var.upload_image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "S3_BUCKET_NAME", value = var.s3_bucket_name },
        { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${var.db_host}:${tostring(var.db_port)}/${var.db_name_upload}" }
      ]
      secrets = [
        { name = "SPRING_DATASOURCE_USERNAME", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_upload
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "report" {
  family                   = "${var.name_prefix}-td-report"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.report_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "report-service"
      image = var.report_image
      essential = true
      portMappings = [
        {
          containerPort = 8082
          hostPort      = 8082
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${var.db_host}:${tostring(var.db_port)}/${var.db_name_report}" }
      ]
      secrets = [
        { name = "SPRING_DATASOURCE_USERNAME", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "SPRING_DATASOURCE_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_report
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "processing" {
  family                   = "${var.name_prefix}-td-processing"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.processing_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "processing-service"
      image = var.processing_image
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "S3_BUCKET_NAME", value = var.s3_bucket_name },
        { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
        { name = "UPLOAD_SERVICE_BASE_URL", value = "http://${var.alb_dns_name}" },
        { name = "REPORT_SERVICE_BASE_URL", value = "http://${var.alb_dns_name}" },
        { name = "AI_ADAPTER", value = var.ai_adapter },
        { name = "BEDROCK_MODEL_ID", value = var.bedrock_model_id },
        { name = "BEDROCK_REGION", value = var.bedrock_region }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_processing
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "upload" {
  name            = "${var.name_prefix}-svc-upload"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.upload.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.upload_tg_arn
    container_name   = "upload-service"
    container_port   = 8080
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-svc-upload"
  })
}

resource "aws_ecs_service" "report" {
  name            = "${var.name_prefix}-svc-report"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.report.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.report_tg_arn
    container_name   = "report-service"
    container_port   = 8082
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-svc-report"
  })
}

resource "aws_ecs_service" "processing" {
  name            = "${var.name_prefix}-svc-processing"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.processing.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-svc-processing"
  })
}
