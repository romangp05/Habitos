USE ControlHabitosDB;
GO

-- Limpiar objetos anteriores para recrearlos con soporte de usuarios
IF OBJECT_ID('sp_ObtenerSemanaHabitos', 'P') IS NOT NULL DROP PROCEDURE sp_ObtenerSemanaHabitos;
IF OBJECT_ID('sp_AlternarRegistroHabito', 'P') IS NOT NULL DROP PROCEDURE sp_AlternarRegistroHabito;
IF OBJECT_ID('RegistrosDiarios', 'U') IS NOT NULL DROP TABLE RegistrosDiarios;
IF OBJECT_ID('Habitos', 'U') IS NOT NULL DROP TABLE Habitos;
IF OBJECT_ID('Usuarios', 'U') IS NOT NULL DROP TABLE Usuarios;
GO

-- 1. Tabla de Usuarios
CREATE TABLE Usuarios (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    FechaRegistro DATETIME DEFAULT GETDATE()
);
GO

-- 2. Tabla de Hábitos (Vinculada a cada Usuario)
CREATE TABLE Habitos (
    IdHabito INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    FechaCreacion DATE DEFAULT CAST(GETDATE() AS DATE),
    Activo BIT DEFAULT 1,
    CONSTRAINT FK_Habitos_Usuarios FOREIGN KEY (IdUsuario)
        REFERENCES Usuarios(IdUsuario) ON DELETE CASCADE
);
GO

-- 3. Tabla de Registros Diarios
CREATE TABLE RegistrosDiarios (
    IdRegistro INT IDENTITY(1,1) PRIMARY KEY,
    IdHabito INT NOT NULL,
    Fecha DATE NOT NULL,
    Completado BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Registros_Habitos FOREIGN KEY (IdHabito) 
        REFERENCES Habitos(IdHabito) ON DELETE CASCADE,
    CONSTRAINT UQ_Habito_Fecha UNIQUE (IdHabito, Fecha)
);
GO

-- ==========================================================
-- PROCEDIMIENTO 1: Marcar o Desmarcar un Hábito
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
-- PROCEDIMIENTO 2: Obtener Semana Filtrada por Usuario
-- ==========================================================
CREATE PROCEDURE sp_ObtenerSemanaHabitos
    @IdUsuario INT,
    @FechaInicioLunes DATE
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
    WHERE h.Activo = 1 AND h.IdUsuario = @IdUsuario
    GROUP BY h.IdHabito, h.Nombre
    ORDER BY h.IdHabito;
END;
GO