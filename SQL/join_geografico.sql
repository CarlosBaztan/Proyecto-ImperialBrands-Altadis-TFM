-- ============================================================
-- TFM Altadis / Imperial Brands
-- Enriquecimiento geográfico de la red de distribución
-- Fuentes: Affiliated_Outlets.csv + 26codmun.xlsx (INE)
-- ============================================================

-- LÓGICA DEL JOIN
-- Los primeros 2 dígitos del POSTALCODE de Affiliated_Outlets
-- coinciden con el CPRO (código de provincia) del INE.
--   Ejemplo: POSTALCODE = '28015'  →  CPRO = '28'  →  Madrid
--            POSTALCODE = '08940'  →  CPRO = '08'  →  Barcelona

-- ── TABLA 1: affiliated_outlets ─────────────────────────────
-- Cargada desde Affiliated_Outlets.csv
-- Columnas: Affiliated_Code, Affiliated_NAME, POSTALCODE,
--           Engage, Management_Cluster, Location, Tam_m2, CPRO

-- ── TABLA 2: provincias ──────────────────────────────────────
-- Generada a partir de 26codmun.xlsx (INE, 52 hojas)
-- Columnas: CPRO (01-52), PROVINCIA (nombre completo)

-- ── TABLA 3: municipios_ine ──────────────────────────────────
-- Todos los municipios del INE con su código y nombre
-- Columnas: CPRO, CMUN, DC, NOMBRE, PROVINCIA

-- ── VISTA PRINCIPAL: v_outlets_provincia ────────────────────
-- Une cada estanco con su provincia a través del CPRO
CREATE VIEW IF NOT EXISTS v_outlets_provincia AS
SELECT
    a.Affiliated_Code,
    a.Affiliated_NAME,
    a.POSTALCODE,
    a.CPRO,
    p.PROVINCIA,
    a.Engage,
    a.Management_Cluster,
    a.Location,
    a.Tam_m2
FROM affiliated_outlets a
LEFT JOIN provincias p ON a.CPRO = p.CPRO;


-- ── CONSULTAS DE ANÁLISIS ────────────────────────────────────

-- 1. Número de estancos por provincia (ordenado de mayor a menor)
SELECT
    PROVINCIA,
    COUNT(*) AS num_estancos
FROM v_outlets_provincia
GROUP BY PROVINCIA
ORDER BY num_estancos DESC;

-- 2. Distribución por tipo de ubicación y provincia
SELECT
    PROVINCIA,
    Location,
    COUNT(*) AS num_estancos
FROM v_outlets_provincia
GROUP BY PROVINCIA, Location
ORDER BY PROVINCIA, num_estancos DESC;

-- 3. Distribución por cluster de gestión y provincia
SELECT
    PROVINCIA,
    Management_Cluster,
    COUNT(*) AS num_estancos
FROM v_outlets_provincia
GROUP BY PROVINCIA, Management_Cluster
ORDER BY PROVINCIA, Management_Cluster;

-- 4. Provincias con mayor proporción de estancos en zonas turísticas
SELECT
    PROVINCIA,
    COUNT(*) AS total,
    SUM(CASE WHEN Location = 'VACATIONAL' THEN 1 ELSE 0 END) AS turisticos,
    ROUND(100.0 * SUM(CASE WHEN Location = 'VACATIONAL' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_turistico
FROM v_outlets_provincia
GROUP BY PROVINCIA
HAVING total >= 10
ORDER BY pct_turistico DESC;

-- 5. Buscar un estanco concreto por código postal
SELECT *
FROM v_outlets_provincia
WHERE POSTALCODE = '28015';
