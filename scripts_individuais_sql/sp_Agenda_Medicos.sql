-- Stored Procedure: Agenda de Médicos
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

-- Execução para teste
EXEC Agenda_Medicos;
GO
