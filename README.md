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

## Fluxo end-to-end (jornada do usuario)

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

| Variavel | Tipo no TFC | Descricao | Default | Obrigatoria | Exemplo |
|---|---|---|---|---|---|
| `tfc_organization` | Terraform variable | Nome da organizacao no Terraform Cloud. | - | Sim | `fiap-lab` |
| `tfc_workspace` | Terraform variable | Nome do workspace no TFC. | `fiap-hackaton-prod` | Nao | `fiap-hackaton-prod` |
| `aws_region` | Terraform variable | Regiao AWS para provisionar. | `us-east-1` | Nao | `us-east-1` |
| `project` | Terraform variable | Prefixo de nome de recursos. | `fiap-hackaton` | Nao | `fiap-hackaton` |
| `environment` | Terraform variable | Ambiente usado no prefixo. | `prod` | Nao | `prod` |
| `vpc_cidr` | Terraform variable | CIDR da VPC. | `10.0.0.0/16` | Nao | `10.0.0.0/16` |
| `public_subnet_cidrs` | Terraform variable | CIDRs das subnets publicas. | `["10.0.1.0/24", "10.0.2.0/24"]` | Nao | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | Terraform variable | CIDRs das subnets privadas. | `["10.0.11.0/24", "10.0.12.0/24"]` | Nao | `["10.0.11.0/24", "10.0.12.0/24"]` |
| `db_instance_class` | Terraform variable | Classe do RDS. | `db.t3.micro` | Nao | `db.t3.micro` |
| `db_allocated_storage` | Terraform variable | Tamanho do RDS (GB). | `20` | Nao | `20` |
| `db_name_upload` | Terraform variable | Nome do DB do upload-service. | `upload_db` | Nao | `upload_db` |
| `db_name_report` | Terraform variable | Nome do DB do report-service. | `report_db` | Nao | `report_db` |
| `create_report_db` | Terraform variable | Criar o banco `report_db` apos o RDS subir. | `true` | Nao | `true` |
| `db_username` | Terraform variable | Usuario master do RDS (sensitive). | - | Sim | `fiap_user` |
| `db_password` | Terraform variable | Senha master do RDS (sensitive). | - | Sim | `S3nh@F0rte!` |
| `s3_bucket_name` | Terraform variable | Bucket S3 para uploads. | `fiap-hackaton-prod-diagrams` | Nao | `fiap-hackaton-prod-diagrams` |
| `sqs_queue_name` | Terraform variable | Fila SQS principal. | `fiap-hackaton-prod-diagram-analysis` | Nao | `fiap-hackaton-prod-diagram-analysis` |
| `sqs_dlq_name` | Terraform variable | DLQ da fila principal. | `fiap-hackaton-prod-diagram-analysis-dlq` | Nao | `fiap-hackaton-prod-diagram-analysis-dlq` |
| `api_gw_stage` | Terraform variable | Stage do API Gateway. | `prod` | Nao | `prod` |
| `api_key_name` | Terraform variable | Nome da API Key. | `fiap-hackaton-prod-apikey` | Nao | `fiap-hackaton-prod-apikey` |
| `api_key_value` | Terraform variable | Valor da API Key (sensitive). | - | Sim | `change-me-123` |
| `ecs_cpu` | Terraform variable | CPU por task (Fargate). | `256` | Nao | `256` |
| `ecs_memory` | Terraform variable | Memoria por task (MiB). | `512` | Nao | `512` |
| `upload_image` | Terraform variable | Imagem do upload-service. | - | Sim | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-upload-service:latest` |
| `report_image` | Terraform variable | Imagem do report-service. | - | Sim | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-report-service:latest` |
| `processing_image` | Terraform variable | Imagem do processing-service. | - | Sim | `123456789012.dkr.ecr.us-east-1.amazonaws.com/fiap-hackaton-prod-processing-service:latest` |
| `ai_adapter` | Terraform variable | Adapter de IA do processing-service. | `bedrock` | Nao | `bedrock` |
| `bedrock_model_id` | Terraform variable | ID do modelo Bedrock usado pelo processing-service. | `anthropic.claude-3-sonnet-20240229-v1:0` | Nao | `anthropic.claude-3-sonnet-20240229-v1:0` |
| `bedrock_region` | Terraform variable | Regiao do Bedrock para o processing-service. | `us-east-1` | Nao | `us-east-1` |
| `alb_allowed_cidrs` | Terraform variable | CIDRs permitidos no ALB. | `["0.0.0.0/0"]` | Nao | `["0.0.0.0/0"]` |
| `log_retention_days` | Terraform variable | Retencao de logs (dias). | `3` | Nao | `3` |
| `tags` | Terraform variable | Tags extras (map). | `{}` | Nao | `{ Owner = "fiap" }` |

### Environment variables no Terraform Cloud

As credenciais AWS devem ser configuradas como **Environment variables** no TFC:

- `AWS_ACCESS_KEY_ID` (sensitive)
- `AWS_SECRET_ACCESS_KEY` (sensitive)

Opcionalmente, se quiser, pode definir:

- `AWS_DEFAULT_REGION` (ex: `us-east-1`)

Observacao importante:
- **ECS Fargate** nao precisa de `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` no container em producao. O acesso AWS do runtime ocorre via **Task Role**.
- Para desenvolvimento local (Bedrock real), as credenciais podem ser usadas via variaveis de ambiente ou perfil local, conforme o README do processing-service.

### API Key: precisa ou nao?

Sim, **na configuracao atual** a API Key e obrigatoria porque o API Gateway esta com `api_key_required = true`. Isso evita acesso anonimo e atende o requisito de seguranca do MVP. Se quiser remover essa exigencia, precisa ajustar o modulo do API Gateway para nao requerer API Key e remover Usage Plan + API Key.

### Como gerar a API Key

1. Gere um valor forte localmente:

```bash
openssl rand -hex 24
```

2. Salve o valor no Terraform Cloud como `api_key_value` (sensitive).
3. A API Key sera criada no API Gateway com o nome `api_key_name`.

Uso no cliente (exemplo):

```bash
curl -H "x-api-key: <API_KEY>" https://<invoke-url>/v1/uploads
```

Se preferir, voce pode gerar manualmente no console AWS, mas **neste projeto a API Key e gerenciada pelo Terraform** para manter tudo versionado.


### Recursos provisionados

- VPC (subnets publicas e privadas), IGW, rotas
- ALB publico com roteamento por path
- ECS Fargate (upload, report, processing)
- RDS PostgreSQL (instancia unica com dois databases logicos)
- S3 (bucket privado com SSE-S3)
- SQS + DLQ
- API Gateway (REST) com API Key
- ECR (repositorios por servico)
- CloudWatch Log Groups
- IAM Roles (execution + task roles)
- Secrets Manager (credenciais do DB)

### Naming padrao (prefixo)

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

### Acesso e operacao

- API Gateway: usar o output `api_gateway_invoke_url`
- API Key: valor definido em `api_key_value`
- Logs: CloudWatch Log Groups `/ecs/fiap-hackaton-prod-*`
- Bucket: `fiap-hackaton-prod-diagrams`
- SQS: `fiap-hackaton-prod-diagram-analysis`

### Integracao da imagem (CI/CD -> ECS)

As tasks do ECS usam as variaveis `upload_image`, `report_image` e `processing_image` (com tag). O CI/CD precisa publicar a imagem no ECR e atualizar esses valores. Opcoes:

1. **Terraform como fonte de verdade**
  - CI/CD faz build e push no ECR.
  - CI/CD atualiza as variaveis do Terraform Cloud (ex: `upload_image`) e dispara um run.
  - Terraform atualiza a task definition e o ECS faz rollout.

2. **Deploy direto no ECS (sem atualizar Terraform) >UTILIZADO<**
  - CI/CD faz `aws ecs update-service` com nova task definition.
  - Mais rapido, mas o estado do Terraform fica desatualizado.

3. **Pipeline duplo (Terraform + deploy)**
  - Terraform cria a infra.
  - CI/CD de cada servico faz deploy direto no ECS e ignora o Terraform para imagens.
  - Exige disciplina para nao mudar infra pelo pipeline de app.

Recursos provisionados: VPC, ECS Fargate, RDS PostgreSQL, S3, SQS, API Gateway, ECR, CloudWatch, Secrets Manager, IAM Roles.

## Validacao Semana 5 (Checklist)

Use este checklist para confirmar o que ja foi entregue e o que ainda precisa de ajuste:

1) **Bedrock habilitado na conta**
- Modelo `Claude 3 Sonnet` habilitado no console do Bedrock.
- Regiao do modelo igual a `bedrock_region`.

2) **Permissoes IAM**
- Task Role do processing-service possui `bedrock:InvokeModel` no ARN do modelo.
- Task Role do processing-service mantem permissoes de S3 e SQS.

3) **Variaveis de ambiente do processing-service**
- `AI_ADAPTER=bedrock`
- `BEDROCK_MODEL_ID` e `BEDROCK_REGION`
- `AWS_REGION`, `S3_BUCKET_NAME`, `SQS_QUEUE_URL`
- `UPLOAD_SERVICE_BASE_URL` e `REPORT_SERVICE_BASE_URL`

4) **ECS + Logs**
- Task definition atualizada com as variaveis acima.
- Logs no CloudWatch em `/ecs/fiap-hackaton-prod-processing` mostram chamadas Bedrock.

5) **Deploy**
- Pipeline de CD atualiza task definition e faz rollout no ECS.

## Semana 6 — Entregaveis e Execucao

### Entregaveis
- README completo com **seguranca**, fluxo end-to-end e troubleshooting (este arquivo).
- Diagrama de arquitetura exportado em [docs/architecture/architecture.md](docs/architecture/architecture.md).
- Evidencias de teste end-to-end (prints/logs).

### Runbook de Execucao (fim a fim)

1) **Pre-requisitos**
- Terraform Cloud configurado com variaveis do projeto.
- Bedrock habilitado na conta AWS na regiao correta.

2) **Provisionamento**
- Rodar `terraform plan` e `terraform apply` via Terraform Cloud.

3) **Deploy dos servicos**
- Publicar imagens no ECR.
- Executar pipelines de CD de cada servico.

4) **Teste do fluxo**
- `POST /v1/uploads` com arquivo valido.
- `GET /v1/jobs/{id}/status` ate status `ANALISADO`.
- `GET /v1/reports/{jobId}` para validar o relatorio.

5) **Validacao de logs**
- `processing-service`: confirmar logs de chamada Bedrock.
- `upload-service` e `report-service`: confirmar persistencia e consulta.

6) **Evidencias**
- Salvar prints do API Gateway, status do job e logs do CloudWatch.
