USE ControlHabitosDB;
GO

-- 1. Crear tabla de Amistades (sin borrar tus usuarios actuales)
IF OBJECT_ID('Amistades', 'U') IS NULL
BEGIN
    CREATE TABLE Amistades (
        IdAmistad INT IDENTITY(1,1) PRIMARY KEY,
        IdSolicitante INT NOT NULL,
        IdReceptor INT NOT NULL,
        Estado NVARCHAR(20) NOT NULL DEFAULT 'Pendiente', -- 'Pendiente', 'Aceptada'
        FechaSolicitud DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Amistad_Solicitante FOREIGN KEY (IdSolicitante) REFERENCES Usuarios(IdUsuario),
        CONSTRAINT FK_Amistad_Receptor FOREIGN KEY (IdReceptor) REFERENCES Usuarios(IdUsuario),
        CONSTRAINT UQ_Amistad_Par UNIQUE (IdSolicitante, IdReceptor)
    );
END
GO

-- 2. Procedimiento para obtener el historial acumulado por hábito de un usuario
IF OBJECT_ID('sp_ObtenerHistorialUsuario', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObtenerHistorialUsuario;
GO

CREATE PROCEDURE sp_ObtenerHistorialUsuario
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        h.IdHabito,
        h.Nombre,
        CONVERT(VARCHAR(10), h.FechaCreacion, 23) AS FechaCreacion,
        COUNT(CASE WHEN r.Completado = 1 THEN 1 END) AS TotalCompletados,
        ISNULL(CONVERT(VARCHAR(10), MAX(CASE WHEN r.Completado = 1 THEN r.Fecha END), 23), 'Sin registros') AS UltimaFecha
    FROM Habitos h
    LEFT JOIN RegistrosDiarios r ON h.IdHabito = r.IdHabito
    WHERE h.IdUsuario = @IdUsuario AND h.Activo = 1
    GROUP BY h.IdHabito, h.Nombre, h.FechaCreacion
    ORDER BY TotalCompletados DESC, h.IdHabito ASC;
END;
GO