-- Stored Procedure: Resumo de Pagamentos por Paciente (Parametrizada)
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

-- Exemplos de Execução
EXEC Resumo_Pagamentos @nome_pac = 'Leonardo Ribeiro';
EXEC Resumo_Pagamentos @nome_pac = 'Maria Pereira';
GO
