-- =============================================================================
-- Upload Service Database Schema
-- Banco: upload_db (exclusivo do upload-service)
-- Descrição: Persiste os jobs de análise e seus estados ao longo do fluxo.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- para gen_random_uuid()

-- =============================================================================
-- Tabela: jobs
-- Representa um job de análise criado a partir de um upload de diagrama.
-- =============================================================================
CREATE TABLE IF NOT EXISTS jobs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    status          VARCHAR(20)     NOT NULL DEFAULT 'RECEBIDO',
    s3_key          VARCHAR(512)    NOT NULL,
    original_filename VARCHAR(255)  NOT NULL,
    file_type       VARCHAR(10)     NOT NULL,
    file_size_bytes BIGINT          NOT NULL,
    description     VARCHAR(500),
    error_message   TEXT,
    report_id       UUID,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT jobs_status_check CHECK (
        status IN ('RECEBIDO', 'EM_PROCESSAMENTO', 'ANALISADO', 'ERRO')
    ),
    CONSTRAINT jobs_file_type_check CHECK (
        file_type IN ('PDF', 'PNG', 'JPG', 'JPEG')
    ),
    CONSTRAINT jobs_file_size_check CHECK (
        file_size_bytes > 0 AND file_size_bytes <= 10485760
    )
);

-- Índice para buscas por status (ex: monitorar jobs pendentes)
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs (status);

-- Índice para ordenação por data de criação
CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON jobs (created_at DESC);

-- =============================================================================
-- Função e trigger: atualiza updated_at automaticamente
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- Tabela: job_events (log de transições de estado para auditoria)
-- =============================================================================
CREATE TABLE IF NOT EXISTS job_events (
    id          BIGSERIAL       PRIMARY KEY,
    job_id      UUID            NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    from_status VARCHAR(20),
    to_status   VARCHAR(20)     NOT NULL,
    message     TEXT,
    occurred_at TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT job_events_to_status_check CHECK (
        to_status IN ('RECEBIDO', 'EM_PROCESSAMENTO', 'ANALISADO', 'ERRO')
    )
);

CREATE INDEX IF NOT EXISTS idx_job_events_job_id ON job_events (job_id);
CREATE INDEX IF NOT EXISTS idx_job_events_occurred_at ON job_events (occurred_at DESC);

-- =============================================================================
-- Dados iniciais de exemplo (apenas para ambiente de desenvolvimento)
-- =============================================================================
-- INSERT INTO jobs (id, status, s3_key, original_filename, file_type, file_size_bytes, description)
-- VALUES (
--     '550e8400-e29b-41d4-a716-446655440000',
--     'RECEBIDO',
--     'uploads/550e8400-e29b-41d4-a716-446655440000.pdf',
--     'arquitetura-ecommerce-v2.pdf',
--     'PDF',
--     245760,
--     'Diagrama da nova versão do sistema de e-commerce'
-- );
