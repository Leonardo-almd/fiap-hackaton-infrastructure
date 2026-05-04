resource "aws_ecr_repository" "upload" {
  name                 = "${var.name_prefix}-upload-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-upload-service"
  })
}

resource "aws_ecr_repository" "report" {
  name                 = "${var.name_prefix}-report-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-report-service"
  })
}

resource "aws_ecr_repository" "processing" {
  name                 = "${var.name_prefix}-processing-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-processing-service"
  })
}
