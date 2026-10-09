# Atividade 3 - Automatização de Tarefas (Triggers e Stored Procedures)
**Unidade Curricular:** UC13 - Banco de Dados  
**Turma/Código:** CTMSP_DPE_QO_FULLST_252T01_BDADO_QUA.568.004  
**Estudante:** João Emanuel Almeida Ramos  
**Projeto:** Banco de Dados da Clínica Médica (clinica_medica)  

---

## 1. Introdução e Contextualização do Projeto

Na etapa anterior do projeto da **Clínica Médica**, foram construídos o modelo lógico (DER), a estrutura física de dados (DDL) e as operações de manipulação (DML). Nesta **Atividade 3**, o foco é a **automatização de processos de negócio** diretamente na camada do Sistema Gerenciador de Banco de Dados (SGBD - Microsoft SQL Server).

A automação no banco de dados traz ganhos significativos em:
* **Integridade e Consistência:** Regras de negócio críticas (como descontos de convênio) são executadas independentemente da aplicação cliente.
* **Desempenho e Latência:** A lógica é pré-compilada e processada próxima aos dados, reduzindo o tráfego de rede e o número de idas e voltas (*round-trips*).
* **Segurança e Padronização:** O acesso às tabelas pode ser encapsulado através de rotinas homologadas.

A atividade divide-se em dois eixos fundamentais:
1. **Gatilhos (Triggers):** Automação orientada a eventos para cálculo automático do valor a pagar dos pedidos de exames com base no plano de saúde do paciente.
2. **Procedimentos Armazenados (Stored Procedures):** Rotinas pré-compiladas reutilizáveis para geração de relatórios operacionais, rastreabilidade de consultas/exames e consolidação financeira por paciente.

---

## 2. Automação 1: Gatilho (Trigger) de Cálculo de Valor a Pagar

### 2.1 Regra de Negócio e Dinâmica do Gatilho
Na tabela pedido_exame, o campo alor_pagar armazena o valor líquido que o paciente deve desembolsar após a aplicação dos descontos contratuais do seu convênio médico.

As regras de cobertura definidas pela clínica são:
* **Plano Especial:** Cobertura de **100%** (desconto integral: alor_pagar = 0.00).
* **Plano Padrão:** Cobertura de **30%** (paciente arca com 70% do preço de tabela).
* **Plano Básico:** Cobertura de **10%** (paciente arca com 90% do preço de tabela).

### 2.2 Funcionamento da Pseudo-Tabela INSERTED
No SQL Server, ao disparar uma trigger do tipo AFTER INSERT, o SGBD disponibiliza uma tabela temporária de memória chamada INSERTED. Essa tabela contém uma cópia exata das tuplas recém-inseridas, permitindo que a trigger recupere a chave primária (
umero_pedido), a chave estrangeira da consulta (k_consulta_numero_consulta) e o código do exame (k_exame_codigo).

### 2.3 Roteiro de Execução e Reset do IDENTITY
Como as tuplas iniciais de teste foram inseridas antes da criação da trigger com valor zero, o roteiro técnico requer:
1. Limpar a tabela pedido_exame: DELETE FROM pedido_exame;
2. Reiniciar o contador incremental para que o próximo pedido inicie em 2200: DBCC CHECKIDENT('pedido_exame', RESEED, 2199);
3. Criar a trigger Atualiza_Pedido_Exame.
4. Reinserir os 9 registros na tabela pedido_exame.
5. Constatar o recálculo automático em alor_pagar.

### 2.4 Código SQL Oficial da Trigger (	rg_Atualiza_Pedido_Exame.sql)

`sql
USE clinica_medica;
GO

-- Exclusão de versão anterior para garantir idempotência
IF OBJECT_ID('Atualiza_Pedido_Exame', 'TR') IS NOT NULL
    DROP TRIGGER Atualiza_Pedido_Exame;
GO

CREATE TRIGGER Atualiza_Pedido_Exame
ON pedido_exame
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Declaração de variáveis locais
    DECLARE @num_ped AS int;
    DECLARE @num_cons AS int;
    DECLARE @cod_ex AS int;
    DECLARE @prc AS money;
    DECLARE @cpf_pac AS varchar(20);
    DECLARE @tp_plan AS varchar(20);

    -- 2. Captura dos dados inseridos a partir da pseudo-tabela INSERTED
    SELECT @num_ped = numero_pedido,
           @num_cons = fk_consulta_numero_consulta,
           @cod_ex = fk_exame_codigo
    FROM inserted;

    -- 3. Consulta ao preço base do exame na tabela exame
    SELECT @prc = preco 
    FROM exame 
    WHERE codigo = @cod_ex;

    -- 4. Busca do CPF do paciente vinculado à consulta
    SELECT @cpf_pac = fk_paciente_cpf 
    FROM consulta 
    WHERE numero_consulta = @num_cons;

    -- 5. Recuperação do tipo de plano de saúde do paciente
    SELECT @tp_plan = tipo_plano 
    FROM paciente 
    WHERE cpf = @cpf_pac;

    -- 6. Estrutura condicional para aplicação do desconto
    -- Plano Especial: 100% de desconto
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

    PRINT 'Trigger (Atualiza Pedido de Exame) executada com sucesso para o Pedido: ' + CAST(@num_ped AS varchar(10));
END;
GO
`

### 2.5 Resultado e Validação dos Cálculos da Trigger

Após a reinserção dos dados com INSERT, a consulta SELECT * FROM pedido_exame; apresenta os valores calculados com precisão matemática:

| Número Pedido | Resultado | Data Exame | Valor a Pagar (R$) | Nº Consulta | Cód. Exame | Paciente Vinculado | Tipo Plano | Preço Base (R$) | % Desconto |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **2200** | Normal | 2022-12-15 | **385.00** | 22000 | 10040 | Leonardo Ribeiro | Padrão | 550.00 | 30% |
| **2201** | *(Em branco)* | 2022-12-19 | **35.00** | 22000 | 10100 | Leonardo Ribeiro | Padrão | 50.00 | 30% |
| **2202** | *(Em branco)* | 2022-12-16 | **270.00** | 22001 | 10080 | Bruna Alvez | Básico | 300.00 | 10% |
| **2203** | Normal | 2022-12-15 | **720.00** | 22002 | 10050 | Bruna Alvez | Básico | 800.00 | 10% |
| **2204** | Inconsistente | 2022-12-16 | **0.00** | 22003 | 10080 | Gilberto Barros | Especial | 300.00 | 100% |
| **2205** | *(Em branco)* | 2022-12-17 | **49.00** | 22004 | 10060 | Maria Pereira | Padrão | 70.00 | 30% |
| **2206** | Normal | 2022-12-21 | **70.00** | 22007 | 10020 | Maria Pereira | Padrão | 100.00 | 30% |
| **2207** | *(Em branco)* | 2022-12-22 | **175.00** | 22008 | 10030 | Leonardo Ribeiro | Padrão | 250.00 | 30% |
| **2208** | *(Em branco)* | 2022-12-22 | **560.00** | 22008 | 10050 | Leonardo Ribeiro | Padrão | 800.00 | 30% |

---

## 3. Automação 2: Procedimentos Armazenados (Stored Procedures)

As *Stored Procedures* encapsulam consultas complexas envolvendo junções relacionais (INNER JOIN), ordenações específicas (ORDER BY), filtros e agregações (SUM, GROUP BY).

---

### 3.1 Procedimento 1: Agenda_Medicos

* **Objetivo:** Relacionar a agenda de atendimentos dos médicos, identificando data, horário e os dados cadastrais do paciente (incluindo convênio).
* **Tabelas Relacionadas:**
  * medico (m) — Chave primária: crm
  * consulta (c) — Chaves estrangeiras: k_medico_crm e k_paciente_cpf
  * paciente (p) — Chave primária: cpf
* **Critério de Ordenação:** Ordem alfabética pelo nome do médico e por data da consulta (ORDER BY m.nome_medico, c.data_consulta).

#### Código SQL (sp_Agenda_Medicos.sql):
`sql
USE clinica_medica;
GO

IF OBJECT_ID('Agenda_Medicos', 'P') IS NOT NULL 
    DROP PROCEDURE Agenda_Medicos;
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

-- Invocação da Procedure
EXEC Agenda_Medicos;
GO
`

#### Resultado Obtido da Execução:
| Nome Médico | Especialidade | CRM | Nº Consulta | Data Consulta | Horário | Nome Paciente | CPF Paciente | Convênio | Plano |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :---: | :--- | :--- |
| Agildo Nunes | Cardiologia | 102030 | 22000 | 2022-12-12 | 14:30 | Leonardo Ribeiro | 012.345.678-90 | Inovamed | Padrão |
| Agildo Nunes | Cardiologia | 102030 | 22006 | 2022-12-19 | 16:45 | Gilberto Barros | 234.567.890-23 | Inovamed | Especial |
| Agildo Nunes | Cardiologia | 102030 | 22009 | 2022-12-20 | 14:20 | Bruna Alvez | 123.456.789-12 | Ultramed | Básico |
| Edna Cardoso | Ortopedia | 405060 | 22004 | 2022-12-15 | 15:00 | Maria Pereira | 345.678.901-45 | Ultramed | Padrão |
| Lúcia Marques | Pediatria | 607080 | 22007 | 2022-12-19 | 18:00 | Maria Pereira | 345.678.901-45 | Ultramed | Padrão |
| Márcia Alvez | Gastrologia | 203040 | 22001 | 2022-12-13 | 08:30 | Bruna Alvez | 123.456.789-12 | Ultramed | Básico |
| Márcia Alvez | Gastrologia | 203040 | 22003 | 2022-12-14 | 10:00 | Gilberto Barros | 234.567.890-23 | Inovamed | Especial |
| Ricardo Souza | Otorrinolaringologia | 506070 | 22005 | 2022-12-16 | 10:00 | Bruna Alvez | 123.456.789-12 | Ultramed | Básico |
| Roberto Gusmão | Neurologia | 304050 | 22002 | 2022-12-13 | 11:00 | Bruna Alvez | 123.456.789-12 | Ultramed | Básico |
| Roberto Gusmão | Neurologia | 304050 | 22008 | 2022-12-20 | 09:00 | Leonardo Ribeiro | 012.345.678-90 | Inovamed | Padrão |

---

### 3.2 Procedimento 2: Exames_Solicitados

* **Objetivo:** Rastrear todos os exames médicos solicitados em consultas, agrupados e ordenados por médico prescritor e data de realização.
* **Tabelas Relacionadas:**
  * medico (m)
  * consulta (c)
  * pedido_exame (p)
  * exame (e)
* **Critério de Ordenação:** Nome do médico e data do exame (ORDER BY m.nome_medico, p.data_exame).

#### Código SQL (sp_Exames_Solicitados.sql):
`sql
USE clinica_medica;
GO

IF OBJECT_ID('Exames_Solicitados', 'P') IS NOT NULL 
    DROP PROCEDURE Exames_Solicitados;
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

-- Invocação da Procedure
EXEC Exames_Solicitados;
GO
`

#### Resultado Obtido da Execução:
| Nome Médico | Especialidade | CRM | Nº Consulta | Nº Pedido | Data Exame | Cód. Exame | Especificação Exame |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| Agildo Nunes | Cardiologia | 102030 | 22000 | 2200 | 2022-12-15 | 10040 | Ultrassonografia |
| Agildo Nunes | Cardiologia | 102030 | 22000 | 2201 | 2022-12-19 | 10100 | Eletrocardiograma |
| Edna Cardoso | Ortopedia | 405060 | 22004 | 2205 | 2022-12-17 | 10060 | Radiografia |
| Lúcia Marques | Pediatria | 607080 | 22007 | 2206 | 2022-12-21 | 10020 | Hemograma |
| Márcia Alvez | Gastrologia | 203040 | 22001 | 2202 | 2022-12-16 | 10080 | Endoscopia |
| Márcia Alvez | Gastrologia | 203040 | 22003 | 2204 | 2022-12-16 | 10080 | Endoscopia |
| Roberto Gusmão | Neurologia | 304050 | 22002 | 2203 | 2022-12-15 | 10050 | Ressonância |
| Roberto Gusmão | Neurologia | 304050 | 22008 | 2207 | 2022-12-22 | 10030 | Tomografia |
| Roberto Gusmão | Neurologia | 304050 | 22008 | 2208 | 2022-12-22 | 10050 | Ressonância |

---

### 3.3 Procedimento 3: Historico_Pagamentos

* **Objetivo:** Relatório financeiro individualizado que exibe o histórico de consultas, exames solicitados e o valor líquido pago por cada paciente.
* **Tabelas Relacionadas:**
  * paciente (pa)
  * consulta (c)
  * pedido_exame (pe)
  * exame (e)
* **Critério de Ordenação:** Nome do paciente e data de realização do exame (ORDER BY pa.nome_paciente, pe.data_exame).

#### Código SQL (sp_Historico_Pagamentos.sql):
`sql
USE clinica_medica;
GO

IF OBJECT_ID('Historico_Pagamentos', 'P') IS NOT NULL 
    DROP PROCEDURE Historico_Pagamentos;
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

-- Invocação da Procedure
EXEC Historico_Pagamentos;
GO
`

#### Resultado Obtido da Execução:
| Nome Paciente | CPF | Nº Consulta | Data Consulta | Data Exame | Valor a Pagar (R$) | Cód. Exame | Especificação |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| Bruna Alvez | 123.456.789-12 | 22002 | 2022-12-13 | 2022-12-15 | **720.00** | 10050 | Ressonância |
| Bruna Alvez | 123.456.789-12 | 22001 | 2022-12-13 | 2022-12-16 | **270.00** | 10080 | Endoscopia |
| Gilberto Barros | 234.567.890-23 | 22003 | 2022-12-14 | 2022-12-16 | **0.00** | 10080 | Endoscopia |
| Leonardo Ribeiro | 012.345.678-90 | 22000 | 2022-12-12 | 2022-12-15 | **385.00** | 10040 | Ultrassonografia |
| Leonardo Ribeiro | 012.345.678-90 | 22000 | 2022-12-12 | 2022-12-19 | **35.00** | 10100 | Eletrocardiograma |
| Leonardo Ribeiro | 012.345.678-90 | 22008 | 2022-12-20 | 2022-12-22 | **175.00** | 10030 | Tomografia |
| Leonardo Ribeiro | 012.345.678-90 | 22008 | 2022-12-20 | 2022-12-22 | **560.00** | 10050 | Ressonância |
| Maria Pereira | 345.678.901-45 | 22004 | 2022-12-15 | 2022-12-17 | **49.00** | 10060 | Radiografia |
| Maria Pereira | 345.678.901-45 | 22007 | 2022-12-19 | 2022-12-21 | **70.00** | 10020 | Hemograma |

---

### 3.4 Procedimento 4: Resumo_Pagamentos (Parametrizada)

* **Objetivo:** Calcular o valor financeiro total gasto em exames por um paciente específico, utilizando passagem dinâmica de parâmetros e função agregadora SUM().
* **Parâmetro de Entrada:** @nome_pac varchar(40) — Recebe o nome exato do paciente a ser filtrado.
* **Agrupamento:** GROUP BY pa.nome_paciente.

#### Código SQL (sp_Resumo_Pagamentos.sql):
`sql
USE clinica_medica;
GO

IF OBJECT_ID('Resumo_Pagamentos', 'P') IS NOT NULL 
    DROP PROCEDURE Resumo_Pagamentos;
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
`

#### Testes Práticos e Resultados:

##### Teste 1: Paciente Leonardo Ribeiro
`sql
EXEC Resumo_Pagamentos @nome_pac = 'Leonardo Ribeiro';
`
* **Composição do Cálculo:**
  * Ultrassonografia: R$ 385.00
  * Eletrocardiograma: R$ 35.00
  * Tomografia: R$ 175.00
  * Ressonância: R$ 560.00
  * **Soma Total:** 385 + 35 + 175 + 560 = **R$ 1.155,00**

| Nome Paciente | Total a Pagar (R$) |
| :--- | :---: |
| Leonardo Ribeiro | **1155.00** |

##### Teste 2: Paciente Maria Pereira
`sql
EXEC Resumo_Pagamentos @nome_pac = 'Maria Pereira';
`
* **Composição do Cálculo:**
  * Radiografia: R$ 49.00
  * Hemograma: R$ 70.00
  * **Soma Total:** 49 + 70 = **R$ 119,00**

| Nome Paciente | Total a Pagar (R$) |
| :--- | :---: |
| Maria Pereira | **119.00** |

---

## 4. Análise Conceitual e Engenharia de Banco de Dados

### 4.1 Matriz Comparativa de Recursos de Automação

| Recurso | Tipo de Disparo | Recebe Parâmetros? | Retorna Dados? | Cenário Típico de Aplicação |
| :--- | :--- | :---: | :---: | :--- |
| **Trigger (Gatilho)** | Automático (Evento DML: INSERT, UPDATE, DELETE) | Não | Não diretamente (atualiza estado) | Integridade de dados, auditoria, log e recálculos automáticos em cascata. |
| **Stored Procedure** | Manual ou Programado (EXEC nome) | Sim (Entrada e Saída) | Sim (Conjuntos de resultados ou código de retorno) | Rotinas de negócio complexas, relatórios pesados e operações em lote. |
| **View (Visão)** | Consultada como tabela virtual (SELECT * FROM view) | Não | Sim (Conjunto tabular) | Abstração de complexidade de junções e segurança de acesso a colunas. |
| **Function (UDF)** | Invocada em expressões (SELECT dbo.fn(...)) | Sim | Sim (Escalar ou Tabela) | Cálculos determinísticos, formatações e funções utilitárias. |

---

### 4.2 Análise Crítica de Performance: Abordagem Escalar vs. Set-Based no Trigger

No script didático fornecido pelo SENAI, a trigger utiliza variáveis escalares (DECLARE @num_ped int; SELECT @num_ped = numero_pedido FROM inserted).  
> [!IMPORTANT]
> **Limitação da Abordagem Escalar:** No Microsoft SQL Server, se uma aplicação executar uma inserção em lote com múltiplas linhas (ex.: INSERT INTO pedido_exame VALUES (...), (...);), a atribuição SELECT @num_ped = numero_pedido FROM inserted capturará **apenas o último registro** da pseudo-tabela INSERTED, deixando os demais sem atualização correta do valor!

#### Proposta de Engenharia Sênior (Abordagem Set-Based / Baseada em Conjuntos):
Para garantir robustez em ambiente de produção de alto volume, a trigger deve ser escrita com uma única operação UPDATE relacional baseada em conjuntos:

`sql
CREATE TRIGGER Atualiza_Pedido_Exame_SetBased
ON pedido_exame
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE pe
    SET pe.valor_pagar = e.preco - (e.preco * CASE 
                                                WHEN pac.tipo_plano = 'Especial' THEN 1.00 
                                                WHEN pac.tipo_plano = 'Padrão'   THEN 0.30 
                                                WHEN pac.tipo_plano = 'Básico'   THEN 0.10 
                                                ELSE 0.00 
                                              END)
    FROM pedido_exame pe
    INNER JOIN inserted ins ON pe.numero_pedido = ins.numero_pedido
    INNER JOIN exame e ON ins.fk_exame_codigo = e.codigo
    INNER JOIN consulta c ON ins.fk_consulta_numero_consulta = c.numero_consulta
    INNER JOIN paciente pac ON c.fk_paciente_cpf = pac.cpf;
END;
GO
`
* **Vantagens da Abordagem Set-Based:**
  1. Processa de 1 a 100.000 registros simultâneos no mesmo comando INSERT sem falhas.
  2. Executa em um único plano de acesso do otimizador de consultas (*query optimizer*).
  3. Reduz *locks* e tempo de travamento de transação.

---

## 5. Estrutura dos Arquivos Entregues

A resolução completa da atividade está estruturada nos seguintes arquivos anexos no diretório da atividade:

1. clinica_medica_automatizacao_completo.sql: Script unificado contendo DDL, DML, Trigger, reset do identity, inserções e as 4 Stored Procedures com testes.
2. scripts_individuais_sql/: Pasta contendo cada script individualmente com codificação UTF-8 rigorosamente corrigida:
   * 	rg_Atualiza_Pedido_Exame.sql
   * sp_Agenda_Medicos.sql
   * sp_Exames_Solicitados.sql
   * sp_Historico_Pagamentos.sql
   * sp_Resumo_Pagamentos.sql
3. Atividade3_Resolucao_ClinicaMedica.docx: Relatório executivo completo em formato Microsoft Word.
4. Atividade3_Envio_Automatizacao.zip: Pacote compactado contendo todos os scripts e a documentação técnica para upload no AVA/Portal SENAI.

---

## 6. Conclusão

A implementação das estruturas de automação nesta **Atividade 3** consolidou a camada de persistência da Clínica Médica como uma solução autônoma, resiliente e segura. O gatilho DML garante a aplicação infalível dos contratos de planos de saúde, enquanto as stored procedures disponibilizam uma interface analítica ágil e padronizada para os usuários do sistema hospitalar.
