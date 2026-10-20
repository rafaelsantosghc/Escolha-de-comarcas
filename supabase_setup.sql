-- =====================================================================
-- SCRIPT COMPLETO DE CONFIGURAÇÃO E MIGRAÇÃO: SUPABASE POSTGRESQL
-- TJRS - Escolha de Comarcas e Gestão de Lotes (Vercel + Supabase)
-- =====================================================================
-- INSTRUÇÕES DE EXECUÇÃO:
-- 1. Abra o painel do seu projeto no Supabase (https://supabase.com/dashboard).
-- 2. No menu lateral esquerdo, clique em "SQL Editor".
-- 3. Caso tenha abas abertas chamadas "Untitled query", você pode fechá-las
--    ou excluí-las sem nenhum receio (elas são apenas rascunhos em branco).
-- 4. Clique em "+ New query", cole TODO este script abaixo e clique em "RUN".
-- =====================================================================

-- 1. CRIAÇÃO DAS TABELAS ESSENCIAIS
CREATE TABLE IF NOT EXISTS public.concursos (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    cargo TEXT,
    orgao TEXT DEFAULT 'TJRS',
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.lotes (
    id TEXT NOT NULL,
    concurso_id TEXT NOT NULL REFERENCES public.concursos(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    ativo BOOLEAN DEFAULT false,
    is_ranking_visible BOOLEAN DEFAULT true,
    is_printing_enabled BOOLEAN DEFAULT true,
    travado BOOLEAN DEFAULT false,
    senha TEXT DEFAULT '',
    comarcas JSONB DEFAULT '[]'::jsonb,
    candidatos JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (id, concurso_id)
);

CREATE TABLE IF NOT EXISTS public.respostas (
    id TEXT PRIMARY KEY,
    concurso_id TEXT DEFAULT 'tjrs_analista_2024',
    lote_id TEXT NOT NULL,
    ambiente TEXT DEFAULT 'prod',
    nome TEXT NOT NULL,
    cpf TEXT DEFAULT '',
    email TEXT DEFAULT '',
    whatsapp TEXT DEFAULT '',
    intencao TEXT DEFAULT 'assumir',
    escolhas JSONB DEFAULT '[]'::jsonb,
    possui_fg_cc TEXT DEFAULT 'Não',
    fg_cc_registro_funcional TEXT DEFAULT '',
    fg_cc_cargo TEXT DEFAULT '',
    fg_cc_comarca_atual TEXT DEFAULT '',
    fg_cc_pretende_continuar TEXT DEFAULT '',
    bloqueado BOOLEAN DEFAULT true,
    dados_cadastrais_bloqueados BOOLEAN DEFAULT true,
    dados_completos JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.configuracoes (
    chave TEXT PRIMARY KEY,
    valor JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.comarcas_tjrs (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    regiao TEXT DEFAULT 'RS',
    ativo BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.candidatos_base (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    cpf TEXT DEFAULT '',
    email TEXT DEFAULT '',
    whatsapp TEXT DEFAULT '',
    tipo TEXT DEFAULT 'PF',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================================
-- 2. HABILITAÇÃO DO ROW LEVEL SECURITY (RLS) COM POLÍTICAS PERMISSIVAS
-- Garante que o site hospedado na Vercel consiga ler, criar lotes,
-- salvar configurações e registrar respostas sem erro 42501!
-- =====================================================================

ALTER TABLE public.concursos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.respostas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comarcas_tjrs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidatos_base ENABLE ROW LEVEL SECURITY;

-- Políticas para concursos (Leitura pública e Escrita liberada)
DROP POLICY IF EXISTS "concursos_leitura_publica" ON public.concursos;
CREATE POLICY "concursos_leitura_publica" ON public.concursos FOR SELECT USING (true);
DROP POLICY IF EXISTS "concursos_escrita_publica" ON public.concursos;
CREATE POLICY "concursos_escrita_publica" ON public.concursos FOR ALL USING (true) WITH CHECK (true);

-- Políticas para lotes (Leitura pública e Gestão liberada)
DROP POLICY IF EXISTS "lotes_leitura_publica" ON public.lotes;
CREATE POLICY "lotes_leitura_publica" ON public.lotes FOR SELECT USING (true);
DROP POLICY IF EXISTS "lotes_escrita_publica" ON public.lotes;
CREATE POLICY "lotes_escrita_publica" ON public.lotes FOR ALL USING (true) WITH CHECK (true);

-- Políticas para respostas (Leitura e gravação de escolhas liberada)
DROP POLICY IF EXISTS "respostas_leitura_publica" ON public.respostas;
CREATE POLICY "respostas_leitura_publica" ON public.respostas FOR SELECT USING (true);
DROP POLICY IF EXISTS "respostas_escrita_publica" ON public.respostas;
CREATE POLICY "respostas_escrita_publica" ON public.respostas FOR ALL USING (true) WITH CHECK (true);

-- Políticas para configuracoes (Armazenamento de dados gerais e Central de Candidatos)
DROP POLICY IF EXISTS "configuracoes_leitura_publica" ON public.configuracoes;
CREATE POLICY "configuracoes_leitura_publica" ON public.configuracoes FOR SELECT USING (true);
DROP POLICY IF EXISTS "configuracoes_escrita_publica" ON public.configuracoes;
CREATE POLICY "configuracoes_escrita_publica" ON public.configuracoes FOR ALL USING (true) WITH CHECK (true);

-- Políticas para comarcas_tjrs (Catálogo oficial das 167 comarcas)
DROP POLICY IF EXISTS "comarcas_tjrs_leitura_publica" ON public.comarcas_tjrs;
CREATE POLICY "comarcas_tjrs_leitura_publica" ON public.comarcas_tjrs FOR SELECT USING (true);
DROP POLICY IF EXISTS "comarcas_tjrs_escrita_publica" ON public.comarcas_tjrs;
CREATE POLICY "comarcas_tjrs_escrita_publica" ON public.comarcas_tjrs FOR ALL USING (true) WITH CHECK (true);

-- Políticas para candidatos_base
DROP POLICY IF EXISTS "candidatos_base_leitura_publica" ON public.candidatos_base;
CREATE POLICY "candidatos_base_leitura_publica" ON public.candidatos_base FOR SELECT USING (true);
DROP POLICY IF EXISTS "candidatos_base_escrita_publica" ON public.candidatos_base;
CREATE POLICY "candidatos_base_escrita_publica" ON public.candidatos_base FOR ALL USING (true) WITH CHECK (true);

-- =====================================================================
-- 3. SEED INICIAL: CONCURSO PADRÃO TJRS
-- =====================================================================
INSERT INTO public.concursos (id, nome, cargo, orgao, ativo)
VALUES (
    'tjrs_analista_2024',
    'Concurso TJRS - Analista Judiciário',
    'Analista Judiciário - Área Judiciária',
    'TJRS',
    true
)
ON CONFLICT (id) DO UPDATE SET
    nome = EXCLUDED.nome,
    cargo = EXCLUDED.cargo,
    orgao = EXCLUDED.orgao,
    ativo = EXCLUDED.ativo;

-- =====================================================================
-- FIM DO SCRIPT
-- =====================================================================
