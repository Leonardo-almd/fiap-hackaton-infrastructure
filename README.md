# fiap-infrastructure

Repositório central de infraestrutura do projeto FIAP Secure Systems.

Contém:
- **Terraform**: toda a infraestrutura AWS (VPC, ECS, RDS, S3, SQS, API Gateway, IAM)
- **Docker Compose**: ambiente de desenvolvimento local com LocalStack + PostgreSQL
- **docs/**: contratos de API (OpenAPI), schemas JSON, modelos de banco, documentação de arquitetura
- **scripts/**: utilitários de inicialização local

## Repositórios do projeto

| Repositório | Responsável | Descrição |
|---|---|---|
| [fiap-upload-service](https://github.com/org/fiap-upload-service) | Pessoa 1 | Recebe diagramas, cria jobs, publica no SQS |
| [fiap-processing-service](https://github.com/org/fiap-processing-service) | Pessoa 2 | Consome fila, orquestra pipeline de IA |
| [fiap-report-service](https://github.com/org/fiap-report-service) | Pessoa 2 | Persiste e expõe relatórios de análise |
| **fiap-infrastructure** (este repo) | Pessoa 1 | Terraform, docker-compose, documentação |

## Estrutura

```
fiap-infrastructure/
├── terraform/              # Infraestrutura AWS como código
│   └── modules/
├── docs/
│   ├── api/                # Contratos OpenAPI (fonte da verdade)
│   ├── schemas/            # JSON Schemas (SQS message, report)
│   ├── database/           # Scripts de inicialização do banco
│   └── architecture/       # Diagrama e decisões arquiteturais
├── scripts/
│   └── localstack-init.sh  # Cria S3 e SQS no LocalStack
├── docker-compose.yml      # Ambiente local completo
└── README.md
```

## Ambiente local

### Pré-requisito: clonar todos os repos como irmãos

```bash
mkdir ~/fiap-project && cd ~/fiap-project
git clone https://github.com/org/fiap-upload-service
git clone https://github.com/org/fiap-processing-service
git clone https://github.com/org/fiap-report-service
git clone https://github.com/org/fiap-infrastructure
```

### Subir o ambiente

```bash
cd fiap-infrastructure

# Sobe apenas a infraestrutura (LocalStack + bancos)
docker compose up localstack upload-db report-db -d

# Sobe tudo (incluindo os serviços)
docker compose up -d

# Verificar saúde
curl http://localhost:8080/actuator/health   # upload-service
curl http://localhost:8081/actuator/health   # processing-service
curl http://localhost:8082/actuator/health   # report-service
```

### Testar o fluxo completo

```bash
# 1. Upload de um diagrama
curl -X POST http://localhost:8080/v1/uploads \
  -F "file=@/caminho/diagrama.png" \
  -F "description=Meu diagrama"

# 2. Verificar status (substituir {jobId} pelo valor retornado)
curl http://localhost:8080/v1/jobs/{jobId}/status

# 3. Consultar relatório quando status = ANALISADO
curl http://localhost:8082/v1/reports/{jobId}
```

## Contratos (fonte da verdade)

Todos os contratos estão em `docs/` e devem ser atualizados aqui antes de qualquer alteração nos serviços.

| Arquivo | Descrição |
|---|---|
| `docs/api/upload-service-api.yaml` | OpenAPI do upload-service |
| `docs/api/report-service-api.yaml` | OpenAPI do report-service |
| `docs/schemas/sqs-message.json` | JSON Schema da mensagem SQS |
| `docs/schemas/report.json` | JSON Schema do relatório |
| `docs/database/upload-service-init.sql` | Schema do banco upload_db |
| `docs/database/report-service-init.sql` | Schema do banco report_db |
| `docs/architecture/architecture.md` | Diagrama e decisões arquiteturais |

## Infraestrutura AWS (Terraform)

```bash
cd terraform

# Inicializar
terraform init

# Verificar o que será criado
terraform plan

# Aplicar (apenas após revisão do plan)
terraform apply
```

Recursos provisionados: VPC, ECS Fargate, RDS PostgreSQL, S3, SQS, API Gateway, ECR, CloudWatch, Secrets Manager, IAM Roles.
