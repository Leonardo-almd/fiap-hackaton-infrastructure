[🇧🇷 Português](#-fiap-secure-systems--mvp-de-análise-automatizada-de-diagramas-de-arquitetura) | [🇦🇺 English](#-fiap-secure-systems--automated-architecture-diagram-analysis-mvp)

---

# 🇧🇷 FIAP Secure Systems — MVP de Análise Automatizada de Diagramas de Arquitetura

# Documentação

Este sistema agrega vários serviços. A documentação principal foi centralizada no repositório de infraestrutura:

- [fiap-hackaton-infrastructure/README.md](fiap-hackaton-infrastructure/README.md)

Documentação por serviço:

- [fiap-hackaton-upload-service/README.md](fiap-hackaton-upload-service/README.md)
- [fiap-hackaton-processing-service/README.md](fiap-hackaton-processing-service/README.md)
- [fiap-hackaton-report-service/README.md](fiap-hackaton-report-service/README.md)

## Descrição do Problema

Empresas que operam sistemas distribuídos possuem dezenas de diagramas de arquitetura armazenados como imagens ou PDFs. A análise manual desses diagramas é lenta, depende de especialistas e não escala.

Este MVP resolve esse problema permitindo o **upload de um diagrama de arquitetura** e retornando automaticamente um **relatório técnico estruturado** com componentes identificados, riscos arquiteturais e recomendações — tudo via IA.

---

## Arquitetura da Solução

A solução é baseada em **3 microsserviços** independentes, comunicação assíncrona via **AWS SQS** e arquitetura interna seguindo o modelo **hexagonal (Ports & Adapters)**.

```
Cliente -> AWS API Gateway -> upload-service -> S3 + SQS
                                               |
                                    processing-service -> IA (Bedrock)
                                               |
                                      report-service
```

Para o diagrama completo com todos os fluxos, consulte [docs/architecture/architecture.md](docs/architecture/architecture.md).

### Microsserviços

| Serviço | Porta | Responsabilidade |
|---|---|---|
| `upload-service` | 8080 | Receber arquivos, criar jobs, publicar na fila |
| `processing-service` | 8081 | Consumir fila, orquestrar análise de IA |
| `report-service` | 8082 | Persistir e expor relatórios |

### Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| Linguagem | Java 21 + Spring Boot 3.3 |
| Fila assíncrona | AWS SQS (Standard + DLQ) |
| Armazenamento de arquivos | AWS S3 |
| Banco de dados | AWS RDS PostgreSQL 16 (um por serviço) |
| Infraestrutura como código | Terraform |
| Containers | Docker + AWS ECS Fargate |
| CI/CD | GitHub Actions |
| Observabilidade | AWS CloudWatch + Spring Actuator |
| IA (Fase 2) | Amazon Bedrock — Claude Sonnet 4.5 |

---

## Fluxo da Solução

1. **Upload**: cliente envia diagrama (PNG, JPG ou PDF) via `POST /v1/uploads`
2. **Armazenamento**: arquivo é salvo no S3; job criado com status `RECEBIDO`
3. **Enfileiramento**: mensagem publicada no SQS com `jobId` e localização no S3
4. **Processamento**: `processing-service` consome a mensagem; status -> `EM_PROCESSAMENTO`
5. **Análise IA**: diagrama é enviado ao modelo de visão; resposta estruturada em JSON
6. **Relatório**: resultado persistido no `report-service`; status -> `ANALISADO`
7. **Consulta**: cliente consulta status via `GET /v1/jobs/{jobId}/status` e relatório via `GET /v1/reports/{jobId}`

---

## Contratos de API

| Serviço | Contrato OpenAPI |
|---|---|
| upload-service | [docs/api/upload-service-api.yaml](docs/api/upload-service-api.yaml) |
| report-service | [docs/api/report-service-api.yaml](docs/api/report-service-api.yaml) |

### Endpoints principais

```
POST   /v1/uploads                    # Upload de diagrama
GET    /v1/jobs/{jobId}/status        # Status do processamento
GET    /v1/reports/{jobId}            # Relatório completo
```

### Formato da mensagem SQS

Consulte o schema completo em [docs/schemas/sqs-message.json](docs/schemas/sqs-message.json).

```json
{
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "s3Key": "uploads/550e8400-e29b-41d4-a716-446655440000.pdf",
  "fileType": "PDF",
  "fileSize": 245760,
  "originalFilename": "arquitetura-ecommerce-v2.pdf",
  "publishedAt": "2024-11-15T10:30:00.123Z"
}
```

### Schema do relatório

Consulte o schema completo em [docs/schemas/report.json](docs/schemas/report.json).

```json
{
  "jobId": "...",
  "componentes": [{ "nome": "...", "tipo": "SERVICE", "descricao": "..." }],
  "riscos": [{ "severidade": "ALTA", "categoria": "ACOPLAMENTO", "titulo": "...", "descricao": "..." }],
  "recomendacoes": [{ "prioridade": "ALTA", "titulo": "...", "descricao": "..." }]
}
```

---

## Repositórios do projeto

| Repositório | Responsável | Descrição |
|---|---|---|
| fiap-hackaton-upload-service | Pessoa 1 | Recebe diagramas, cria jobs, publica no SQS |
| fiap-hackaton-processing-service | Pessoa 2 | Consome fila, orquestra pipeline de IA |
| fiap-hackaton-report-service | Pessoa 2 | Persiste e expõe relatórios de análise |
| **fiap-hackaton-infrastructure** (este repo) | Pessoa 1 | Terraform, docker-compose, documentação |

## Estrutura

```
fiap-hackaton-infrastructure/
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
git clone https://github.com/org/fiap-hackaton-upload-service
git clone https://github.com/org/fiap-hackaton-processing-service
git clone https://github.com/org/fiap-hackaton-report-service
git clone https://github.com/org/fiap-hackaton-infrastructure
```

### Subir o ambiente

```bash
cd fiap-hackaton-infrastructure

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

## Fluxo end-to-end (jornada do usuário)

Veja o documento completo em [docs/user-journey/end-to-end-flow.md](docs/user-journey/end-to-end-flow.md).

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

## Segurança

### Validação de entrada
- Tipos de arquivo aceitos: PNG, JPG, JPEG, PDF (validação de MIME type e extensão)
- Tamanho máximo: 10MB por arquivo
- Sanitização de nome de arquivo antes de usar como chave no S3

### Comunicação entre serviços
- HTTPS obrigatório em todos os endpoints externos (via API Gateway)
- TLS na comunicação interna entre serviços no ECS (VPC privada)
- IAM Roles por serviço (princípio do menor privilégio)
- Security Groups restritivos: cada serviço acessa apenas o que precisa

### Armazenamento
- S3: bucket privado, acesso apenas via IAM Role do ECS Task
- RDS: sem acesso público; apenas via Security Group da VPC
- Credenciais: AWS Secrets Manager (nunca em variáveis de ambiente em produção)

### IA (Fase 2)
- Guardrails de entrada: rejeitar arquivos que não sejam diagramas arquiteturais
- Guardrails de saída: validar schema JSON da resposta antes de persistir
- Fallback explícito: se a IA retornar resposta inválida ou erro, o job vai para `ERRO` com mensagem rastreável
- Sem exposição de dados sensíveis ao modelo (arquivos são processados como imagem/texto, não como dados de negócio)

### Riscos conhecidos e limitações
- O MVP usa API Key simples no API Gateway; em produção, recomenda-se OAuth2/Cognito
- A DLQ captura mensagens que falharam 3 vezes; análise manual pode ser necessária
- O modelo de IA pode não reconhecer diagramas muito complexos ou com notações não padronizadas

## Infraestrutura AWS (Terraform)

Este repositório usa **Terraform Cloud** para `plan` e `apply`.

```bash
cd terraform

# Validar localmente (sem backend remoto)
terraform init -backend=false
terraform fmt -recursive
terraform validate
```

### Workspace Terraform Cloud

- Workspace: `fiap-hackaton-prod`
- Execution mode: Remote
- VCS-driven (branch de trabalho)

### Variáveis necessárias no Terraform Cloud

| Variável | Tipo no TFC | Descrição | Default | Obrigatória | Exemplo |
|---|---|---|---|---|---|
| `tfc_organization` | Terraform variable | Nome da organização no Terraform Cloud. | - | Sim | `fiap-lab` |
| `tfc_workspace` | Terraform variable | Nome do workspace no TFC. | `fiap-hackaton-prod` | Não | `fiap-hackaton-prod` |
| `aws_region` | Terraform variable | Região AWS para provisionar. | `us-east-1` | Não | `us-east-1` |
| `project` | Terraform variable | Prefixo de nome de recursos. | `fiap-hackaton` | Não | `fiap-hackaton` |
| `environment` | Terraform variable | Ambiente usado no prefixo. | `prod` | Não | `prod` |
| `vpc_cidr` | Terraform variable | CIDR da VPC. | `10.0.0.0/16` | Não | `10.0.0.0/16` |
| `public_subnet_cidrs` | Terraform variable | CIDRs das subnets públicas. | `["10.0.1.0/24", "10.0.2.0/24"]` | Não | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | Terraform variable | CIDRs das subnets privadas. | `["10.0.11.0/24", "10.0.12.0/24"]` | Não | `["10.0.11.0/24", "10.0.12.0/24"]` |
| `db_instance_class` | Terraform variable | Classe do RDS. | `db.t3.micro` | Não | `db.t3.micro` |
| `db_allocated_storage` | Terraform variable | Tamanho do RDS (GB). | `20` | Não | `20` |
| `db_name_upload` | Terraform variable | Nome do DB do upload-service. | `upload_db` | Não | `upload_db` |
| `db_name_report` | Terraform variable | Nome do DB do report-service. | `report_db` | Não | `report_db` |
| `create_report_db` | Terraform variable | Criar o banco `report_db` após o RDS subir. | `true` | Não | `true` |
| `db_username` | Terraform variable | Usuário master do RDS (sensitive). | - | Sim | `fiap_user` |
| `db_password` | Terraform variable | Senha master do RDS (sensitive). | - | Sim | `S3nh@F0rte!` |
| `s3_bucket_name` | Terraform variable | Bucket S3 para uploads. | `fiap-hackaton-prod-diagrams` | Não | `fiap-hackaton-prod-diagrams` |
| `sqs_queue_name` | Terraform variable | Fila SQS principal. | `fiap-hackaton-prod-diagram-analysis` | Não | `fiap-hackaton-prod-diagram-analysis` |
| `sqs_dlq_name` | Terraform variable | DLQ da fila principal. | `fiap-hackaton-prod-diagram-analysis-dlq` | Não | `fiap-hackaton-prod-diagram-analysis-dlq` |
| `api_gw_stage` | Terraform variable | Stage do API Gateway. | `prod` | Não | `prod` |
| `api_key_name` | Terraform variable | Nome da API Key. | `fiap-hackaton-prod-apikey` | Não | `fiap-hackaton-prod-apikey` |
| `api_key_value` | Terraform variable | Valor da API Key (sensitive). | - | Sim | `change-me-123` |
| `ecs_cpu` | Terraform variable | CPU por task (Fargate). | `256` | Não | `256` |
| `ecs_memory` | Terraform variable | Memória por task (MiB). | `512` | Não | `512` |
| `upload_image` | Terraform variable | Imagem do upload-service. | - | Sim | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-upload-service:latest` |
| `report_image` | Terraform variable | Imagem do report-service. | - | Sim | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-report-service:latest` |
| `processing_image` | Terraform variable | Imagem do processing-service. | - | Sim | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-processing-service:latest` |
| `ai_adapter` | Terraform variable | Adapter de IA do processing-service. | `bedrock` | Não | `bedrock` |
| `bedrock_model_id` | Terraform variable | ID base do modelo Bedrock (sem prefixo). | `anthropic.claude-sonnet-4-5-20250929-v1:0` | Não | `anthropic.claude-sonnet-4-5-20250929-v1:0` |
| `bedrock_model_id_prefix` | Terraform variable | Prefixo cross-region do modelo (ex: global, us). | `global` | Não | `global` |
| `bedrock_region` | Terraform variable | Região do Bedrock para o processing-service. | `us-east-1` | Não | `us-east-1` |
| `alb_allowed_cidrs` | Terraform variable | CIDRs permitidos no ALB. | `["0.0.0.0/0"]` | Não | `["0.0.0.0/0"]` |
| `log_retention_days` | Terraform variable | Retenção de logs (dias). | `3` | Não | `3` |
| `tags` | Terraform variable | Tags extras (map). | `{}` | Não | `{ Owner = "fiap" }` |

### Environment variables no Terraform Cloud

As credenciais AWS devem ser configuradas como **Environment variables** no TFC:

- `AWS_ACCESS_KEY_ID` (sensitive)
- `AWS_SECRET_ACCESS_KEY` (sensitive)

Opcionalmente, se quiser, pode definir:

- `AWS_DEFAULT_REGION` (ex: `us-east-1`)

Observação importante:
- **ECS Fargate** não precisa de `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` no container em produção. O acesso AWS do runtime ocorre via **Task Role**.
- Para desenvolvimento local (Bedrock real), as credenciais podem ser usadas via variáveis de ambiente ou perfil local, conforme o README do processing-service.

### Como gerar a API Key

1. Gere um valor forte localmente:

```bash
openssl rand -hex 24
```

2. Salve o valor no Terraform Cloud como `api_key_value` (sensitive).
3. A API Key será criada no API Gateway com o nome `api_key_name`.

Uso no cliente (exemplo):

```bash
curl -H "x-api-key: <API_KEY>" https://<invoke-url>/v1/uploads
```

Se preferir, você pode gerar manualmente no console AWS, mas **neste projeto a API Key é gerenciada pelo Terraform** para manter tudo versionado.

### Recursos provisionados

- VPC (subnets públicas e privadas), IGW, rotas
- ALB público com roteamento por path
- ECS Fargate (upload, report, processing)
- RDS PostgreSQL (instância única com dois databases lógicos)
- S3 (bucket privado com SSE-S3)
- SQS + DLQ
- API Gateway (REST) com API Key
- ECR (repositórios por serviço)
- CloudWatch Log Groups
- IAM Roles (execution + task roles)
- Secrets Manager (credenciais do DB)

### Naming padrão (prefixo)

- Prefixo: `${project}-${environment}` (default: `fiap-hackaton-prod`)
- S3: `fiap-hackaton-prod-diagrams`
- SQS: `fiap-hackaton-prod-diagram-analysis`
- DLQ: `fiap-hackaton-prod-diagram-analysis-dlq`
- ALB: `fiap-hackaton-prod-alb`
- ECS Cluster: `fiap-hackaton-prod-cluster`
- ECS Services: `fiap-hackaton-prod-svc-upload`, `fiap-hackaton-prod-svc-report`, `fiap-hackaton-prod-svc-processing`
- RDS: `fiap-hackaton-prod-rds`
- API Gateway: `fiap-hackaton-prod-apigw`
- Log Groups: `/ecs/fiap-hackaton-prod-upload`, `/ecs/fiap-hackaton-prod-report`, `/ecs/fiap-hackaton-prod-processing`

### Acesso e operação

- API Gateway: usar o output `api_gateway_invoke_url`
- API Key: valor definido em `api_key_value`
- Logs: CloudWatch Log Groups `/ecs/fiap-hackaton-prod-*`
- Bucket: `fiap-hackaton-prod-diagrams`
- SQS: `fiap-hackaton-prod-diagram-analysis`

### Integração da imagem (CI/CD -> ECS)

As tasks do ECS usam as variáveis `upload_image`, `report_image` e `processing_image` (com tag). O CI/CD precisa publicar a imagem no ECR e atualizar esses valores.

1. **Deploy direto no ECS (sem atualizar Terraform) >UTILIZADO<**
  - CI/CD faz `aws ecs update-service` com nova task definition.
  - Mais rápido, mas o estado do Terraform fica desatualizado.

---

[⬆️ Back to top / Voltar ao topo](#-fiap-secure-systems--mvp-de-análise-automatizada-de-diagramas-de-arquitetura)

---

# 🇦🇺 FIAP Secure Systems — Automated Architecture Diagram Analysis MVP

# Documentation

This system aggregates several services. The main documentation has been centralized in the infrastructure repository:

- [fiap-hackaton-infrastructure/README.md](fiap-hackaton-infrastructure/README.md)

Per-service documentation:

- [fiap-hackaton-upload-service/README.md](fiap-hackaton-upload-service/README.md)
- [fiap-hackaton-processing-service/README.md](fiap-hackaton-processing-service/README.md)
- [fiap-hackaton-report-service/README.md](fiap-hackaton-report-service/README.md)

## Problem Description

Companies operating distributed systems have dozens of architecture diagrams stored as images or PDFs. Manually analyzing these diagrams is slow, depends on specialists, and does not scale.

This MVP solves that problem by allowing the **upload of an architecture diagram** and automatically returning a **structured technical report** with identified components, architectural risks, and recommendations — all powered by AI.

---

## Solution Architecture

The solution is based on **3 independent microservices**, asynchronous communication via **AWS SQS**, and an internal architecture following the **hexagonal (Ports & Adapters)** model.

```
Client -> AWS API Gateway -> upload-service -> S3 + SQS
                                               |
                                    processing-service -> AI (Bedrock)
                                               |
                                      report-service
```

For the full diagram with all flows, see [docs/architecture/architecture.md](docs/architecture/architecture.md).

### Microservices

| Service | Port | Responsibility |
|---|---|---|
| `upload-service` | 8080 | Receive files, create jobs, publish to the queue |
| `processing-service` | 8081 | Consume the queue, orchestrate AI analysis |
| `report-service` | 8082 | Persist and expose reports |

### Technology Stack

| Layer | Technology |
|---|---|
| Language | Java 21 + Spring Boot 3.3 |
| Async queue | AWS SQS (Standard + DLQ) |
| File storage | AWS S3 |
| Database | AWS RDS PostgreSQL 16 (one per service) |
| Infrastructure as code | Terraform |
| Containers | Docker + AWS ECS Fargate |
| CI/CD | GitHub Actions |
| Observability | AWS CloudWatch + Spring Actuator |
| AI (Phase 2) | Amazon Bedrock — Claude Sonnet 4.5 |

---

## Solution Flow

1. **Upload**: client sends a diagram (PNG, JPG, or PDF) via `POST /v1/uploads`
2. **Storage**: file is saved to S3; a job is created with status `RECEBIDO`
3. **Queueing**: message published to SQS with `jobId` and S3 location
4. **Processing**: `processing-service` consumes the message; status -> `EM_PROCESSAMENTO`
5. **AI Analysis**: diagram is sent to the vision model; response structured as JSON
6. **Report**: result persisted in `report-service`; status -> `ANALISADO`
7. **Query**: client checks status via `GET /v1/jobs/{jobId}/status` and the report via `GET /v1/reports/{jobId}`

---

## API Contracts

| Service | OpenAPI Contract |
|---|---|
| upload-service | [docs/api/upload-service-api.yaml](docs/api/upload-service-api.yaml) |
| report-service | [docs/api/report-service-api.yaml](docs/api/report-service-api.yaml) |

### Main Endpoints

```
POST   /v1/uploads                    # Diagram upload
GET    /v1/jobs/{jobId}/status        # Processing status
GET    /v1/reports/{jobId}            # Full report
```

### SQS Message Format

See the full schema at [docs/schemas/sqs-message.json](docs/schemas/sqs-message.json).

```json
{
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "s3Key": "uploads/550e8400-e29b-41d4-a716-446655440000.pdf",
  "fileType": "PDF",
  "fileSize": 245760,
  "originalFilename": "arquitetura-ecommerce-v2.pdf",
  "publishedAt": "2024-11-15T10:30:00.123Z"
}
```

### Report Schema

See the full schema at [docs/schemas/report.json](docs/schemas/report.json).

```json
{
  "jobId": "...",
  "componentes": [{ "nome": "...", "tipo": "SERVICE", "descricao": "..." }],
  "riscos": [{ "severidade": "ALTA", "categoria": "ACOPLAMENTO", "titulo": "...", "descricao": "..." }],
  "recomendacoes": [{ "prioridade": "ALTA", "titulo": "...", "descricao": "..." }]
}
```

---

## Project Repositories

| Repository | Owner | Description |
|---|---|---|
| fiap-hackaton-upload-service | Person 1 | Receives diagrams, creates jobs, publishes to SQS |
| fiap-hackaton-processing-service | Person 2 | Consumes the queue, orchestrates the AI pipeline |
| fiap-hackaton-report-service | Person 2 | Persists and exposes analysis reports |
| **fiap-hackaton-infrastructure** (this repo) | Person 1 | Terraform, docker-compose, documentation |

## Structure

```
fiap-hackaton-infrastructure/
├── terraform/              # AWS infrastructure as code
│   └── modules/
├── docs/
│   ├── api/                # OpenAPI contracts (source of truth)
│   ├── schemas/            # JSON Schemas (SQS message, report)
│   ├── database/           # Database initialization scripts
│   └── architecture/       # Diagram and architectural decisions
├── scripts/
│   └── localstack-init.sh  # Creates S3 and SQS in LocalStack
├── docker-compose.yml      # Full local environment
└── README.md
```

## Local Environment

### Prerequisite: clone all repos as siblings

```bash
mkdir ~/fiap-project && cd ~/fiap-project
git clone https://github.com/org/fiap-hackaton-upload-service
git clone https://github.com/org/fiap-hackaton-processing-service
git clone https://github.com/org/fiap-hackaton-report-service
git clone https://github.com/org/fiap-hackaton-infrastructure
```

### Starting the environment

```bash
cd fiap-hackaton-infrastructure

# Brings up only the infrastructure (LocalStack + databases)
docker compose up localstack upload-db report-db -d

# Brings up everything (including the services)
docker compose up -d

# Check health
curl http://localhost:8080/actuator/health   # upload-service
curl http://localhost:8081/actuator/health   # processing-service
curl http://localhost:8082/actuator/health   # report-service
```

### Testing the full flow

```bash
# 1. Upload a diagram
curl -X POST http://localhost:8080/v1/uploads \
  -F "file=@/path/diagram.png" \
  -F "description=My diagram"

# 2. Check status (replace {jobId} with the returned value)
curl http://localhost:8080/v1/jobs/{jobId}/status

# 3. Fetch the report once status = ANALISADO
curl http://localhost:8082/v1/reports/{jobId}
```

## End-to-End Flow (User Journey)

See the full document at [docs/user-journey/end-to-end-flow.md](docs/user-journey/end-to-end-flow.md).

## Contracts (Source of Truth)

All contracts live in `docs/` and must be updated here before any change to the services.

| File | Description |
|---|---|
| `docs/api/upload-service-api.yaml` | upload-service OpenAPI |
| `docs/api/report-service-api.yaml` | report-service OpenAPI |
| `docs/schemas/sqs-message.json` | SQS message JSON Schema |
| `docs/schemas/report.json` | Report JSON Schema |
| `docs/database/upload-service-init.sql` | upload_db database schema |
| `docs/database/report-service-init.sql` | report_db database schema |
| `docs/architecture/architecture.md` | Diagram and architectural decisions |

## Security

### Input Validation
- Accepted file types: PNG, JPG, JPEG, PDF (MIME type and extension validation)
- Maximum size: 10MB per file
- Filename sanitization before using it as an S3 key

### Inter-Service Communication
- HTTPS mandatory on all external endpoints (via API Gateway)
- TLS for internal communication between services on ECS (private VPC)
- IAM Roles per service (principle of least privilege)
- Restrictive Security Groups: each service accesses only what it needs

### Storage
- S3: private bucket, access only via the ECS Task's IAM Role
- RDS: no public access; only via the VPC Security Group
- Credentials: AWS Secrets Manager (never in environment variables in production)

### AI (Phase 2)
- Input guardrails: reject files that are not architectural diagrams
- Output guardrails: validate the response's JSON schema before persisting
- Explicit fallback: if the AI returns an invalid response or an error, the job moves to `ERRO` with a traceable message
- No sensitive data exposed to the model (files are processed as image/text, not as business data)

### Known Risks and Limitations
- The MVP uses a simple API Key on the API Gateway; OAuth2/Cognito is recommended for production
- The DLQ captures messages that failed 3 times; manual review may be required
- The AI model may not recognize very complex diagrams or ones with non-standard notations

## AWS Infrastructure (Terraform)

This repository uses **Terraform Cloud** for `plan` and `apply`.

```bash
cd terraform

# Validate locally (without a remote backend)
terraform init -backend=false
terraform fmt -recursive
terraform validate
```

### Terraform Cloud Workspace

- Workspace: `fiap-hackaton-prod`
- Execution mode: Remote
- VCS-driven (working branch)

### Required Variables in Terraform Cloud

| Variable | Type in TFC | Description | Default | Required | Example |
|---|---|---|---|---|---|
| `tfc_organization` | Terraform variable | Organization name in Terraform Cloud. | - | Yes | `fiap-lab` |
| `tfc_workspace` | Terraform variable | Workspace name in TFC. | `fiap-hackaton-prod` | No | `fiap-hackaton-prod` |
| `aws_region` | Terraform variable | AWS region to provision in. | `us-east-1` | No | `us-east-1` |
| `project` | Terraform variable | Resource name prefix. | `fiap-hackaton` | No | `fiap-hackaton` |
| `environment` | Terraform variable | Environment used in the prefix. | `prod` | No | `prod` |
| `vpc_cidr` | Terraform variable | VPC CIDR. | `10.0.0.0/16` | No | `10.0.0.0/16` |
| `public_subnet_cidrs` | Terraform variable | Public subnet CIDRs. | `["10.0.1.0/24", "10.0.2.0/24"]` | No | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | Terraform variable | Private subnet CIDRs. | `["10.0.11.0/24", "10.0.12.0/24"]` | No | `["10.0.11.0/24", "10.0.12.0/24"]` |
| `db_instance_class` | Terraform variable | RDS instance class. | `db.t3.micro` | No | `db.t3.micro` |
| `db_allocated_storage` | Terraform variable | RDS storage size (GB). | `20` | No | `20` |
| `db_name_upload` | Terraform variable | upload-service DB name. | `upload_db` | No | `upload_db` |
| `db_name_report` | Terraform variable | report-service DB name. | `report_db` | No | `report_db` |
| `create_report_db` | Terraform variable | Create the `report_db` database after RDS comes up. | `true` | No | `true` |
| `db_username` | Terraform variable | RDS master user (sensitive). | - | Yes | `fiap_user` |
| `db_password` | Terraform variable | RDS master password (sensitive). | - | Yes | `S3nh@F0rte!` |
| `s3_bucket_name` | Terraform variable | S3 bucket for uploads. | `fiap-hackaton-prod-diagrams` | No | `fiap-hackaton-prod-diagrams` |
| `sqs_queue_name` | Terraform variable | Main SQS queue. | `fiap-hackaton-prod-diagram-analysis` | No | `fiap-hackaton-prod-diagram-analysis` |
| `sqs_dlq_name` | Terraform variable | Main queue's DLQ. | `fiap-hackaton-prod-diagram-analysis-dlq` | No | `fiap-hackaton-prod-diagram-analysis-dlq` |
| `api_gw_stage` | Terraform variable | API Gateway stage. | `prod` | No | `prod` |
| `api_key_name` | Terraform variable | API Key name. | `fiap-hackaton-prod-apikey` | No | `fiap-hackaton-prod-apikey` |
| `api_key_value` | Terraform variable | API Key value (sensitive). | - | Yes | `change-me-123` |
| `ecs_cpu` | Terraform variable | CPU per task (Fargate). | `256` | No | `256` |
| `ecs_memory` | Terraform variable | Memory per task (MiB). | `512` | No | `512` |
| `upload_image` | Terraform variable | upload-service image. | - | Yes | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-upload-service:latest` |
| `report_image` | Terraform variable | report-service image. | - | Yes | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-report-service:latest` |
| `processing_image` | Terraform variable | processing-service image. | - | Yes | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-processing-service:latest` |
| `ai_adapter` | Terraform variable | processing-service AI adapter. | `bedrock` | No | `bedrock` |
| `bedrock_model_id` | Terraform variable | Base Bedrock model ID (without prefix). | `anthropic.claude-sonnet-4-5-20250929-v1:0` | No | `anthropic.claude-sonnet-4-5-20250929-v1:0` |
| `bedrock_model_id_prefix` | Terraform variable | Model's cross-region prefix (e.g. global, us). | `global` | No | `global` |
| `bedrock_region` | Terraform variable | Bedrock region for processing-service. | `us-east-1` | No | `us-east-1` |
| `alb_allowed_cidrs` | Terraform variable | CIDRs allowed on the ALB. | `["0.0.0.0/0"]` | No | `["0.0.0.0/0"]` |
| `log_retention_days` | Terraform variable | Log retention (days). | `3` | No | `3` |
| `tags` | Terraform variable | Extra tags (map). | `{}` | No | `{ Owner = "fiap" }` |

### Environment Variables in Terraform Cloud

AWS credentials must be configured as **Environment variables** in TFC:

- `AWS_ACCESS_KEY_ID` (sensitive)
- `AWS_SECRET_ACCESS_KEY` (sensitive)

Optionally, you can also set:

- `AWS_DEFAULT_REGION` (e.g. `us-east-1`)

Important note:
- **ECS Fargate** does not need `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in the container in production. The runtime's AWS access happens via the **Task Role**.
- For local development (real Bedrock), credentials can be used via environment variables or a local profile, as described in the processing-service README.

### How to Generate the API Key

1. Generate a strong value locally:

```bash
openssl rand -hex 24
```

2. Save the value in Terraform Cloud as `api_key_value` (sensitive).
3. The API Key will be created in the API Gateway under the name `api_key_name`.

Client usage (example):

```bash
curl -H "x-api-key: <API_KEY>" https://<invoke-url>/v1/uploads
```

If you prefer, you can generate it manually in the AWS console, but **in this project the API Key is managed by Terraform** to keep everything versioned.

### Provisioned Resources

- VPC (public and private subnets), IGW, routes
- Public ALB with path-based routing
- ECS Fargate (upload, report, processing)
- RDS PostgreSQL (single instance with two logical databases)
- S3 (private bucket with SSE-S3)
- SQS + DLQ
- API Gateway (REST) with API Key
- ECR (one repository per service)
- CloudWatch Log Groups
- IAM Roles (execution + task roles)
- Secrets Manager (DB credentials)

### Standard Naming (prefix)

- Prefix: `${project}-${environment}` (default: `fiap-hackaton-prod`)
- S3: `fiap-hackaton-prod-diagrams`
- SQS: `fiap-hackaton-prod-diagram-analysis`
- DLQ: `fiap-hackaton-prod-diagram-analysis-dlq`
- ALB: `fiap-hackaton-prod-alb`
- ECS Cluster: `fiap-hackaton-prod-cluster`
- ECS Services: `fiap-hackaton-prod-svc-upload`, `fiap-hackaton-prod-svc-report`, `fiap-hackaton-prod-svc-processing`
- RDS: `fiap-hackaton-prod-rds`
- API Gateway: `fiap-hackaton-prod-apigw`
- Log Groups: `/ecs/fiap-hackaton-prod-upload`, `/ecs/fiap-hackaton-prod-report`, `/ecs/fiap-hackaton-prod-processing`

### Access and Operation

- API Gateway: use the `api_gateway_invoke_url` output
- API Key: value defined in `api_key_value`
- Logs: CloudWatch Log Groups `/ecs/fiap-hackaton-prod-*`
- Bucket: `fiap-hackaton-prod-diagrams`
- SQS: `fiap-hackaton-prod-diagram-analysis`

### Image Integration (CI/CD -> ECS)

ECS tasks use the `upload_image`, `report_image`, and `processing_image` variables (with a tag). CI/CD needs to publish the image to ECR and update these values.

1. **Direct deploy to ECS (without updating Terraform) >USED<**
  - CI/CD runs `aws ecs update-service` with a new task definition.
  - Faster, but the Terraform state becomes out of date.

---

[⬆️ Back to top / Voltar ao topo](#-fiap-secure-systems--mvp-de-análise-automatizada-de-diagramas-de-arquitetura)
