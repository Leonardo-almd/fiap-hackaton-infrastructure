# Fluxo end-to-end (jornada do usuario)

Este documento descreve o fluxo completo de uso do sistema, incluindo como chamar as APIs, onde encontrar enderecos e o que validar em cada etapa.

## 1) Onde encontrar os enderecos

### Ambiente AWS (API Gateway)
- O endpoint principal vem do output `api_gateway_invoke_url` do Terraform.
- No Terraform Cloud, abra o workspace e copie o output `api_gateway_invoke_url`.
- O endpoint tem formato semelhante a:
  - `https://<api-id>.execute-api.<regiao>.amazonaws.com/<stage>`

### Ambiente local (Docker Compose)
- Upload: `http://localhost:8080`
- Processing: `http://localhost:8081`
- Report: `http://localhost:8082`

## 2) Credenciais e headers

### API Key (AWS)
- Necessario enviar `x-api-key` em todas as chamadas ao API Gateway.
- O valor esta na variavel `api_key_value` do Terraform Cloud.

### Exemplo de headers
- `x-api-key: <SUA_API_KEY>`
- `Content-Type: multipart/form-data` no upload

## 3) Fluxo de ponta a ponta

### Passo A) Upload do diagrama

**Endpoint (AWS)**:
- `POST {api_gateway_invoke_url}/v1/uploads`

**Endpoint (local)**:
- `POST http://localhost:8080/v1/uploads`

**Exemplo de chamada**:

```bash
curl -X POST "${API_URL}/v1/uploads" \
  -H "x-api-key: ${API_KEY}" \
  -F "file=@/caminho/diagrama.png;type=image/png" \
  -F "description=Teste de processamento"
```

**O que validar**:
- Resposta retorna `jobId`.
- Status inicial do job: `RECEBIDO`.
- Arquivo enviado aparece no bucket S3 (ambiente AWS).

**Exemplo de resposta esperada**:

```json
{
  "jobId": "5f2c2c6d-9bb8-4a78-9c8d-9d6b3f3b5e5c",
  "status": "RECEBIDO",
  "message": "Upload recebido"
}
```

### Passo B) Acompanhar status do job

**Endpoint (AWS)**:
- `GET {api_gateway_invoke_url}/v1/jobs/{jobId}/status`

**Endpoint (local)**:
- `GET http://localhost:8080/v1/jobs/{jobId}/status`

**Exemplo de chamada**:

```bash
curl -H "x-api-key: ${API_KEY}" \
  "${API_URL}/v1/jobs/${JOB_ID}/status"
```

**O que validar**:
- Status transita de `RECEBIDO` -> `EM_PROCESSAMENTO` -> `ANALISADO`.
- Se houver erro, validar mensagem de erro e logs do processing-service.

**Exemplo de resposta esperada**:

```json
{
  "jobId": "5f2c2c6d-9bb8-4a78-9c8d-9d6b3f3b5e5c",
  "status": "EM_PROCESSAMENTO",
  "updatedAt": "2026-05-16T12:34:56Z"
}
```

### Passo C) Consultar relatorio

**Endpoint (AWS)**:
- `GET {api_gateway_invoke_url}/v1/reports/{jobId}`

**Endpoint (local)**:
- `GET http://localhost:8082/v1/reports/{jobId}`

**Exemplo de chamada**:

```bash
curl -H "x-api-key: ${API_KEY}" \
  "${API_URL}/v1/reports/${JOB_ID}"
```

**O que validar**:
- Resposta contem `componentes`, `riscos`, `recomendacoes`.
- Estrutura segue o schema `docs/schemas/report.json`.

**Exemplo de resposta esperada**:

```json
{
  "jobId": "5f2c2c6d-9bb8-4a78-9c8d-9d6b3f3b5e5c",
  "componentes": [
    {"nome": "API Gateway", "tipo": "gateway"},
    {"nome": "ECS Fargate", "tipo": "compute"}
  ],
  "riscos": [
    {"descricao": "Sem rate limit no gateway", "severidade": "media"}
  ],
  "recomendacoes": [
    {"descricao": "Adicionar WAF e throttling"}
  ]
}
```

## 4) Validacao tecnica do processamento

### Logs no CloudWatch (AWS)
- Upload: `/ecs/fiap-hackaton-prod-upload`
- Processing: `/ecs/fiap-hackaton-prod-processing`
- Report: `/ecs/fiap-hackaton-prod-report`

**O que procurar**:
- Processing-service: logs indicando inicio e fim da analise.
- Se Bedrock estiver ativo: logs com `BedrockAIAdapter`.

### Logs locais (Docker Compose)

```bash
docker compose logs -f upload-service
docker compose logs -f processing-service
docker compose logs -f report-service
```

## 5) Troubleshooting rapido

### Status nao sai de RECEBIDO
- Verificar se o processing-service esta rodando.
- Verificar se a fila SQS esta criada.
- Validar variaveis `SQS_QUEUE_URL`, `UPLOAD_SERVICE_BASE_URL`, `REPORT_SERVICE_BASE_URL`.

### Erro ao invocar Bedrock
- Modelo nao habilitado na conta.
- Falta permissao `bedrock:InvokeModel` na task role do processing-service.
- `BEDROCK_REGION` incorreta.

### Erro ao buscar relatorio
- Report-service nao recebeu o payload (ver logs).
- Banco `report_db` indisponivel.

## 6) Variaveis recomendadas (AWS)

- `API_URL`: `api_gateway_invoke_url`
- `API_KEY`: valor de `api_key_value` no Terraform Cloud
- `JOB_ID`: retornado no upload

Exemplo de export:

```bash
export API_URL="https://<api-id>.execute-api.<regiao>.amazonaws.com/prod"
export API_KEY="<SUA_API_KEY>"
export JOB_ID="<JOB_ID>"
```
