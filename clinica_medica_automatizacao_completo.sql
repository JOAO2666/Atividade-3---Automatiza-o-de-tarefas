-- =================================================================================
-- SENAI - UNIDADE CURRICULAR: UC13 - BANCO DE DADOS
-- TURMA: CTMSP_DPE_QO_FULLST_252T01_BDADO_QUA.568.004
-- PROJETO: BANCO DE DADOS DA CLÍNICA MÉDICA (clinica_medica)
-- ATIVIDADE 3: AUTOMATIZAÇÃO DE TAREFAS (TRIGGERS E STORED PROCEDURES)
-- =================================================================================

-- 1. CRIAÇÃO DA BASE DE DADOS E CONTEXTUALIZAÇÃO
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'clinica_medica')
BEGIN
    CREATE DATABASE clinica_medica;
END
GO

USE clinica_medica;
GO

-- 2. CRIAÇÃO DAS TABELAS (DDL)
-- Tabela paciente
IF OBJECT_ID('pedido_exame', 'U') IS NOT NULL DROP TABLE pedido_exame;
IF OBJECT_ID('consulta', 'U') IS NOT NULL DROP TABLE consulta;
IF OBJECT_ID('exame', 'U') IS NOT NULL DROP TABLE exame;
IF OBJECT_ID('medico', 'U') IS NOT NULL DROP TABLE medico;
IF OBJECT_ID('paciente', 'U') IS NOT NULL DROP TABLE paciente;
GO

CREATE TABLE paciente (
    cpf varchar(14) PRIMARY KEY,
    nome_paciente varchar(40),
    telefone varchar(14),
    numero_plano int,
    nome_plano varchar(20),
    tipo_plano varchar(10)
);

CREATE TABLE medico (
    crm int PRIMARY KEY,
    nome_medico varchar(30),
    especialidade varchar(20)
);

CREATE TABLE exame (
    codigo int PRIMARY KEY,
    especificacao varchar(20),
    preco money
);

CREATE TABLE consulta (
    numero_consulta int identity(22000, 1) PRIMARY KEY,
    data_consulta date,
    horario_consulta time,
    fk_paciente_cpf varchar(14),
    fk_medico_crm int,
    CONSTRAINT FK_consulta_paciente FOREIGN KEY (fk_paciente_cpf) REFERENCES paciente(cpf) ON DELETE CASCADE,
    CONSTRAINT FK_consulta_medico FOREIGN KEY (fk_medico_crm) REFERENCES medico(crm) ON DELETE CASCADE
);

CREATE TABLE pedido_exame (
    numero_pedido int identity(2200, 1) PRIMARY KEY,
    resultado varchar(40),
    data_exame date,
    valor_pagar money,
    fk_consulta_numero_consulta int,
    fk_exame_codigo int,
    CONSTRAINT FK_pedido_exame_consulta FOREIGN KEY (fk_consulta_numero_consulta) REFERENCES consulta(numero_consulta) ON DELETE CASCADE,
    CONSTRAINT FK_pedido_exame_exame FOREIGN KEY (fk_exame_codigo) REFERENCES exame(codigo)
);
GO

-- 3. INSERÇÃO DE DADOS BASE (PACIENTE, MEDICO, EXAME, CONSULTA)
INSERT INTO paciente VALUES('012.345.678-90', 'Leonardo Ribeiro', '(11)91234-5678', 123456, 'Inovamed', 'Padrão');
INSERT INTO paciente VALUES('123.456.789-12', 'Bruna Alvez', '(15)92345-6789', 234567, 'Ultramed', 'Básico');
INSERT INTO paciente VALUES('234.567.890-23', 'Gilberto Barros', '(11)94567-8901', 345678, 'Inovamed', 'Especial');
INSERT INTO paciente VALUES('345.678.901-45', 'Maria Pereira', '(12)95678-9012', 456789, 'Ultramed', 'Padrão');
INSERT INTO paciente VALUES('456.789.012-34', 'Arnaldo Coelho', '(19)96789-0123', 567890, 'Inovamed', 'Especial');

INSERT INTO medico VALUES(102030, 'Agildo Nunes', 'Cardiologia');
INSERT INTO medico VALUES(203040, 'Márcia Alvez', 'Gastrologia');
INSERT INTO medico VALUES(304050, 'Roberto Gusmão', 'Neurologia');
INSERT INTO medico VALUES(405060, 'Edna Cardoso', 'Ortopedia');
INSERT INTO medico VALUES(506070, 'Ricardo Souza', 'Otorrinolaringologia');
INSERT INTO medico VALUES(607080, 'Lúcia Marques', 'Pediatria');
INSERT INTO medico VALUES(708090, 'Beatriz Lucena', 'Oncologia');

INSERT INTO exame VALUES(10020, 'Hemograma', 100.00);
INSERT INTO exame VALUES(10030, 'Tomografia', 250.00);
INSERT INTO exame VALUES(10040, 'Ultrassonografia', 550.00);
INSERT INTO exame VALUES(10050, 'Ressonância', 800.00);
INSERT INTO exame VALUES(10060, 'Radiografia', 70.00);
INSERT INTO exame VALUES(10070, 'Mamografia', 150.00);
INSERT INTO exame VALUES(10080, 'Endoscopia', 300.00);
INSERT INTO exame VALUES(10090, 'Colonoscopia', 300.00);
INSERT INTO exame VALUES(10100, 'Eletrocardiograma', 50.00);
INSERT INTO exame VALUES(10110, 'Ecocardiograma', 120.00);
INSERT INTO exame VALUES(10120, 'Audiometria', 65.00);

INSERT INTO consulta VALUES('2022/12/12', '14:30', '012.345.678-90', 102030);
INSERT INTO consulta VALUES('2022/12/13', '08:30', '123.456.789-12', 203040);
INSERT INTO consulta VALUES('2022/12/13', '11:00', '123.456.789-12', 304050);
INSERT INTO consulta VALUES('2022/12/14', '10:00', '234.567.890-23', 203040);
INSERT INTO consulta VALUES('2022/12/15', '15:00', '345.678.901-45', 405060);
INSERT INTO consulta VALUES('2022/12/16', '10:00', '123.456.789-12', 506070);
INSERT INTO consulta VALUES('2022/12/19', '16:45', '234.567.890-23', 102030);
INSERT INTO consulta VALUES('2022/12/19', '18:00', '345.678.901-45', 607080);
INSERT INTO consulta VALUES('2022/12/20', '09:00', '012.345.678-90', 304050);
INSERT INTO consulta VALUES('2022/12/20', '14:20', '123.456.789-12', 102030);
GO

-- =================================================================================
-- 4. AUTOMAÇÃO 1: TRIGGER (GATILHO) DE CÁLCULO DE VALOR A PAGAR
-- =================================================================================
-- Drop trigger se já existir
IF OBJECT_ID('Atualiza_Pedido_Exame', 'TR') IS NOT NULL
    DROP TRIGGER Atualiza_Pedido_Exame;
GO

CREATE TRIGGER Atualiza_Pedido_Exame
ON pedido_exame
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declaração de variáveis para armazenar dados da linha inserida
    DECLARE @num_ped AS int;
    DECLARE @num_cons AS int;
    DECLARE @cod_ex AS int;
    DECLARE @prc AS money;
    DECLARE @cpf_pac AS varchar(20);
    DECLARE @tp_plan AS varchar(20);

    -- Captura dos dados a partir da pseudo-tabela INSERTED
    SELECT @num_ped = numero_pedido,
           @num_cons = fk_consulta_numero_consulta,
           @cod_ex = fk_exame_codigo
    FROM inserted;

    -- Busca preço base na tabela exame
    SELECT @prc = preco FROM exame WHERE codigo = @cod_ex;

    -- Busca CPF do paciente na tabela consulta
    SELECT @cpf_pac = fk_paciente_cpf FROM consulta WHERE numero_consulta = @num_cons;

    -- Busca tipo de plano na tabela paciente
    SELECT @tp_plan = tipo_plano FROM paciente WHERE cpf = @cpf_pac;

    -- Aplicação das regras de negócio condicionais:
    -- Plano Especial: 100% de desconto (cobertura total)
    IF @tp_plan = 'Especial'
    BEGIN
        UPDATE pedido_exame 
        SET valor_pagar = @prc - (@prc * 100 / 100) 
        WHERE numero_pedido = @num_ped;
    END

    -- Plano Padrão: 30% de desconto
    IF @tp_plan = 'Padrão'
    BEGIN
        UPDATE pedido_exame 
        SET valor_pagar = @prc - (@prc * 30 / 100) 
        WHERE numero_pedido = @num_ped;
    END

    -- Plano Básico: 10% de desconto
    IF @tp_plan = 'Básico'
    BEGIN
        UPDATE pedido_exame 
        SET valor_pagar = @prc - (@prc * 10 / 100) 
        WHERE numero_pedido = @num_ped;
    END

    PRINT 'Trigger (Atualiza Pedido de Exame) Encerrada com sucesso para o Pedido: ' + CAST(@num_ped AS varchar(10));
END;
GO

-- =================================================================================
-- 5. REINICIALIZAÇÃO DO IDENTITY E INSERÇÃO PARA DISPARO DA TRIGGER
-- =================================================================================
-- Limpa tabela pedido_exame
DELETE FROM pedido_exame;

-- Reinicia contador IDENTITY para que o próximo seja 2200
DBCC CHECKIDENT('pedido_exame', RESEED, 2199);
GO

-- Inserção dos pedidos de exame (a trigger calculará valor_pagar automaticamente)
INSERT INTO pedido_exame VALUES('Normal', '2022/12/15', 0.00, 22000, 10040);
INSERT INTO pedido_exame VALUES('', '2022/12/19', 0.00, 22000, 10100);
INSERT INTO pedido_exame VALUES('', '2022/12/16', 0.00, 22001, 10080);
INSERT INTO pedido_exame VALUES('Normal', '2022/12/15', 0.00, 22002, 10050);
INSERT INTO pedido_exame VALUES('Inconsistente', '2022/12/16', 0.00, 22003, 10080);
INSERT INTO pedido_exame VALUES('', '2022/12/17', 0.00, 22004, 10060);
INSERT INTO pedido_exame VALUES('Normal', '2022/12/21', 0.00, 22007, 10020);
INSERT INTO pedido_exame VALUES('', '2022/12/22', 0.00, 22008, 10030);
INSERT INTO pedido_exame VALUES('', '2022/12/22', 0.00, 22008, 10050);
GO

-- Verificação da tabela pedido_exame com valores calculados
SELECT * FROM pedido_exame;
GO

-- =================================================================================
-- 6. AUTOMAÇÃO 2: STORED PROCEDURES (PROCEDIMENTOS ARMAZENADOS)
-- =================================================================================

-- 6.1 Stored Procedure: Agenda_Medicos
IF OBJECT_ID('Agenda_Medicos', 'P') IS NOT NULL DROP PROCEDURE Agenda_Medicos;
GO
CREATE PROCEDURE Agenda_Medicos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        m.nome_medico,
        m.especialidade,
        m.crm,
        c.numero_consulta,
        c.data_consulta,
        c.horario_consulta,
        p.nome_paciente,
        p.cpf,
        p.nome_plano,
        p.tipo_plano
    FROM medico AS m
    INNER JOIN consulta AS c ON m.crm = c.fk_medico_crm
    INNER JOIN paciente AS p ON c.fk_paciente_cpf = p.cpf
    ORDER BY m.nome_medico, c.data_consulta;
END;
GO

-- 6.2 Stored Procedure: Exames_Solicitados
IF OBJECT_ID('Exames_Solicitados', 'P') IS NOT NULL DROP PROCEDURE Exames_Solicitados;
GO
CREATE PROCEDURE Exames_Solicitados
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        m.nome_medico,
        m.especialidade,
        m.crm,
        c.numero_consulta,
        p.numero_pedido,
        p.data_exame,
        e.codigo,
        e.especificacao
    FROM medico AS m
    INNER JOIN consulta AS c ON m.crm = c.fk_medico_crm
    INNER JOIN pedido_exame AS p ON c.numero_consulta = p.fk_consulta_numero_consulta
    INNER JOIN exame AS e ON p.fk_exame_codigo = e.codigo
    ORDER BY m.nome_medico, p.data_exame;
END;
GO

-- 6.3 Stored Procedure: Historico_Pagamentos
IF OBJECT_ID('Historico_Pagamentos', 'P') IS NOT NULL DROP PROCEDURE Historico_Pagamentos;
GO
CREATE PROCEDURE Historico_Pagamentos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        pa.nome_paciente,
        pa.cpf,
        c.numero_consulta,
        c.data_consulta,
        pe.data_exame,
        pe.valor_pagar,
        e.codigo,
        e.especificacao
    FROM paciente AS pa
    INNER JOIN consulta AS c ON pa.cpf = c.fk_paciente_cpf
    INNER JOIN pedido_exame AS pe ON c.numero_consulta = pe.fk_consulta_numero_consulta
    INNER JOIN exame AS e ON pe.fk_exame_codigo = e.codigo
    ORDER BY pa.nome_paciente, pe.data_exame;
END;
GO

-- 6.4 Stored Procedure: Resumo_Pagamentos (Parametrizada)
IF OBJECT_ID('Resumo_Pagamentos', 'P') IS NOT NULL DROP PROCEDURE Resumo_Pagamentos;
GO
CREATE PROCEDURE Resumo_Pagamentos 
    @nome_pac varchar(40)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        pa.nome_paciente,
        SUM(pe.valor_pagar) AS total_pagar
    FROM paciente AS pa
    INNER JOIN consulta AS c ON pa.cpf = c.fk_paciente_cpf
    INNER JOIN pedido_exame AS pe ON c.numero_consulta = pe.fk_consulta_numero_consulta
    WHERE pa.nome_paciente = @nome_pac
    GROUP BY pa.nome_paciente;
END;
GO

-- =================================================================================
-- 7. EXECUÇÃO E TESTES DAS PROCEDURES
-- =================================================================================
EXEC Agenda_Medicos;
EXEC Exames_Solicitados;
EXEC Historico_Pagamentos;
EXEC Resumo_Pagamentos @nome_pac = 'Leonardo Ribeiro';
EXEC Resumo_Pagamentos @nome_pac = 'Maria Pereira';
GO
