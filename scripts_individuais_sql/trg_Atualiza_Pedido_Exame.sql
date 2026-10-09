-- Gatilho de cálculo automático do valor a pagar da tabela pedido_exame
USE clinica_medica;
GO

IF OBJECT_ID('Atualiza_Pedido_Exame', 'TR') IS NOT NULL
    DROP TRIGGER Atualiza_Pedido_Exame;
GO

CREATE TRIGGER Atualiza_Pedido_Exame
ON pedido_exame
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @num_ped AS int;
    DECLARE @num_cons AS int;
    DECLARE @cod_ex AS int;
    DECLARE @prc AS money;
    DECLARE @cpf_pac AS varchar(20);
    DECLARE @tp_plan AS varchar(20);

    -- Captura dados da linha inserida
    SELECT @num_ped = numero_pedido,
           @num_cons = fk_consulta_numero_consulta,
           @cod_ex = fk_exame_codigo
    FROM inserted;

    -- Busca preço do exame
    SELECT @prc = preco FROM exame WHERE codigo = @cod_ex;

    -- Busca CPF do paciente vinculado à consulta
    SELECT @cpf_pac = fk_paciente_cpf FROM consulta WHERE numero_consulta = @num_cons;

    -- Busca tipo do plano do paciente
    SELECT @tp_plan = tipo_plano FROM paciente WHERE cpf = @cpf_pac;

    -- Aplicação das regras de negócio conforme plano de saúde:
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

    PRINT 'Trigger (Atualiza Pedido de Exame) Encerrada com sucesso.';
END;
GO
