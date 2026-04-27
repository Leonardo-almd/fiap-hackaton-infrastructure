-- =============================================================================
-- Report Service Database Schema
-- Banco: report_db (exclusivo do report-service)
-- Descrição: Persiste os relatórios de análise arquitetural gerados pela IA.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- Tabela: reports
-- Relatório vinculado a um job de análise. Criado pelo processing-service.
-- =============================================================================
CREATE TABLE IF NOT EXISTS reports (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id      UUID        NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reports_job_id ON reports (job_id);

-- =============================================================================
-- Tabela: componentes
-- Componentes arquiteturais identificados no diagrama pela IA.
-- =============================================================================
CREATE TABLE IF NOT EXISTS componentes (
    id          BIGSERIAL       PRIMARY KEY,
    report_id   UUID            NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    nome        VARCHAR(200)    NOT NULL,
    tipo        VARCHAR(50)     NOT NULL,
    descricao   TEXT            NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT componentes_tipo_check CHECK (
        tipo IN ('GATEWAY', 'SERVICE', 'DATABASE', 'QUEUE', 'CACHE',
                 'CDN', 'LOAD_BALANCER', 'EXTERNAL', 'UNKNOWN')
    )
);

CREATE INDEX IF NOT EXISTS idx_componentes_report_id ON componentes (report_id);

-- =============================================================================
-- Tabela: riscos
-- Riscos arquiteturais detectados pela IA no diagrama.
-- =============================================================================
CREATE TABLE IF NOT EXISTS riscos (
    id                  BIGSERIAL       PRIMARY KEY,
    report_id           UUID            NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    severidade          VARCHAR(10)     NOT NULL,
    categoria           VARCHAR(30)     NOT NULL,
    titulo              VARCHAR(200)    NOT NULL,
    descricao           TEXT            NOT NULL,
    componentes_afetados TEXT[],
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT riscos_severidade_check CHECK (
        severidade IN ('ALTA', 'MEDIA', 'BAIXA')
    ),
    CONSTRAINT riscos_categoria_check CHECK (
        categoria IN ('SEGURANCA', 'ACOPLAMENTO', 'ESCALABILIDADE',
                      'DISPONIBILIDADE', 'PERFORMANCE', 'MANUTENCAO')
    )
);

CREATE INDEX IF NOT EXISTS idx_riscos_report_id ON riscos (report_id);
CREATE INDEX IF NOT EXISTS idx_riscos_severidade ON riscos (severidade);

-- =============================================================================
-- Tabela: recomendacoes
-- Recomendações geradas pela IA para mitigar os riscos encontrados.
-- =============================================================================
CREATE TABLE IF NOT EXISTS recomendacoes (
    id          BIGSERIAL       PRIMARY KEY,
    report_id   UUID            NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    prioridade  VARCHAR(10)     NOT NULL,
    titulo      VARCHAR(200)    NOT NULL,
    descricao   TEXT            NOT NULL,
    referencias TEXT[],
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT recomendacoes_prioridade_check CHECK (
        prioridade IN ('ALTA', 'MEDIA', 'BAIXA')
    )
);

CREATE INDEX IF NOT EXISTS idx_recomendacoes_report_id ON recomendacoes (report_id);
CREATE INDEX IF NOT EXISTS idx_recomendacoes_prioridade ON recomendacoes (prioridade);
