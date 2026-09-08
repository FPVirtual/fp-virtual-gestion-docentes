-- =====================================================================
-- Script: ROLLBACK (parcial) de rename_flcmi.sql
-- Motor:  MySQL / MariaDB (InnoDB)
--
-- IMPORTANTE - LEE ESTO ANTES DE USARLO:
-- Este rollback SOLO deshace el GRUPO A (los 18 renombrados simples).
-- La fusión del GRUPO B (0019 -> 20309) NO es reversible con un script:
-- al fusionar, las filas de las tablas hijas que antes apuntaban a 0019
-- pasaron a apuntar a 20309, y la fila 0019 de "modulos" se borró. No
-- hay forma de saber, a partir del estado fusionado, qué filas de 20309
-- eran originalmente de 0019. Si necesitas deshacer también la fusión,
-- la única vía fiable es restaurar el backup (mysqldump) que hiciste
-- antes de ejecutar rename_flcmi.sql.
--
-- Uso:
--   mysql -u <usuario> -p <base_de_datos> < rollback_flcmi.sql
-- =====================================================================


DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo_flcmi;

DELIMITER $$

CREATE PROCEDURE sp_renombrar_id_modulo_flcmi()
proc: BEGIN
    DECLARE v_faltantes  INT DEFAULT 0;
    DECLARE v_colisiones INT DEFAULT 0;
    DECLARE v_huerfanos  INT DEFAULT 0;

    SELECT COUNT(*) INTO v_faltantes
    FROM tmp_id_modulo_map_flcmi m
    LEFT JOIN modulos mo ON mo.id_modulo = m.id_modulo_antiguo
    WHERE mo.id_modulo IS NULL;

    IF v_faltantes > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de origen que no existen en modulos';
    END IF;

    SELECT COUNT(*) INTO v_colisiones
    FROM tmp_id_modulo_map_flcmi m
    JOIN modulos mo ON mo.id_modulo = m.id_modulo_nuevo;

    IF v_colisiones > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de destino que ya existen en modulos';
    END IF;

    SET FOREIGN_KEY_CHECKS = 0;

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

    SELECT 'OK: 18 codigos del grupo A revertidos. El grupo B (fusion 0019->20309) NO se revierte: restaura el backup si hace falta.' AS resultado;
END$$

DELIMITER ;


DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map_flcmi;

CREATE TEMPORARY TABLE tmp_id_modulo_map_flcmi (
    id_modulo_antiguo VARCHAR(50) NOT NULL PRIMARY KEY,
    id_modulo_nuevo   VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_nuevo (id_modulo_nuevo)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Mapeo INVERTIDO del grupo A únicamente
INSERT INTO tmp_id_modulo_map_flcmi (id_modulo_antiguo, id_modulo_nuevo) VALUES
('17003', '0008'),
('999t',  '0001'),
('16984', '0015'),
('16986', '0011'),
('16989', '0017'),
('17006', '0006'),
('16991', '0013'),
('17008', '0014'),
('17010', '0018'),
('16993', '0009'),
('17012', '0002'),
('17015', '0012'),
('16995', '0010'),
('17017', '0007'),
('16998', '0005'),
('17000', '0004'),
('17020', '0003'),
('17022', '0016');


START TRANSACTION;

CALL sp_renombrar_id_modulo_flcmi();

COMMIT;


DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map_flcmi;
DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo_flcmi;
