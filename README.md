# Atividade 3 - Automatização de Tarefas no Banco de Dados 🏥⚡

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![SENAI](https://img.shields.io/badge/SENAI-UC13%20Banco%20de%20Dados-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Conclu%C3%ADdo-brightgreen?style=for-the-badge)

Repositório com a resolução completa, scripts SQL e relatório técnico da **Atividade 3 - Automatização de Tarefas** da Unidade Curricular de Banco de Dados (**UC13**).

* **Instituição:** SENAI
* **Turma/Código:** `CTMSP_DPE_QO_FULLST_252T01_BDADO_QUA.568.004`
* **Estudante:** João Emanuel Almeida Ramos
* **Projeto:** Banco de Dados da Clínica Médica (`clinica_medica`)
* **Vídeo-aula de Referência (SENAI Play):** [Automatização de banco de dados - YouTube](https://www.youtube.com/watch?v=APlSUpEFPak)

---

## 🎯 Objetivos da Atividade

1. **Gatilhos (Triggers):** Automatizar o cálculo da coluna `valor_pagar` na tabela `pedido_exame` a partir do tipo de plano de saúde do paciente vinculado à consulta (`AFTER INSERT`).
2. **Procedimentos Armazenados (Stored Procedures):** Criar e parametrizar rotinas de extração de relatórios clínicos e financeiros com múltiplos `INNER JOIN`, ordenações e agregações.

---

## 🏗️ Estrutura do Repositório

```text
├── clinica_medica_automatizacao_completo.sql  # Script SQL completo e unificado (DDL + DML + Triggers + Procedures)
├── Atividade3_Resolucao_ClinicaMedica.md     # Relatório técnico completo em Markdown
├── Atividade3_Resolucao_ClinicaMedica.docx   # Relatório técnico formatado em Word (.docx)
├── Atividade3_Envio_Automatizacao.zip        # Pacote compactado de entrega acadêmica
├── BancoDados_Ativ_Automatizacao.pdf         # Apostila e roteiro oficial da atividade
├── youtube_transcript.txt                    # Transcrição da aula de referência do SENAI Play
└── scripts_individuais_sql/                  # Scripts SQL individuais (UTF-8)
    ├── trg_Atualiza_Pedido_Exame.sql
    ├── sp_Agenda_Medicos.sql
    ├── sp_Exames_Solicitados.sql
    ├── sp_Historico_Pagamentos.sql
    └── sp_Resumo_Pagamentos.sql
```

---

## ⚡ 1. Gatilho (Trigger): `Atualiza_Pedido_Exame`

O gatilho atua sobre o evento `AFTER INSERT` na tabela `pedido_exame`. Ele intercepta os dados da pseudo-tabela `INSERTED`, recupera o preço de tabela do exame e o convênio do paciente, aplicando os seguintes descontos:

* **Plano Especial:** 100% de desconto $\rightarrow$ `valor_pagar = R$ 0,00`
* **Plano Padrão:** 30% de desconto $\rightarrow$ `valor_pagar = preco * 0.70`
* **Plano Básico:** 10% de desconto $\rightarrow$ `valor_pagar = preco * 0.90`

### Roteiro de Execução:
```sql
DELETE FROM pedido_exame;
DBCC CHECKIDENT('pedido_exame', RESEED, 2199);
-- Inserir os 9 registros para disparo automático do gatilho
```

### 📊 Resultados Calculados na Tabela `pedido_exame`:
| Nº Pedido | Resultado | Data Exame | Valor a Pagar (R$) | Nº Consulta | Cód. Exame | Paciente | Plano | Preço Base | Desconto |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **2200** | Normal | 2022-12-15 | **R$ 385,00** | 22000 | 10040 | Leonardo Ribeiro | Padrão | R$ 550,00 | 30% |
| **2201** | *(vazio)* | 2022-12-19 | **R$ 35,00** | 22000 | 10100 | Leonardo Ribeiro | Padrão | R$ 50,00 | 30% |
| **2202** | *(vazio)* | 2022-12-16 | **R$ 270,00** | 22001 | 10080 | Bruna Alvez | Básico | R$ 300,00 | 10% |
| **2203** | Normal | 2022-12-15 | **R$ 720,00** | 22002 | 10050 | Bruna Alvez | Básico | R$ 800,00 | 10% |
| **2204** | Inconsistente | 2022-12-16 | **R$ 0,00** | 22003 | 10080 | Gilberto Barros | Especial | R$ 300,00 | 100% |
| **2205** | *(vazio)* | 2022-12-17 | **R$ 49,00** | 22004 | 10060 | Maria Pereira | Padrão | R$ 70,00 | 30% |
| **2206** | Normal | 2022-12-21 | **R$ 70,00** | 22007 | 10020 | Maria Pereira | Padrão | R$ 100,00 | 30% |
| **2207** | *(vazio)* | 2022-12-22 | **R$ 175,00** | 22008 | 10030 | Leonardo Ribeiro | Padrão | R$ 250,00 | 30% |
| **2208** | *(vazio)* | 2022-12-22 | **R$ 560,00** | 22008 | 10050 | Leonardo Ribeiro | Padrão | R$ 800,00 | 30% |

---

## 🛠️ 2. Procedimentos Armazenados (Stored Procedures)

### 2.1 `Agenda_Medicos`
* **Descrição:** Relaciona a agenda de atendimentos dos médicos com data, horário e dados cadastrais do paciente.
* **Junções:** `medico` $\bowtie$ `consulta` $\bowtie$ `paciente`.
* **Ordenação:** `ORDER BY m.nome_medico, c.data_consulta`.
* **Execução:**
  ```sql
  EXEC Agenda_Medicos;
  ```

### 2.2 `Exames_Solicitados`
* **Descrição:** Rastreia os exames solicitados por cada profissional médico.
* **Junções:** `medico` $\bowtie$ `consulta` $\bowtie$ `pedido_exame` $\bowtie$ `exame`.
* **Ordenação:** `ORDER BY m.nome_medico, p.data_exame`.
* **Execução:**
  ```sql
  EXEC Exames_Solicitados;
  ```

### 2.3 `Historico_Pagamentos`
* **Descrição:** Extrato detalhado de exames e valor líquido a pagar por paciente.
* **Junções:** `paciente` $\bowtie$ `consulta` $\bowtie$ `pedido_exame` $\bowtie$ `exame`.
* **Ordenação:** `ORDER BY pa.nome_paciente, pe.data_exame`.
* **Execução:**
  ```sql
  EXEC Historico_Pagamentos;
  ```

### 2.4 `Resumo_Pagamentos` (Parametrizada)
* **Descrição:** Agregação financeira por paciente utilizando parâmetro `@nome_pac varchar(40)`.
* **Execução & Resultados Testados:**
  ```sql
  EXEC Resumo_Pagamentos @nome_pac = 'Leonardo Ribeiro';
  -- Total a Pagar: R$ 1.155,00 (385 + 35 + 175 + 560)

  EXEC Resumo_Pagamentos @nome_pac = 'Maria Pereira';
  -- Total a Pagar: R$ 119,00 (49 + 70)
  ```

---

## 🚀 Diferencial de Engenharia: Abordagem *Set-Based* (Baseada em Conjuntos)

Para ambientes de produção corporativos que realizam inserções em lote (multi-row inserts), foi implementada a trigger relacional baseada em conjuntos:

```sql
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
```

---

## 👨‍💻 Autor
* **João Emanuel Almeida Ramos** ([GitHub: @JOAO2666](https://github.com/JOAO2666))
