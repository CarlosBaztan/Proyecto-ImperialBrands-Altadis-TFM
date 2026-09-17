USE [TFM Imperial Tobacco];

--Añado columnas--
ALTER TABLE TablaMaestra5
ADD Delivery_Unidades FLOAT,
    Flag_OoS          INT,
    Flag_Ruta         INT;

select top 100*
from TablaMaestra5

select Sales_Uds
from TablaMaestra5
where Sales_Uds < 0

UPDATE t
SET t.Delivery_Unidades = ISNULL(d.total, 0)
FROM TablaMaestra5 t
LEFT JOIN (
    SELECT Delivery_DAY, Affiliated_Code, Product_Code,
           SUM(Delivery_Uds) AS total
    FROM DeliveryDay
    GROUP BY Delivery_DAY, Affiliated_Code, Product_Code
) d ON d.Delivery_DAY     = t.Sales_DAY
    AND d.Affiliated_Code  = t.Affiliated_Code
    AND d.Product_Code     = t.Product_Code;

UPDATE t
SET t.Flag_OoS = CASE WHEN o.Affiliated_Code IS NOT NULL THEN 1 ELSE 0 END
FROM TablaMaestra5 t
LEFT JOIN [dbo].[OutOfStock(Rotura)] o
    ON o.OoS_DAY          = t.Sales_DAY
    AND o.Affiliated_Code  = t.Affiliated_Code
    AND o.Product_Code     = t.Product_Code;

UPDATE t
SET t.Flag_Ruta = CASE WHEN r.Affiliated_Code IS NOT NULL THEN 1 ELSE 0 END
FROM TablaMaestra5 t
LEFT JOIN RouteDay r
    ON CAST(CONVERT(VARCHAR, r.Route_DAY, 112) AS FLOAT) = t.Sales_DAY
    AND r.Affiliated_Code = t.Affiliated_Code;

--Comproebo valores columnas creadas--
SELECT 
    COUNT(*) AS Total,
    SUM(CASE WHEN Flag_OoS = 1 THEN 1 ELSE 0 END) AS Con_Rotura,
    SUM(CASE WHEN Flag_Ruta = 1 THEN 1 ELSE 0 END) AS Con_Ruta,
    SUM(CASE WHEN Delivery_Unidades > 0 THEN 1 ELSE 0 END) AS Con_Entrega
FROM TablaMaestra5;



-- DATOS PRICIPALES TABLAMAESTRA5--
-----------------------------------
SELECT
    COUNT(*)                                          AS Total_Registros,
    COUNT(DISTINCT Affiliated_Code)                   AS Outlets_Unicos,
    COUNT(DISTINCT Product_Code)                      AS Productos_Unicos,
    MIN(Sales_DAY)                                     AS Fecha_Min,
    MAX(Sales_DAY)                                     AS Fecha_Max,
    SUM(CASE WHEN Sales_Uds > 0 THEN Sales_Uds ELSE 0 END) AS Unidades_Vendidas_Total,
    SUM(CASE WHEN Flag_OoS = 1 THEN 1 ELSE 0 END)      AS Dias_Con_Rotura,
    SUM(CASE WHEN Flag_Ruta = 1 THEN 1 ELSE 0 END)     AS Dias_Con_Ruta,
    SUM(CASE WHEN Delivery_Unidades > 0 THEN 1 ELSE 0 END) AS Dias_Con_Entrega
FROM TablaMaestra5;

----Tabla renta importada a SSMS21
use [TFM Imperial Tobacco]
select *
from dbo.
--Comprobacion si coinciden nombres provincias
SELECT DISTINCT t.PROVINCIA
FROM TablaMaestra5 t
WHERE t.PROVINCIA NOT IN (SELECT Nombre FROM RentaProvincialNE_2015);