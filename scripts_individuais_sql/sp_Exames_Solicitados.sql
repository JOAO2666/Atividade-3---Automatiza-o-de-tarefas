-- Stored Procedure: Exames Solicitados em Ordem de Médico
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

-- Execução para teste
EXEC Exames_Solicitados;
GO
