# FIAP Secure Systems — MVP de Análise Automatizada de Diagramas de Arquitetura

#  Documentação

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
