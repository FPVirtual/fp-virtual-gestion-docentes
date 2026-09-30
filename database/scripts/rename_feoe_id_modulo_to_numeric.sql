-- =====================================================================
-- Script: Renombrado de id_modulo (códigos "feoe-XX" -> códigos numéricos)
-- Motor:  MySQL / MariaDB (InnoDB)
-- Tablas afectadas: modulos (PK), ciclo_modulo, imparte, docente_modulo_ciclo
--
-- NOTA (v2): de los 23 códigos originales, "feoe-MI" NO existe en la
-- tabla "modulos" de producción (comprobado). En vez de renombrar un
-- módulo existente para ese caso, este script CREA el módulo nuevo con
-- id_modulo = 20309 y nombre = 'MI - Formación en Empresa u Organismo
-- Equiparado' (mismo patrón que los otros 22 módulos feoe-XX). Los
-- otros 22 códigos SÍ existen y se renombran como en la v1.
--
-- Por qué hace falta este script y no un UPDATE simple:
--   "modulos.id_modulo" es la clave primaria y las otras tres tablas la
--   referencian con FOREIGN KEY ... ON DELETE CASCADE, pero SIN
--   ON UPDATE CASCADE. Un UPDATE directo sobre "modulos" fallaría por
--   violación de integridad referencial mientras existan filas hijas
--   apuntando al id_modulo antiguo. Este script actualiza padre e hijas
--   de forma coordinada, dentro de una transacción, con comprobaciones
--   automáticas que abortan (ROLLBACK) si algo no cuadra.
--
-- Uso recomendado:
--   1) Backup previo (ver comando al final de este fichero).
--   2) mysql -u <usuario> -p <base_de_datos> < rename_feoe_id_modulo_to_numeric.sql
--   3) Revisar el mensaje final. Si aparece un error "Abortado: ..." no se
--      ha cambiado NADA (rollback automático); corrige la causa y reintenta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) Procedimiento con toda la lógica y las comprobaciones de seguridad.
--    Se crea FUERA de la transacción porque CREATE/DROP PROCEDURE hacen
--    COMMIT implícito en MySQL/MariaDB.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo;

DELIMITER $$

CREATE PROCEDURE sp_renombrar_id_modulo()
proc: BEGIN
    DECLARE v_faltantes  INT DEFAULT 0;
    DECLARE v_colisiones INT DEFAULT 0;
    DECLARE v_huerfanos  INT DEFAULT 0;
    DECLARE v_existe_mi  INT DEFAULT 0;

    -- Comprobación 1: todos los id_modulo de origen (los 22 que SÍ
    -- deben existir) deben estar en "modulos"
    SELECT COUNT(*) INTO v_faltantes
    FROM tmp_id_modulo_map m
    LEFT JOIN modulos mo ON mo.id_modulo = m.id_modulo_antiguo
    WHERE mo.id_modulo IS NULL;

    IF v_faltantes > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de origen que no existen en modulos';
    END IF;

    -- Comprobación 2: ninguno de los id_modulo de destino (de los 22
    -- renombrados) debe existir ya
    SELECT COUNT(*) INTO v_colisiones
    FROM tmp_id_modulo_map m
    JOIN modulos mo ON mo.id_modulo = m.id_modulo_nuevo;

    IF v_colisiones > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de destino que ya existen en modulos';
    END IF;

    -- Comprobación 3: el nuevo id_modulo 20309 (feoe-MI) tampoco debe
    -- existir ya, para no pisar un módulo existente
    SELECT COUNT(*) INTO v_existe_mi
    FROM modulos WHERE id_modulo = '20309';

    IF v_existe_mi > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: el id_modulo 20309 ya existe en modulos';
    END IF;

    -- Creamos el módulo nuevo para feoe-MI (no existía en producción)
    INSERT INTO modulos (id_modulo, nombre, created_at, updated_at)
    VALUES ('20309', 'MI - Formación en Empresa u Organismo Equiparado', NOW(), NOW());

    -- Desactivamos temporalmente los checks de FK (las FK no tienen
    -- ON UPDATE CASCADE, así que necesitamos actualizar padre e hijas
    -- de forma coordinada sin que cada UPDATE individual falle).
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

    -- Comprobación 4: no debe quedar ninguna fila huérfana en las tablas hijas
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

    SELECT 'OK: 22 codigos renombrados, modulo 20309 (feoe-MI) creado, sin filas huerfanas' AS resultado;
END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- 2) Tabla temporal con el mapeo antiguo -> nuevo (22 pares; feoe-MI se
--    trata aparte dentro del procedimiento porque no existe todavía).
--    CREATE TEMPORARY TABLE no hace commit implícito, así que es seguro
--    crearla ya (se destruye sola al cerrar la sesión, o la borramos
--    explícitamente al final).
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map;

CREATE TEMPORARY TABLE tmp_id_modulo_map (
    id_modulo_antiguo VARCHAR(50) NOT NULL PRIMARY KEY,
    id_modulo_nuevo   VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_nuevo (id_modulo_nuevo)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
-- (mismo charset/collation que usan las tablas de la app: ver
--  config/database.php -> DB_CHARSET / DB_COLLATION)

INSERT INTO tmp_id_modulo_map (id_modulo_antiguo, id_modulo_nuevo) VALUES
('feoe-AC',   '20293'),
('feoe-AD',   '20300'),
('feoe-AF',   '20299'),
('feoe-APSD', '20298'),
('feoe-ASIR', '20306'),
('feoe-AVGE', '20305'),
('feoe-CI',   '20301'),
('feoe-DAM',  '20307'),
('feoe-DAW',  '20308'),
('feoe-ECA',  '20312'),
('feoe-EI',   '20313'),
('feoe-ES',   '20297'),
('feoe-FP',   '20296'),
('feoe-GA',   '20292'),
('feoe-GVEC', '20302'),
('feoe-IEA',  '20294'),
('feoe-IS',   '20314'),
('feoe-LACC', '20311'),
-- feoe-MI -> 20309 NO va aquí: no existe en producción, se crea directamente
-- (ver INSERT dentro del procedimiento).
('feoe-PAE',  '20310'),
('feoe-SMR',  '20295'),
('feoe-STI',  '20304'),
('feoe-TL',   '20303');


-- ---------------------------------------------------------------------
-- 3) Ejecución dentro de una transacción explícita.
--    Si el procedimiento hace SIGNAL, la ejecución del script se detiene
--    aquí (el cliente "mysql" para en el primer error salvo que se use
--    --force), el COMMIT de más abajo NUNCA se ejecuta y, al cerrarse la
--    conexión, MySQL revierte la transacción abierta automáticamente.
-- ---------------------------------------------------------------------
START TRANSACTION;

CALL sp_renombrar_id_modulo();

COMMIT;


-- ---------------------------------------------------------------------
-- 4) Limpieza (solo se llega aquí si el COMMIT anterior tuvo éxito).
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map;
DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo;


-- =====================================================================
-- Backup recomendado ANTES de ejecutar este script (ejecutar en shell,
-- no como parte de este .sql):
--
--   mysqldump -u <usuario> -p <base_de_datos> \
--     modulos ciclo_modulo imparte docente_modulo_ciclo \
--     > backup_modulos_$(date +%Y%m%d_%H%M%S).sql
--
-- Para deshacer manualmente tras un backup, restaura ese fichero:
--   mysql -u <usuario> -p <base_de_datos> < backup_modulos_YYYYMMDD_HHMMSS.sql
-- =====================================================================
