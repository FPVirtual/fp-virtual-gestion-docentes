-- =====================================================================
-- Script: ROLLBACK - Renombrado de id_modulo (códigos numéricos -> "feoe-XX")
-- Motor:  MySQL / MariaDB (InnoDB)
-- Tablas afectadas: modulos (PK), ciclo_modulo, imparte, docente_modulo_ciclo
--
-- Úsalo SOLO si ya ejecutaste rename_feoe_id_modulo_to_numeric.sql y
-- necesitas deshacer el cambio (alternativa a restaurar el backup).
--
-- NOTA sobre 20309 (feoe-MI): ese módulo NO existía antes del script de
-- ida (se creó de cero). Este rollback revierte los 22 renombrados,
-- pero NO borra automáticamente el módulo 20309: bórralo tú mismo al
-- final (bloque 4, comentado) solo si estás seguro de que nada lo
-- necesita ya, porque si algún docente/ciclo se ha asignado a 20309
-- desde que se creó, borrarlo se llevaría esas asignaciones por delante.
--
-- Uso:
--   mysql -u <usuario> -p <base_de_datos> < rollback_id_modulo_a_feoe.sql
-- =====================================================================


DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo;

DELIMITER $$

CREATE PROCEDURE sp_renombrar_id_modulo()
proc: BEGIN
    DECLARE v_faltantes  INT DEFAULT 0;
    DECLARE v_colisiones INT DEFAULT 0;
    DECLARE v_huerfanos  INT DEFAULT 0;

    SELECT COUNT(*) INTO v_faltantes
    FROM tmp_id_modulo_map m
    LEFT JOIN modulos mo ON mo.id_modulo = m.id_modulo_antiguo
    WHERE mo.id_modulo IS NULL;

    IF v_faltantes > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de origen que no existen en modulos';
    END IF;

    SELECT COUNT(*) INTO v_colisiones
    FROM tmp_id_modulo_map m
    JOIN modulos mo ON mo.id_modulo = m.id_modulo_nuevo;

    IF v_colisiones > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de destino que ya existen en modulos';
    END IF;

    SET FOREIGN_KEY_CHECKS = 0;

    UPDATE ciclo_modulo cm
    JOIN tmp_id_modulo_map m ON m.id_modulo_antiguo = cm.id_modulo
    SET cm.id_modulo = m.id_modulo_nuevo;

    UPDATE imparte i
    JOIN tmp_id_modulo_map m ON m.id_modulo_antiguo = i.id_modulo
    SET i.id_modulo = m.id_modulo_nuevo;

    UPDATE docente_modulo_ciclo d
    JOIN tmp_id_modulo_map m ON m.id_modulo_antiguo = d.id_modulo
    SET d.id_modulo = m.id_modulo_nuevo;

    UPDATE modulos mo
    JOIN tmp_id_modulo_map m ON m.id_modulo_antiguo = mo.id_modulo
    SET mo.id_modulo = m.id_modulo_nuevo;

    SET FOREIGN_KEY_CHECKS = 1;

    SELECT COUNT(*) INTO v_huerfanos FROM (
        SELECT id_modulo FROM ciclo_modulo
        WHERE id_modulo NOT IN (SELECT id_modulo FROM modulos)
        UNION ALL
        SELECT id_modulo FROM imparte
        WHERE id_modulo NOT IN (SELECT id_modulo FROM modulos)
        UNION ALL
        SELECT id_modulo FROM docente_modulo_ciclo
        WHERE id_modulo NOT IN (SELECT id_modulo FROM modulos)
    ) huerfanos;

    IF v_huerfanos > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: han quedado filas huerfanas tras la actualizacion';
    END IF;

    SELECT 'OK: 22 codigos revertidos a feoe-XX. Revisa el bloque 4 de este script para decidir que hacer con el modulo 20309 (feoe-MI).' AS resultado;
END$$

DELIMITER ;


DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map;

CREATE TEMPORARY TABLE tmp_id_modulo_map (
    id_modulo_antiguo VARCHAR(50) NOT NULL PRIMARY KEY,
    id_modulo_nuevo   VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_nuevo (id_modulo_nuevo)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Mapeo INVERTIDO: origen = código numérico actual, destino = feoe-XX original
-- (los 22 que realmente existían antes; 20309/feoe-MI se trata aparte, ver arriba)
INSERT INTO tmp_id_modulo_map (id_modulo_antiguo, id_modulo_nuevo) VALUES
('20293', 'feoe-AC'),
('20300', 'feoe-AD'),
('20299', 'feoe-AF'),
('20298', 'feoe-APSD'),
('20306', 'feoe-ASIR'),
('20305', 'feoe-AVGE'),
('20301', 'feoe-CI'),
('20307', 'feoe-DAM'),
('20308', 'feoe-DAW'),
('20312', 'feoe-ECA'),
('20313', 'feoe-EI'),
('20297', 'feoe-ES'),
('20296', 'feoe-FP'),
('20292', 'feoe-GA'),
('20302', 'feoe-GVEC'),
('20294', 'feoe-IEA'),
('20314', 'feoe-IS'),
('20311', 'feoe-LACC'),
('20310', 'feoe-PAE'),
('20295', 'feoe-SMR'),
('20304', 'feoe-STI'),
('20303', 'feoe-TL');


START TRANSACTION;

CALL sp_renombrar_id_modulo();

COMMIT;


DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map;
DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo;


-- =====================================================================
-- 4) OPCIONAL - Eliminar el módulo 20309 (feoe-MI) creado por el script
--    de ida, SOLO si no tiene ninguna asignación (ciclo_modulo, imparte,
--    docente_modulo_ciclo). Descomenta y ejecuta aparte tras revisar:
--
--   SELECT
--     (SELECT COUNT(*) FROM ciclo_modulo WHERE id_modulo = '20309') AS en_ciclo_modulo,
--     (SELECT COUNT(*) FROM imparte WHERE id_modulo = '20309') AS en_imparte,
--     (SELECT COUNT(*) FROM docente_modulo_ciclo WHERE id_modulo = '20309') AS en_docente_modulo_ciclo;
--
--   -- Si las tres columnas dan 0:
--   -- DELETE FROM modulos WHERE id_modulo = '20309';
-- =====================================================================
