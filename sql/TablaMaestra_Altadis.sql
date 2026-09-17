-- ================================================================
-- TFM Altadis / Imperial Brands
-- TABLA MAESTRA: TablasMaestra_Altadis
-- Grano: Fecha + Affiliated_Code + Product_Code
--
-- Tablas internas necesarias (importar con asistente SSMS):
--   SalesDay, DeliveryDay, OoSDay, RouteDay,
--   AffiliatedOutlets, Product
--
-- Tablas externas necesarias (ya creadas o por crear):
--   CodPostalesProvincias  → CPRO + PROVINCIA
--   Calendario             → ver PASO 1 al final de este script
--   RentaProvincial        → CPRO + Renta_Media_Hogar (del INE)
-- ================================================================


-- ================================================================
-- PASO 1: CREAR TABLA CALENDARIO (fuente externa)
-- Cubre todo el rango de fechas de los datos (2015)
-- Añade variables temporales útiles para el análisis
-- ================================================================

CREATE TABLE Calendario (
    Fecha        DATE        PRIMARY KEY,
    Anio         INT,
    Mes          INT,
    Trimestre    INT,
    Semana       INT,
    DiaSemana    INT,        -- 1=Lunes … 7=Domingo
    NombreDia    VARCHAR(20),
    EsFinSemana  BIT,        -- 1 si sábado o domingo
    EsFestivo    BIT,        -- 1 si festivo nacional/autonómico
    EsLaborable  BIT         -- 1 si laborable (no festivo y no finde)
);

-- Poblar el calendario para el año 2015
-- (ajusta el rango si tus datos cubren más fechas)
DECLARE @fecha DATE = '2015-01-01';
WHILE @fecha <= '2015-12-31'
BEGIN
    INSERT INTO Calendario VALUES (
        @fecha,
        YEAR(@fecha),
        MONTH(@fecha),
        DATEPART(QUARTER, @fecha),
        DATEPART(WEEK, @fecha),
        DATEPART(WEEKDAY, @fecha),
        DATENAME(WEEKDAY, @fecha),
        CASE WHEN DATEPART(WEEKDAY, @fecha) IN (1,7) THEN 1 ELSE 0 END,
        0,   -- rellenar luego con festivos reales
        CASE WHEN DATEPART(WEEKDAY, @fecha) IN (1,7) THEN 0 ELSE 1 END
    );
    SET @fecha = DATEADD(DAY, 1, @fecha);
END;

-- Marcar festivos nacionales 2015 (ampliar con autonómicos si se quiere)
UPDATE Calendario SET EsFestivo = 1, EsLaborable = 0
WHERE Fecha IN (
    '2015-01-01', '2015-01-06', '2015-04-02', '2015-04-03',
    '2015-05-01', '2015-08-15', '2015-10-12', '2015-11-01',
    '2015-11-02', '2015-12-07', '2015-12-08', '2015-12-25'
);


-- ================================================================
-- PASO 2: AÑADIR COLUMNA CPRO A AffiliatedOutlets (si no está)
-- ================================================================

ALTER TABLE AffiliatedOutlets ADD CPRO CHAR(2);

UPDATE AffiliatedOutlets
SET CPRO = LEFT(RIGHT('00000' + CAST(POSTALCODE AS VARCHAR(10)), 5), 2);


-- ================================================================
-- PASO 3: CREAR TABLA MAESTRA
-- ================================================================

CREATE TABLE TablaMaestra_Altadis (

    -- ── CLAVE ────────────────────────────────────────────────────
    Fecha               DATE,
    Affiliated_Code     VARCHAR(20),
    Product_Code        VARCHAR(20),

    -- ── DIMENSIÓN TIENDA (AffiliatedOutlets) ─────────────────────
    Affiliated_NAME     VARCHAR(100),
    POSTALCODE          VARCHAR(10),
    CPRO                CHAR(2),
    PROVINCIA           VARCHAR(60),
    Engage              INT,
    Management_Cluster  INT,
    Location            VARCHAR(30),
    Tam_m2              VARCHAR(20),

    -- ── DIMENSIÓN PRODUCTO (Product) ─────────────────────────────
    SIZE                VARCHAR(20),
    Format              VARCHAR(10),

    -- ── VENTAS (SalesDay) ─────────────────────────────────────────
    Sales_Uds           FLOAT,

    -- ── ENTREGAS (DeliveryDay) ────────────────────────────────────
    Delivery_Uds        FLOAT,

    -- ── ROTURA DE STOCK (OoSDay) ──────────────────────────────────
    -- 1 = hubo rotura declarada ese día para ese estanco-producto
    -- 0 = no hubo rotura declarada
    Flag_OoS            BIT,

    -- ── RUTA (RouteDay) ───────────────────────────────────────────
    -- 1 = ese día estaba programada una entrega por ruta
    -- 0 = no había ruta programada
    Flag_Ruta           BIT,

    -- ── CALENDARIO ────────────────────────────────────────────────
    DiaSemana           INT,
    NombreDia           VARCHAR(20),
    Semana              INT,
    Mes                 INT,
    Trimestre           INT,
    EsFinSemana         BIT,
    EsFestivo           BIT,
    EsLaborable         BIT,

    -- ── DATOS EXTERNOS INE (RentaProvincial) ─────────────────────
    -- Importar desde INE: Atlas de Distribución de Renta de Hogares
    Renta_Media_Hogar   FLOAT   -- renta media anual del hogar por provincia
);


-- ================================================================
-- PASO 4: POBLAR LA TABLA MAESTRA
-- Base: SalesDay (combinación más completa de fecha+tienda+producto)
-- Se añaden el resto de tablas con LEFT JOIN
-- ================================================================

INSERT INTO TablaMaestra_Altadis

SELECT

    -- Clave
    CONVERT(DATE, CAST(s.Sales_DAY AS VARCHAR), 112)    AS Fecha,
    s.Affiliated_Code,
    s.Product_Code,

    -- Tienda
    a.Affiliated_NAME,
    a.POSTALCODE,
    a.CPRO,
    p2.PROVINCIA,
    a.Engage,
    a.Management_Cluster,
    a.Location,
    a.Tam_m2,

    -- Producto
    pr.SIZE,
    pr.Format,

    -- Ventas
    s.Sales_Uds,

    -- Entregas (suma por si hay varias entregas el mismo día)
    ISNULL(d.Total_Delivery_Uds, 0)                     AS Delivery_Uds,

    -- Flag OoS
    CASE WHEN o.Affiliated_Code IS NOT NULL THEN 1
         ELSE 0 END                                     AS Flag_OoS,

    -- Flag Ruta
    CASE WHEN r.Affiliated_Code IS NOT NULL THEN 1
         ELSE 0 END                                     AS Flag_Ruta,

    -- Calendario
    c.DiaSemana,
    c.NombreDia,
    c.Semana,
    c.Mes,
    c.Trimestre,
    c.EsFinSemana,
    c.EsFestivo,
    c.EsLaborable,

    -- INE Renta
    ISNULL(ren.Renta_Media_Hogar, NULL)                 AS Renta_Media_Hogar

FROM SalesDay s

-- Tienda
LEFT JOIN AffiliatedOutlets a
    ON s.Affiliated_Code = a.Affiliated_Code

-- Provincia
LEFT JOIN CodPostalesProvincias p2
    ON a.CPRO = p2.CPRO

-- Producto
LEFT JOIN Product pr
    ON s.Product_Code = pr.Product_Code

-- Entregas del mismo día (agrupadas)
LEFT JOIN (
    SELECT
        CONVERT(DATE, CAST(Delivery_DAY AS VARCHAR), 112) AS Fecha,
        Affiliated_Code,
        Product_Code,
        SUM(Delivery_Uds) AS Total_Delivery_Uds
    FROM DeliveryDay
    GROUP BY
        CONVERT(DATE, CAST(Delivery_DAY AS VARCHAR), 112),
        Affiliated_Code,
        Product_Code
) d ON CONVERT(DATE, CAST(s.Sales_DAY AS VARCHAR), 112) = d.Fecha
    AND s.Affiliated_Code = d.Affiliated_Code
    AND s.Product_Code    = d.Product_Code

-- OoS: si existe registro ese día = rotura declarada
LEFT JOIN OoSDay o
    ON CONVERT(DATE, CAST(s.Sales_DAY AS VARCHAR), 112)
       = CONVERT(DATE, CAST(o.OoS_DAY AS VARCHAR), 112)
    AND s.Affiliated_Code = o.Affiliated_Code
    AND s.Product_Code    = o.Product_Code

-- Ruta: si existe registro ese día = día de reparto programado
LEFT JOIN RouteDay r
    ON CONVERT(DATE, CAST(s.Sales_DAY AS VARCHAR), 112)
       = CONVERT(DATE, CAST(r.Route_DAY AS VARCHAR), 112)
    AND s.Affiliated_Code = r.Affiliated_Code

-- Calendario
LEFT JOIN Calendario c
    ON CONVERT(DATE, CAST(s.Sales_DAY AS VARCHAR), 112) = c.Fecha

-- Renta provincial INE
-- (importar tabla con columnas: CPRO, Renta_Media_Hogar)
LEFT JOIN RentaProvincial ren
    ON a.CPRO = ren.CPRO;


-- ================================================================
-- PASO 5: VERIFICACIÓN RÁPIDA
-- ================================================================

-- Total de registros
SELECT COUNT(*) AS Total_Registros FROM TablaMaestra_Altadis;

-- Primeras filas
SELECT TOP 10 * FROM TablaMaestra_Altadis;

-- Registros con rotura de stock declarada
SELECT COUNT(*) AS Dias_Con_OoS
FROM TablaMaestra_Altadis
WHERE Flag_OoS = 1;

-- Ventas por provincia
SELECT PROVINCIA, SUM(Sales_Uds) AS Total_Ventas
FROM TablaMaestra_Altadis
GROUP BY PROVINCIA
ORDER BY Total_Ventas DESC;
