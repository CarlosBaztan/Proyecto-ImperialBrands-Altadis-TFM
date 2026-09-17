USE [TFM Imperial Tobacco];

select top 100*
from TablaMaestra4

-- ============================================================
-- PASO 1: Crear TablaMaestra4 con Product limpio (Natu122 resuelto como ATA)
-- ============================================================
WITH Product_Clean AS (
    SELECT Product_Code, SIZE, Format,
           ROW_NUMBER() OVER (
               PARTITION BY Product_Code 
               ORDER BY CASE WHEN Format = 'ATA' THEN 1 ELSE 2 END
           ) AS rn
    FROM Product
)
SELECT s.*,
       a.Affiliated_NAME, a.POSTALCODE, a.PROVINCIA, a.Location, a.Tam_m2,
       p.SIZE, p.Format

INTO TablaMaestra6

FROM SalesDay s
LEFT JOIN AffiliatedOutlets_Enriched a 
    ON s.Affiliated_Code = a.Affiliated_Code
LEFT JOIN Product_Clean p
    ON s.Product_Code = p.Product_Code
    AND p.rn = 1;

-- ============================================================
-- PASO 2: Añadir columnas vacías
-- ============================================================
ALTER TABLE TablaMaestra4
ADD Delivery_Unidades FLOAT,
    Flag_OoS          INT,
    Flag_Ruta         INT;

-- ============================================================
-- PASO 3: Rellenar entregas (JOIN, no subconsulta correlacionada)
-- ============================================================
UPDATE t
SET t.Delivery_Unidades = ISNULL(d.total, 0)
FROM TablaMaestra4 t
LEFT JOIN (
    SELECT Delivery_DAY, Affiliated_Code, Product_Code,
           SUM(Delivery_Uds) AS total
    FROM DeliveryDay
    GROUP BY Delivery_DAY, Affiliated_Code, Product_Code
) d ON d.Delivery_DAY     = t.Sales_DAY
    AND d.Affiliated_Code  = t.Affiliated_Code
    AND d.Product_Code     = t.Product_Code;

-- ============================================================
-- PASO 4: Flag de rotura de stock (JOIN)
-- ============================================================
UPDATE t
SET t.Flag_OoS = CASE WHEN o.Affiliated_Code IS NOT NULL THEN 1 ELSE 0 END
FROM TablaMaestra4 t
LEFT JOIN [dbo].[OutOfStock(Rotura)] o
    ON o.OoS_DAY          = t.Sales_DAY
    AND o.Affiliated_Code  = t.Affiliated_Code
    AND o.Product_Code     = t.Product_Code;

-- ============================================================
-- PASO 5: Flag de ruta (JOIN)
-- ============================================================
UPDATE t
SET t.Flag_Ruta = CASE WHEN r.Affiliated_Code IS NOT NULL THEN 1 ELSE 0 END
FROM TablaMaestra4 t
LEFT JOIN RouteDay r
    ON CAST(CONVERT(VARCHAR, r.Route_DAY, 112) AS FLOAT) = t.Sales_DAY
    AND r.Affiliated_Code = t.Affiliated_Code;

-- ============================================================
-- VERIFICACIÓN
-- ============================================================
SELECT COUNT(*) AS Dias_Con_Rotura      FROM TablaMaestra4 WHERE Flag_OoS = 1;
SELECT COUNT(*) AS Dias_Con_Ruta        FROM TablaMaestra4 WHERE Flag_Ruta = 1;
SELECT COUNT(*) AS Entregas_Negativas   FROM TablaMaestra4 WHERE Delivery_Unidades < 0;
SELECT COUNT(DISTINCT Product_Code)     AS Productos_Unicos FROM TablaMaestra4;
