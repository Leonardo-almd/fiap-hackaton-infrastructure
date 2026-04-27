#!/bin/bash
# =============================================================================
# LocalStack Init Script
# Executado automaticamente pelo LocalStack ao iniciar.
# Cria o bucket S3 e a fila SQS com Dead Letter Queue.
# =============================================================================

set -e

echo ">>> Iniciando configuração do LocalStack..."

AWS_CMD="aws --endpoint-url=http://localhost:4566 --region us-east-1"

# Criar bucket S3
echo ">>> Criando bucket S3: fiap-diagrams"
$AWS_CMD s3 mb s3://fiap-diagrams || true
$AWS_CMD s3api put-bucket-versioning \
  --bucket fiap-diagrams \
  --versioning-configuration Status=Enabled

# Criar Dead Letter Queue
echo ">>> Criando DLQ: diagram-analysis-dlq"
$AWS_CMD sqs create-queue \
  --queue-name diagram-analysis-dlq \
  --attributes '{"MessageRetentionPeriod":"1209600"}'

DLQ_ARN=$($AWS_CMD sqs get-queue-attributes \
  --queue-url http://localhost:4566/000000000000/diagram-analysis-dlq \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

# Criar fila principal com redrive policy para DLQ
echo ">>> Criando fila principal: diagram-analysis"
$AWS_CMD sqs create-queue \
  --queue-name diagram-analysis \
  --attributes "{
    \"VisibilityTimeout\": \"60\",
    \"MessageRetentionPeriod\": \"86400\",
    \"RedrivePolicy\": \"{\\\"deadLetterTargetArn\\\":\\\"${DLQ_ARN}\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"
  }"

echo ">>> LocalStack configurado com sucesso!"
echo "    S3 Bucket: fiap-diagrams"
echo "    SQS Queue: diagram-analysis"
echo "    SQS DLQ:   diagram-analysis-dlq"
