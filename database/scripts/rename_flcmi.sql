-- =====================================================================
-- Script: Renombrado de id_modulo según "codigos-viejos-y-nuevos-cursos-flc-mi.csv"
-- Motor:  MySQL / MariaDB (InnoDB)
-- Tablas afectadas: modulos (PK), ciclo_modulo, imparte, docente_modulo_ciclo
--
-- Este CSV tiene 19 filas, tratadas en dos grupos:
--
--   A) 18 renombrados simples "código antiguo -> código nuevo", igual que
--      los scripts anteriores. Incluye el caso 0001 -> 999t (código con
--      letra, confirmado como correcto, no es un error de transcripción).
--
--   B) Un caso especial: 0019 -> 20309. El id_modulo 20309 YA EXISTE
--      (es "MI - Formación en Empresa u Organismo Equiparado", creado en
--      el script anterior porque feoe-MI no existía). 0019 es el MISMO
--      módulo con su código antiguo, así que aquí NO se renombra, se
--      FUSIONA: se mueven las asignaciones de 0019 a 20309 en las tres
--      tablas hijas (evitando duplicados de clave) y luego se elimina
--      la fila 0019 de "modulos".
--
-- Misma red de seguridad que los scripts anteriores: todo dentro de una
-- única transacción, comprobaciones previas que abortan sin cambiar
-- nada si algo no cuadra, FK checks desactivados solo durante las
-- actualizaciones, y verificación de que no queden filas huérfanas
-- antes del COMMIT.
--
-- Uso recomendado:
--   1) Backup previo (ver comando al final de este fichero).
--   2) mysql -u <usuario> -p <base_de_datos> < rename_flcmi.sql
--   3) Revisar el mensaje final "OK: ..." o "Abortado: ...".
-- =====================================================================


DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo_flcmi;

DELIMITER $$

CREATE PROCEDURE sp_renombrar_id_modulo_flcmi()
proc: BEGIN
    DECLARE v_faltantes    INT DEFAULT 0;
    DECLARE v_colisiones   INT DEFAULT 0;
    DECLARE v_huerfanos    INT DEFAULT 0;
    DECLARE v_existe_0019  INT DEFAULT 0;
    DECLARE v_existe_20309 INT DEFAULT 0;

    -- =================================================================
    -- Comprobaciones previas del GRUPO A (18 renombrados simples)
    -- =================================================================
    SELECT COUNT(*) INTO v_faltantes
    FROM tmp_id_modulo_map_flcmi m
    LEFT JOIN modulos mo ON mo.id_modulo = m.id_modulo_antiguo
    WHERE mo.id_modulo IS NULL;

    IF v_faltantes > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de origen (grupo A) que no existen en modulos';
    END IF;

    SELECT COUNT(*) INTO v_colisiones
    FROM tmp_id_modulo_map_flcmi m
    JOIN modulos mo ON mo.id_modulo = m.id_modulo_nuevo;

    IF v_colisiones > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de destino (grupo A) que ya existen en modulos';
    END IF;

    -- =================================================================
    -- Comprobaciones previas del GRUPO B (fusión 0019 -> 20309)
    -- =================================================================
    SELECT COUNT(*) INTO v_existe_0019 FROM modulos WHERE id_modulo = '0019';
    SELECT COUNT(*) INTO v_existe_20309 FROM modulos WHERE id_modulo = '20309';

    IF v_existe_0019 = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: el id_modulo 0019 (grupo B) no existe en modulos';
    END IF;

    IF v_existe_20309 = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: el id_modulo 20309 (destino de la fusion) no existe en modulos';
    END IF;

    SET FOREIGN_KEY_CHECKS = 0;

    -- -----------------------------------------------------------------
    -- GRUPO B: fusión de 0019 en 20309
    -- -----------------------------------------------------------------

    -- ciclo_modulo: PK (id_ciclo, id_modulo). Si un ciclo ya tiene tanto
    -- 0019 como 20309, nos quedamos con la fila de 20309 y descartamos
    -- la de 0019 (para no violar la PK al mover el resto).
    DELETE cm0019
    FROM ciclo_modulo cm0019
    JOIN ciclo_modulo cm20309
      ON cm20309.id_ciclo = cm0019.id_ciclo
     AND cm20309.id_modulo = '20309'
    WHERE cm0019.id_modulo = '0019';

    UPDATE ciclo_modulo
    SET id_modulo = '20309'
    WHERE id_modulo = '0019';

    -- imparte: PK (dni, id_modulo, id_centro). Mismo criterio.
    DELETE i0019
    FROM imparte i0019
    JOIN imparte i20309
      ON i20309.dni = i0019.dni
     AND i20309.id_centro = i0019.id_centro
     AND i20309.id_modulo = '20309'
    WHERE i0019.id_modulo = '0019';

    UPDATE imparte
    SET id_modulo = '20309'
    WHERE id_modulo = '0019';

    -- docente_modulo_ciclo: PK es un id autoincremental (sin restricción
    -- compuesta), pero evitamos dejar filas lógicamente duplicadas
    -- (mismo dni + id_ciclo + id_centro + id_modulo=20309 dos veces).
    DELETE d0019
    FROM docente_modulo_ciclo d0019
    JOIN docente_modulo_ciclo d20309
      ON d20309.dni = d0019.dni
     AND d20309.id_ciclo = d0019.id_ciclo
     AND d20309.id_centro = d0019.id_centro
     AND d20309.id_modulo = '20309'
    WHERE d0019.id_modulo = '0019';

    UPDATE docente_modulo_ciclo
    SET id_modulo = '20309'
    WHERE id_modulo = '0019';

    -- Ya no queda ninguna referencia a 0019: eliminamos el módulo antiguo.
    DELETE FROM modulos WHERE id_modulo = '0019';

    -- -----------------------------------------------------------------
    -- GRUPO A: 18 renombrados simples
    -- -----------------------------------------------------------------
    UPDATE ciclo_modulo cm
    JOIN tmp_id_modulo_map_flcmi m ON m.id_modulo_antiguo = cm.id_modulo
    SET cm.id_modulo = m.id_modulo_nuevo;

    UPDATE imparte i
    JOIN tmp_id_modulo_map_flcmi m ON m.id_modulo_antiguo = i.id_modulo
    SET i.id_modulo = m.id_modulo_nuevo;

    UPDATE docente_modulo_ciclo d
    JOIN tmp_id_modulo_map_flcmi m ON m.id_modulo_antiguo = d.id_modulo
    SET d.id_modulo = m.id_modulo_nuevo;

    UPDATE modulos mo
    JOIN tmp_id_modulo_map_flcmi m ON m.id_modulo_antiguo = mo.id_modulo
    SET mo.id_modulo = m.id_modulo_nuevo;

    SET FOREIGN_KEY_CHECKS = 1;

    -- =================================================================
    -- Verificación final: ni huérfanos ni restos de "0019"
    -- =================================================================
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

    SELECT 'OK: 18 codigos renombrados y 0019 fusionado en 20309 (feoe-MI)' AS resultado;
END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- Tabla temporal con los 18 pares del GRUPO A (0019 -> 20309 se trata
-- aparte dentro del procedimiento, como fusión, no como renombrado).
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map_flcmi;

CREATE TEMPORARY TABLE tmp_id_modulo_map_flcmi (
    id_modulo_antiguo VARCHAR(50) NOT NULL PRIMARY KEY,
    id_modulo_nuevo   VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_nuevo (id_modulo_nuevo)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

INSERT INTO tmp_id_modulo_map_flcmi (id_modulo_antiguo, id_modulo_nuevo) VALUES
('0008', '17003'),
('0001', '999t'),
('0015', '16984'),
('0011', '16986'),
('0017', '16989'),
('0006', '17006'),
('0013', '16991'),
('0014', '17008'),
('0018', '17010'),
('0009', '16993'),
('0002', '17012'),
('0012', '17015'),
('0010', '16995'),
('0007', '17017'),
('0005', '16998'),
('0004', '17000'),
('0003', '17020'),
('0016', '17022');
-- 0019 -> 20309 NO va aquí: se trata como fusión dentro del procedimiento.


START TRANSACTION;

CALL sp_renombrar_id_modulo_flcmi();

COMMIT;


DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map_flcmi;
DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo_flcmi;


-- =====================================================================
-- Backup recomendado ANTES de ejecutar este script:
--
--   mysqldump -u <usuario> -p <base_de_datos> \
--     modulos ciclo_modulo imparte docente_modulo_ciclo \
--     > backup_modulos_$(date +%Y%m%d_%H%M%S).sql
-- =====================================================================
