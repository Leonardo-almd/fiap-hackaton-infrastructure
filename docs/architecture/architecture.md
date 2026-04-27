# Arquitetura — FIAP Secure Systems MVP

## Visão Geral

O sistema é composto por **3 microsserviços Spring Boot** orquestrados via **AWS API Gateway**, com comunicação assíncrona via **AWS SQS** e armazenamento de arquivos no **AWS S3**.

Cada serviço possui banco de dados próprio (**RDS PostgreSQL**), seguindo o princípio de isolamento de dados de microsserviços.

---

## Diagrama de Arquitetura

```mermaid
flowchart TD
    Client["Cliente (REST / Browser)"]
    APIGW["AWS API Gateway\n(Roteamento + API Key)"]

    subgraph uploadSvc [upload-service — porta 8080]
        UploadController["UploadController\nPOST /uploads\nGET /jobs/{id}/status"]
        UploadUseCase["UploadDiagramUseCase"]
        JobRepository["JobRepository"]
        S3Port["S3Port (interface)"]
        SQSPort["SQSPort (interface)"]
    end

    subgraph processingSvc [processing-service — porta 8081]
        SQSConsumer["SQSConsumer\n(polling SQS)"]
        ProcessUseCase["ProcessDiagramUseCase"]
        AIPort["AIAnalysisPort (interface)\n→ stub / Bedrock"]
        ReportClient["ReportServiceClient\n(HTTP interno)"]
    end

    subgraph reportSvc [report-service — porta 8082]
        ReportController["ReportController\nGET /reports/{jobId}\nPOST /reports (interno)"]
        ReportRepository["ReportRepository"]
    end

    UploadDB[("RDS PostgreSQL\nupload_db")]
    ReportDB[("RDS PostgreSQL\nreport_db")]
    S3[("AWS S3\nbucket: fiap-diagrams")]
    SQS[("AWS SQS\nfila: diagram-analysis")]
    AI["Amazon Bedrock\nClaude 3 Sonnet\n(Fase 2)"]

    Client -->|"HTTPS"| APIGW
    APIGW -->|"POST /uploads\nGET /jobs/{id}/status"| uploadSvc
    APIGW -->|"GET /reports/{jobId}"| reportSvc

    UploadController --> UploadUseCase
    UploadUseCase --> S3Port --> S3
    UploadUseCase --> JobRepository --> UploadDB
    UploadUseCase --> SQSPort --> SQS

    SQS -->|"polling"| SQSConsumer
    SQSConsumer --> ProcessUseCase
    ProcessUseCase -->|"GET arquivo"| S3
    ProcessUseCase -->|"atualiza status"| UploadDB
    ProcessUseCase --> AIPort --> AI
    ProcessUseCase --> ReportClient -->|"POST /reports"| reportSvc

    ReportController --> ReportRepository --> ReportDB
```

---

## Fluxo Principal

```mermaid
sequenceDiagram
    actor C as Cliente
    participant GW as API Gateway
    participant US as upload-service
    participant S3 as AWS S3
    participant SQS as AWS SQS
    participant PS as processing-service
    participant AI as IA (Bedrock)
    participant RS as report-service

    C->>GW: POST /v1/uploads (multipart/form-data)
    GW->>US: encaminha requisição
    US->>US: valida arquivo (tipo, tamanho)
    US->>S3: armazena arquivo
    US->>US: cria job (status=RECEBIDO)
    US->>SQS: publica mensagem (jobId, s3Key, fileType)
    US-->>C: 202 Accepted { jobId, status: RECEBIDO }

    C->>GW: GET /v1/jobs/{jobId}/status
    GW->>US: consulta status
    US-->>C: { status: RECEBIDO }

    PS->>SQS: polling (a cada 5s)
    SQS-->>PS: mensagem disponível
    PS->>US: PATCH status → EM_PROCESSAMENTO
    PS->>S3: download do arquivo
    PS->>AI: envia conteúdo + prompt
    AI-->>PS: { componentes, riscos, recomendacoes }
    PS->>RS: POST /reports (cria relatório)
    PS->>US: PATCH status → ANALISADO (com reportId)

    C->>GW: GET /v1/jobs/{jobId}/status
    GW->>US: consulta status
    US-->>C: { status: ANALISADO, reportId: "..." }

    C->>GW: GET /v1/reports/{jobId}
    GW->>RS: busca relatório
    RS-->>C: relatório completo { componentes, riscos, recomendacoes }
```

---

## Fluxo de Status do Job

```
RECEBIDO → EM_PROCESSAMENTO → ANALISADO
                           ↘ ERRO
```

| Status | Quem define | Quando |
|---|---|---|
| `RECEBIDO` | upload-service | Ao criar o job após salvar no S3 e publicar no SQS |
| `EM_PROCESSAMENTO` | processing-service | Ao consumir a mensagem da fila |
| `ANALISADO` | processing-service | Após receber resposta da IA e persistir relatório |
| `ERRO` | processing-service | Em caso de falha em qualquer etapa do processamento |

---

## Decisões Arquiteturais

### 1. Arquitetura Hexagonal por serviço
Cada serviço segue a arquitetura hexagonal (Ports & Adapters):
- **Domain**: entidades e casos de uso sem dependência de frameworks
- **Application**: orquestração dos casos de uso
- **Adapters (in)**: controllers REST, consumers SQS
- **Adapters (out)**: repositórios JPA, clientes S3, clientes SQS, clientes HTTP

### 2. Comunicação assíncrona via SQS
O upload não aguarda o processamento da IA (que pode levar segundos a minutos). A fila SQS desacopla os dois serviços e permite:
- Retry automático em caso de falha
- Dead Letter Queue (DLQ) para mensagens que falharam repetidamente
- Processamento em paralelo caso múltiplos consumers sejam adicionados

### 3. Banco de dados por serviço
- `upload_db`: exclusivo do upload-service (jobs, status, eventos)
- `report_db`: exclusivo do report-service (relatórios, componentes, riscos, recomendações)
- O processing-service **não possui banco próprio** — atualiza o `upload_db` via HTTP interno e persiste no `report_db` via report-service

### 4. API Gateway gerenciado (AWS)
Evita criar um serviço extra de roteamento. Responsabilidades:
- Roteamento para os serviços
- Validação de API Key (autenticação básica para o MVP)
- Rate limiting
- Logs de acesso no CloudWatch

### 5. Stub de IA na Fase 1 (SOAT)
O processing-service implementa a interface `AIAnalysisPort`. Na Fase 1, um adapter `StubAIAdapter` retorna dados mockados com a estrutura real do relatório. Na Fase 2, um `BedrockAIAdapter` substitui o stub sem alterar o restante da lógica.

---

## Estrutura de Pastas (por serviço)

```
{service-name}/
├── src/
│   ├── main/
│   │   ├── java/br/com/fiap/{service}/
│   │   │   ├── domain/
│   │   │   │   ├── model/          # Entidades e value objects
│   │   │   │   └── port/           # Interfaces (in e out)
│   │   │   ├── application/
│   │   │   │   └── usecase/        # Casos de uso
│   │   │   ├── adapter/
│   │   │   │   ├── in/
│   │   │   │   │   ├── web/        # Controllers REST
│   │   │   │   │   └── sqs/        # Consumers SQS
│   │   │   │   └── out/
│   │   │   │       ├── persistence/ # Repositórios JPA
│   │   │   │       ├── aws/         # Clientes S3, SQS
│   │   │   │       └── http/        # Clientes HTTP (Feign/RestClient)
│   │   │   └── config/             # Configurações Spring, AWS
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/       # Scripts Flyway
│   └── test/
│       └── java/br/com/fiap/{service}/
│           ├── unit/
│           └── integration/
├── Dockerfile
└── pom.xml
```

---

## Infraestrutura AWS

| Recurso | Serviço AWS | Configuração |
|---|---|---|
| Armazenamento de arquivos | S3 | Bucket privado, server-side encryption (SSE-S3) |
| Fila de mensagens | SQS | Standard Queue + DLQ (maxReceiveCount: 3) |
| Banco de dados | RDS PostgreSQL 16 | db.t3.micro por serviço (MVP) |
| Containers | ECS Fargate | Task per service, Auto Scaling |
| Roteamento | API Gateway | REST API, stage: dev/prod |
| Secrets | Secrets Manager | Credenciais de DB, chaves de API |
| Logs | CloudWatch | Log groups por serviço, retenção 30 dias |
| Imagens Docker | ECR | Repositório por serviço |
| Rede | VPC | Private subnets para serviços e DBs, public para ALB |

---

## Segurança

| Ameaça | Mitigação |
|---|---|
| Arquivo malicioso no upload | Validação de MIME type + extensão; limite de tamanho (10MB) |
| Acesso não autorizado à API | API Key no API Gateway (MVP); plano futuro: Cognito |
| Dados em repouso | S3 SSE-S3; RDS encryption at rest |
| Dados em trânsito | HTTPS obrigatório; TLS entre serviços internos |
| Injeção via prompt (IA) | Guardrails de entrada e saída; validação de schema JSON |
| Alucinações da IA | Validação do JSON retornado; fallback para ERRO se inválido |
| Acesso entre serviços | IAM roles por serviço; Security Groups restritivos |
| DLQ e mensagens venenosas | DLQ configurada; alertas no CloudWatch |
