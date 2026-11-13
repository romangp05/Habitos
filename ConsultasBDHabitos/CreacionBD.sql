CREATE DATABASE ControlHabitosDB;
GO
USE ControlHabitosDB;
GO

-- 1. Tabla de Hábitos
CREATE TABLE Habitos (
    IdHabito INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    FechaCreacion DATE DEFAULT CAST(GETDATE() AS DATE),
    Activo BIT DEFAULT 1
);
GO

-- 2. Tabla de Registros Diarios (Relación 1 a Muchos)
CREATE TABLE RegistrosDiarios (
    IdRegistro INT IDENTITY(1,1) PRIMARY KEY,
    IdHabito INT NOT NULL,
    Fecha DATE NOT NULL,
    Completado BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Registros_Habitos FOREIGN KEY (IdHabito) 
        REFERENCES Habitos(IdHabito) ON DELETE CASCADE,
    CONSTRAINT UQ_Habito_Fecha UNIQUE (IdHabito, Fecha) -- Evita duplicados el mismo día
);
GO

-- ==========================================================
-- PROCEDIMIENTO 1: Marcar o Desmarcar un Hábito en una Fecha
-- ==========================================================
CREATE PROCEDURE sp_AlternarRegistroHabito
    @IdHabito INT,
    @Fecha DATE,
    @Completado BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM RegistrosDiarios WHERE IdHabito = @IdHabito AND Fecha = @Fecha)
    BEGIN
        UPDATE RegistrosDiarios
        SET Completado = @Completado
        WHERE IdHabito = @IdHabito AND Fecha = @Fecha;
    END
    ELSE
    BEGIN
        INSERT INTO RegistrosDiarios (IdHabito, Fecha, Completado)
        VALUES (@IdHabito, @Fecha, @Completado);
    END
END;
GO

-- ==========================================================
-- PROCEDIMIENTO 2: Obtener la Matriz Semanal (Lunes a Domingo)
-- ==========================================================
CREATE PROCEDURE sp_ObtenerSemanaHabitos
    @FechaInicioLunes DATE -- Pasa la fecha del lunes de la semana a consultar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        h.IdHabito,
        h.Nombre,
        ISNULL(MAX(CASE WHEN r.Fecha = @FechaInicioLunes THEN CAST(r.Completado AS INT) END), 0) AS Lunes,
        ISNULL(MAX(CASE WHEN r.Fecha = DATEADD(DAY, 1, @FechaInicioLunes) THEN CAST(r.Completado AS INT) END), 0) AS Martes,
        ISNULL(MAX(CASE WHEN r.Fecha = DATEADD(DAY, 2, @FechaInicioLunes) THEN CAST(r.Completado AS INT) END), 0) AS Miercoles,
        ISNULL(MAX(CASE WHEN r.Fecha = DATEADD(DAY, 3, @FechaInicioLunes) THEN CAST(r.Completado AS INT) END), 0) AS Jueves,
        ISNULL(MAX(CASE WHEN r.Fecha = DATEADD(DAY, 4, @FechaInicioLunes) THEN CAST(r.Completado AS INT) END), 0) AS Viernes,
        ISNULL(MAX(CASE WHEN r.Fecha = DATEADD(DAY, 5, @FechaInicioLunes) THEN CAST(r.Completado AS INT) END), 0) AS Sabado,
        ISNULL(MAX(CASE WHEN r.Fecha = DATEADD(DAY, 6, @FechaInicioLunes) THEN CAST(r.Completado AS INT) END), 0) AS Domingo
    FROM Habitos h
    LEFT JOIN RegistrosDiarios r 
        ON h.IdHabito = r.IdHabito 
        AND r.Fecha BETWEEN @FechaInicioLunes AND DATEADD(DAY, 6, @FechaInicioLunes)
    WHERE h.Activo = 1
    GROUP BY h.IdHabito, h.Nombre
    ORDER BY h.IdHabito;
END;
GO

-- Datos de prueba iniciales
INSERT INTO Habitos (Nombre) VALUES 
('Programar / Práctica de código'),
('Entrenamiento físico'),
('Lectura técnica (20 min)'),
('Dormir 7-8 horas');
GO