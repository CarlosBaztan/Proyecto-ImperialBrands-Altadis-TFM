USE [TFM Imperial Tobacco];

-- 1. DIM_Producto
SELECT DISTINCT 
    Product_Code,
    SIZE,
    Format
INTO DIM_Producto
FROM TablaMaestra5;

-- 2. DIM_Outlet (provincia y renta incluidas, son fijas por outlet)
SELECT DISTINCT
    Affiliated_Code,
    Affiliated_NAME,
    POSTALCODE,
    PROVINCIA,
    Location,
    Tam_m2,
    Renta_Media_Provincial
INTO DIM_Outlet
FROM TablaMaestra5;

-- 3. DIM_Fecha (calendario completo de la ventana real de SalesDay)
;WITH Fechas AS (
    SELECT CAST('20150309' AS INT) AS Fecha_AAAAMMDD
    UNION ALL
    SELECT CAST(CONVERT(VARCHAR, DATEADD(DAY, 1, CONVERT(DATE, CAST(Fecha_AAAAMMDD AS VARCHAR), 112)), 112) AS INT)
    FROM Fechas
    WHERE Fecha_AAAAMMDD < 20150906
)
SELECT 
    f.Fecha_AAAAMMDD,
    CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112) AS Fecha,
    DATEPART(DAY,   CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Dia,
    DATEPART(MONTH, CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Mes,
    DATEPART(YEAR,  CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Anio,
    DATEPART(WEEK,  CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Semana_Anio,
    DATENAME(WEEKDAY, CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Dia_Semana,
    CASE WHEN DATEPART(WEEKDAY, CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) IN (1,7) 
         THEN 1 ELSE 0 END AS Es_Fin_Semana,
    CASE WHEN nf.Fecha_AAAAMMDD IS NOT NULL THEN 1 ELSE 0 END AS Es_Festivo_Nacional
INTO DIM_Fecha
FROM Fechas f
LEFT JOIN (
    SELECT DISTINCT Fecha_AAAAMMDD 
    FROM Festivos_2015_VentanaVentas 
    WHERE Tipo_Festivo = 'Nacional'
) nf ON nf.Fecha_AAAAMMDD = f.Fecha_AAAAMMDD
OPTION (MAXRECURSION 200);

-- 4. FACT_Ventas (solo claves + métricas; Es_Festivo ya viene resuelto por CCAA real)
SELECT
    Sales_DAY,
    Affiliated_Code,
    Product_Code,
    Sales_Uds,
    Delivery_Unidades,
    Flag_OoS,
    Flag_Ruta,
    Es_Festivoo
INTO FACT_Ventas2
FROM TablaMaestra5;

-- Verificación
SELECT 'DIM_Producto' AS Tabla, COUNT(*) AS Filas FROM DIM_Producto
UNION ALL SELECT 'DIM_Outlet', COUNT(*) FROM DIM_Outlet
UNION ALL SELECT 'DIM_Fecha', COUNT(*) FROM DIM_Fecha
UNION ALL SELECT 'FACT_Ventas', COUNT(*) FROM FACT_Ventas2;


-----------TABLAS------------
USE [TFM Imperial Tobacco]

select *
FROM FACT_Ventas2

select *
FROM TablaMaestra5

select *
FROM DIM_Fecha 

select *
FROM DIM_Outlet

select *
FROM DIM_Producto

SELECT COUNT(*) FROM FACT_Ventas2;
select *
FROM FACT_Ventas2 v
where v.Es_Festivoo <> 0 and v.Sales_DAY = 20150423

USE [TFM Imperial Tobacco];

DROP TABLE DIM_Outlet;
DROP TABLE DIM_Producto

-- ============================================================
-- DIM_Outlet — reconstruida desde la fuente completa (3.583 outlets)
-- ============================================================
SELECT 
    a.Affiliated_Code,
    a.Affiliated_NAME,
    a.POSTALCODE,
    a.PROVINCIA,
    a.Location,
    a.Tam_m2,
    r.Valor AS Renta_Media_Provincial
INTO DIM_Outlet
FROM AffiliatedOutlets_Enrichedd a
LEFT JOIN RentaProvinciaINE_2015 r
    ON a.PROVINCIA = r.Nombre;

-- ============================================================
-- DIM_Producto — reconstruida desde la fuente completa (59 productos,
-- Natu122 resuelto igual que en TablaMaestra5)
-- ============================================================
;WITH Product_Clean AS (
    SELECT Product_Code, SIZE, Format,
           ROW_NUMBER() OVER (
               PARTITION BY Product_Code 
               ORDER BY CASE WHEN Format = 'ATA' THEN 1 ELSE 2 END
           ) AS rn
    FROM Product
)
SELECT Product_Code, SIZE, Format
INTO DIM_Producto
FROM Product_Clean
WHERE rn = 1;

-- ============================================================
-- VERIFICACIÓN
-- ============================================================
SELECT 'DIM_Producto' AS Tabla, COUNT(*) AS Filas FROM DIM_Producto
UNION ALL SELECT 'DIM_Outlet', COUNT(*) FROM DIM_Outlet
UNION ALL SELECT 'DIM_Fecha', COUNT(*) FROM DIM_Fecha
UNION ALL SELECT 'FACT_Ventas', COUNT(*) FROM FACT_Ventas2;

-- Confirmar 0 nulos de renta tras el nuevo cruce
SELECT COUNT(*) AS Sin_Renta FROM DIM_Outlet WHERE Renta_Media_Provincial IS NULL;

--Validación dimensiones
SELECT COUNT(*) AS Ventas_Sin_Outlet
FROM FACT_Ventas f
WHERE f.Affiliated_Code NOT IN (SELECT Affiliated_Code FROM DIM_Outlet);

SELECT COUNT(*) AS Ventas_Sin_Producto
FROM FACT_Ventas f
WHERE f.Product_Code NOT IN (SELECT Product_Code FROM DIM_Producto);

SELECT COUNT(*) AS Ventas_Sin_Fecha
FROM FACT_Ventas f
WHERE f.Sales_DAY NOT IN (SELECT Fecha_AAAAMMDD FROM DIM_Fecha);

-------------------------------------------------------------------------
--------------------------------------------------------------------------
-------------------------------------------------------------------------
USE [TFM Imperial Tobacco];

DROP TABLE DIM_Fecha;

;WITH Fechas AS (
    SELECT CAST('20150309' AS INT) AS Fecha_AAAAMMDD
    UNION ALL
    SELECT CAST(CONVERT(VARCHAR, DATEADD(DAY, 1, CONVERT(DATE, CAST(Fecha_AAAAMMDD AS VARCHAR), 112)), 112) AS INT)
    FROM Fechas
    WHERE Fecha_AAAAMMDD < 20150906
)
SELECT 
    f.Fecha_AAAAMMDD,
    pc.Provincia,
    CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112) AS Fecha,
    DATEPART(DAY,   CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Dia,
    DATEPART(MONTH, CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Mes,
    DATEPART(YEAR,  CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Anio,
    DATEPART(WEEK,  CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Semana_Anio,
    DATENAME(WEEKDAY, CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) AS Dia_Semana,
    CASE WHEN DATENAME(WEEKDAY, CONVERT(DATE, CAST(f.Fecha_AAAAMMDD AS VARCHAR), 112)) IN ('Saturday','Sunday','sábado','domingo') 
         THEN 1 ELSE 0 END AS Es_Fin_Semana,
    CASE WHEN fest.Fecha_AAAAMMDD IS NOT NULL THEN 1 ELSE 0 END AS Es_Festivoo
INTO DIM_Fecha
FROM Fechas f
CROSS JOIN Provincia_CCAA pc
LEFT JOIN Festivos_2015_VentanaVentas fest 
    ON fest.Fecha_AAAAMMDD = f.Fecha_AAAAMMDD 
    AND fest.CCAA = pc.CCAA
OPTION (MAXRECURSION 200);

SELECT COUNT(*) AS Total_Filas, COUNT(DISTINCT Provincia) AS Provincias, 
       SUM(Es_Festivoo) AS Total_Festivos, SUM(Es_Fin_Semana) AS Total_Fin_Semana
FROM DIM_Fecha;
-------------------------------------------------------------------
--------------------------------------------------------------------
