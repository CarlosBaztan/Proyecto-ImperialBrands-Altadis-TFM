select *
from TablaMaestra5

--Crear tabla Provincia - CCAA
USE [TFM Imperial Tobacco];

CREATE TABLE Provincia_CCAA (
    Provincia VARCHAR(50),
    CCAA      VARCHAR(50)
);

INSERT INTO Provincia_CCAA (Provincia, CCAA) VALUES
('Almería', 'Andalucía'),
('Cádiz', 'Andalucía'),
('Córdoba', 'Andalucía'),
('Granada', 'Andalucía'),
('Huelva', 'Andalucía'),
('Jaén', 'Andalucía'),
('Málaga', 'Andalucía'),
('Sevilla', 'Andalucía'),
('Huesca', 'Aragón'),
('Teruel', 'Aragón'),
('Zaragoza', 'Aragón'),
('Asturias', 'Asturias'),
('Illes Balears', 'Baleares'),
('Las Palmas', 'Canarias'),
('Santa Cruz de Tenerife', 'Canarias'),
('Cantabria', 'Cantabria'),
('Albacete', 'Castilla-La Mancha'),
('Ciudad Real', 'Castilla-La Mancha'),
('Cuenca', 'Castilla-La Mancha'),
('Guadalajara', 'Castilla-La Mancha'),
('Toledo', 'Castilla-La Mancha'),
('Ávila', 'Castilla y León'),
('Burgos', 'Castilla y León'),
('León', 'Castilla y León'),
('Palencia', 'Castilla y León'),
('Salamanca', 'Castilla y León'),
('Segovia', 'Castilla y León'),
('Soria', 'Castilla y León'),
('Valladolid', 'Castilla y León'),
('Zamora', 'Castilla y León'),
('Barcelona', 'Cataluña'),
('Girona', 'Cataluña'),
('Lleida', 'Cataluña'),
('Tarragona', 'Cataluña'),
('Alicante/Alacant', 'Comunitat Valenciana'),
('Castellón/Castelló', 'Comunitat Valenciana'),
('Valencia/València', 'Comunitat Valenciana'),
('Badajoz', 'Extremadura'),
('Cáceres', 'Extremadura'),
('A Coruña', 'Galicia'),
('Lugo', 'Galicia'),
('Ourense', 'Galicia'),
('Pontevedra', 'Galicia'),
('Madrid', 'Madrid'),
('Murcia', 'Murcia'),
('Navarra', 'Navarra'),
('Araba/Álava', 'País Vasco'),
('Bizkaia', 'País Vasco'),
('Gipuzkoa', 'País Vasco'),
('La Rioja', 'La Rioja'),
('Ceuta', 'Ceuta'),
('Melilla', 'Melilla');

--Comprobación
SELECT DISTINCT t.PROVINCIA
FROM TablaMaestra5 t
WHERE t.PROVINCIA NOT IN (SELECT Provincia FROM Provincia_CCAA);

---Creamos TABLA FESTIVOS 
select *
from Festivos_2015
---
    USE [TFM Imperial Tobacco];

    CREATE TABLE Festivos_2015 (
        Fecha_AAAAMMDD INT,
        Descripcion     VARCHAR(60),
        Tipo_Festivo    VARCHAR(30),
        CCAA            VARCHAR(50)
    );

    -- Festivos nacionales no sustituibles (aplican a TODAS las CCAA)
    INSERT INTO Festivos_2015 (Fecha_AAAAMMDD, Descripcion, Tipo_Festivo, CCAA)
    SELECT v.Fecha_AAAAMMDD, v.Descripcion, 'Nacional', c.CCAA
    FROM (VALUES
        (20150101, 'Año Nuevo'),
        (20150403, 'Viernes Santo'),
        (20150501, 'Fiesta del Trabajo'),
        (20150815, 'Asunción de la Virgen'),
        (20151012, 'Fiesta Nacional de España'),
        (20151208, 'Inmaculada Concepción'),
        (20151225, 'Natividad del Señor')
    ) AS v(Fecha_AAAAMMDD, Descripcion)
    CROSS JOIN (SELECT DISTINCT CCAA FROM Provincia_CCAA) c;

    -- Epifanía (todas las CCAA la celebran, sin sustitución)
    INSERT INTO Festivos_2015 (Fecha_AAAAMMDD, Descripcion, Tipo_Festivo, CCAA)
    SELECT 20150106, 'Epifanía del Señor', 'Nacional', CCAA FROM Provincia_CCAA;

    -- Jueves Santo (todas excepto Cataluña y Comunitat Valenciana)
    INSERT INTO Festivos_2015 (Fecha_AAAAMMDD, Descripcion, Tipo_Festivo, CCAA)
    SELECT 20150402, 'Jueves Santo', 'Nacional', CCAA 
    FROM (SELECT DISTINCT CCAA FROM Provincia_CCAA) p
    WHERE CCAA NOT IN ('Cataluña', 'Comunitat Valenciana');

    -- Festivos autonómicos específicos
    INSERT INTO Festivos_2015 (Fecha_AAAAMMDD, Descripcion, Tipo_Festivo, CCAA) VALUES
    (20150228, 'Día de Andalucía', 'Autonómica', 'Andalucía'),
    (20150319, 'San José', 'Autonómica', 'Aragón'),
    (20150319, 'San José', 'Autonómica', 'Comunitat Valenciana'),
    (20150319, 'San José', 'Autonómica', 'Murcia'),
    (20150319, 'San José', 'Autonómica', 'Navarra'),
    (20150319, 'San José', 'Autonómica', 'País Vasco'),
    (20150406, 'Lunes de Pascua', 'Autonómica', 'Baleares'),
    (20150406, 'Lunes de Pascua', 'Autonómica', 'Cantabria'),
    (20150406, 'Lunes de Pascua', 'Autonómica', 'Castilla y León'),
    (20150406, 'Lunes de Pascua', 'Autonómica', 'Cataluña'),
    (20150406, 'Lunes de Pascua', 'Autonómica', 'Navarra'),
    (20150406, 'Lunes de Pascua', 'Autonómica', 'País Vasco'),
    (20150406, 'Lunes de Pascua', 'Autonómica', 'La Rioja'),
    (20150423, 'San Jorge / Día de Aragón', 'Autonómica', 'Aragón'),
    (20150502, 'Fiesta Comunidad de Madrid', 'Autonómica', 'Madrid'),
    (20150530, 'Día de Canarias', 'Autonómica', 'Canarias'),
    (20150604, 'Corpus Christi', 'Autonómica', 'Castilla-La Mancha'),
    (20150604, 'Corpus Christi', 'Autonómica', 'Castilla y León'),
    (20150609, 'Día de la Región de Murcia', 'Autonómica', 'Murcia'),
    (20150609, 'Día de La Rioja', 'Autonómica', 'La Rioja'),
    (20150624, 'San Juan', 'Autonómica', 'Cataluña'),
    (20150725, 'Santiago Apóstol', 'Autonómica', 'Galicia'),
    (20150725, 'Santiago Apóstol', 'Autonómica', 'Madrid'),
    (20150725, 'Santiago Apóstol', 'Autonómica', 'Navarra'),
    (20150908, 'Día de Extremadura', 'Autonómica', 'Extremadura'),
    (20150908, 'Día de Asturias', 'Autonómica', 'Asturias'),
    (20150911, 'Fiesta Nacional de Cataluña', 'Autonómica', 'Cataluña'),
    (20150915, 'Bien Aparecida', 'Autonómica', 'Cantabria'),
    (20151009, 'Día de la Comunitat Valenciana', 'Autonómica', 'Comunitat Valenciana'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Andalucía'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Aragón'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Asturias'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Baleares'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Canarias'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Cantabria'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Castilla y León'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Extremadura'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Galicia'),
    (20151102, 'Lunes sig. Todos los Santos', 'Autonómica', 'Ceuta'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Andalucía'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Aragón'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Asturias'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Baleares'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Castilla-La Mancha'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Castilla y León'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Comunitat Valenciana'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Extremadura'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Murcia'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'La Rioja'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Ceuta'),
    (20151207, 'Lunes sig. Constitución', 'Autonómica', 'Melilla');

--------FECHAS VENTANA CONCRETA SALES DAY (marzo a sept)
CREATE VIEW Festivos_2015_VentanaVentas AS 
SELECT *
FROM Festivos_2015
WHERE Fecha_AAAAMMDD BETWEEN 20150309 AND 20150906;

------------------------------------------------------------
select *
from Festivos_2015

SELECT COUNT(*) 
FROM Festivos_2015
WHERE Fecha_AAAAMMDD BETWEEN 20150309 AND 20150906;

SELECT COUNT(*) 
FROM Festivos_2015

--Comprobación fechas correctas 
SELECT Fecha_AAAAMMDD, Descripcion, COUNT(*) AS Num_CCAA
FROM Festivos_2015
WHERE Fecha_AAAAMMDD BETWEEN 20150309 AND 20150906
GROUP BY Fecha_AAAAMMDD, Descripcion
ORDER BY Fecha_AAAAMMDD;

--Añadir variable Es_Festivo
ALTER TABLE TablaMaestra5
ADD Es_Festivoo INT;

UPDATE t
SET t.Es_Festivoo = CASE WHEN f.Fecha_AAAAMMDD IS NOT NULL THEN 1 ELSE 0 END
FROM TablaMaestra5 t
LEFT JOIN Provincia_CCAA pc 
    ON t.PROVINCIA = pc.Provincia
LEFT JOIN Festivos_2015_VentanaVentas f 
    ON f.Fecha_AAAAMMDD = t.Sales_DAY 
    AND f.CCAA = pc.CCAA;

-- ¿Cuantos FESTIVOS salen? (filas)
    SELECT 
    COUNT(*) AS Total_Filas,
    SUM(CASE WHEN Es_Festivoo = 1 THEN 1 ELSE 0 END) AS Dias_Festivos
FROM TablaMaestra5;


