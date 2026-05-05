resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name_prefix}-rds"
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.security_group_id]
  db_name                 = var.db_name_upload
  username                = var.db_username
  password                = var.db_password
  publicly_accessible     = false
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds"
  })
}

resource "random_id" "secret_suffix" {
  byte_length = 3

  keepers = {
    name_prefix = var.name_prefix
  }
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.name_prefix}-db-credentials-${random_id.secret_suffix.hex}"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-credentials-${random_id.secret_suffix.hex}"
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username   = var.db_username
    password   = var.db_password
    host       = aws_db_instance.this.address
    port       = aws_db_instance.this.port
    db_upload  = var.db_name_upload
    db_report  = var.db_name_report
  })
}

locals {
  lambda_src_dir   = "${path.module}/lambda"
  lambda_build_dir = "${path.module}/lambda_build"
  lambda_zip_path  = "${path.module}/lambda_build.zip"
}

resource "null_resource" "lambda_package" {
  triggers = {
    requirements_hash = filesha256("${local.lambda_src_dir}/requirements.txt")
    handler_hash      = filesha256("${local.lambda_src_dir}/handler.py")
    build_id          = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf "${local.lambda_build_dir}" "${local.lambda_zip_path}"
      mkdir -p "${local.lambda_build_dir}"
      python3 -m pip install -r "${local.lambda_src_dir}/requirements.txt" -t "${local.lambda_build_dir}"
      cp "${local.lambda_src_dir}/handler.py" "${local.lambda_build_dir}/handler.py"
      python3 - <<'PY'
import os
import zipfile

build_dir = r"${local.lambda_build_dir}"
zip_path = r"${local.lambda_zip_path}"

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(build_dir):
        for name in files:
            file_path = os.path.join(root, name)
            arcname = os.path.relpath(file_path, build_dir)
            zf.write(file_path, arcname)
PY
    EOT
  }
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-role-rds-init"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-role-rds-init"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_secrets" {
  name = "${var.name_prefix}-policy-rds-init"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.db.arn
      }
    ]
  })
}

resource "aws_lambda_function" "report_db_init" {
  count         = var.create_report_db ? 1 : 0
  function_name = "${var.name_prefix}-init-report-db"
  filename      = local.lambda_zip_path
  source_code_hash = try(filebase64sha256(local.lambda_zip_path), null)
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda.arn
  timeout       = 120

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      SECRET_ARN      = aws_secretsmanager_secret.db.arn
      REPORT_DB_NAME  = var.db_name_report
    }
  }

  depends_on = [aws_db_instance.this, null_resource.lambda_package]
}

resource "aws_lambda_invocation" "report_db_init" {
  count         = var.create_report_db ? 1 : 0
  function_name = aws_lambda_function.report_db_init[0].function_name
  input         = jsonencode({})

  depends_on = [aws_db_instance.this, aws_secretsmanager_secret_version.db, aws_lambda_function.report_db_init]
}
