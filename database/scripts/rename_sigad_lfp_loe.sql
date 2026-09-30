-- =====================================================================
-- Script: Renombrado de id_modulo según "Relación IDs sigad cursos LFP y
-- LOE" (217 pares: código SIGAD LOE antiguo -> código SIGAD LFP nuevo)
-- Motor:  MySQL / MariaDB (InnoDB)
-- Tablas afectadas: modulos (PK), ciclo_modulo, imparte, docente_modulo_ciclo
--
-- Misma lógica y mismas comprobaciones de seguridad que el script de
-- feoe-XX: transacción única, comprobación previa de que todos los
-- códigos de origen existen y ninguno de destino existe ya, checks de
-- FK desactivados temporalmente (las FK no tienen ON UPDATE CASCADE) y
-- verificación de que no queden filas huérfanas antes del COMMIT.
--
-- IMPORTANTE: ejecuta antes "diagnostico_id_modulo_csv.sql" (solo
-- lectura) para comprobar que los 217 códigos de origen existen en
-- production y que ninguno de destino colisiona. Si el diagnóstico
-- encuentra algo, este script abortará solo (sin cambiar nada) y
-- habrá que decidir qué hacer con esos casos antes de reintentar,
-- igual que pasó con feoe-MI la vez anterior.
--
-- Uso recomendado:
--   1) Backup previo (ver comando al final de este fichero).
--   2) Ejecutar diagnostico_id_modulo_csv.sql y revisar que no haya
--      faltantes ni colisiones.
--   3) mysql -u <usuario> -p <base_de_datos> < rename_sigad_lfp_loe.sql
--   4) Revisar el mensaje final. Si aparece un error "Abortado: ..." no
--      se ha cambiado NADA (rollback automático); corrige la causa y
--      reintenta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) Procedimiento con toda la lógica y las comprobaciones de seguridad.
--    Se crea FUERA de la transacción porque CREATE/DROP PROCEDURE hacen
--    COMMIT implícito en MySQL/MariaDB.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo_sigad;

DELIMITER $$

CREATE PROCEDURE sp_renombrar_id_modulo_sigad()
proc: BEGIN
    DECLARE v_faltantes  INT DEFAULT 0;
    DECLARE v_colisiones INT DEFAULT 0;
    DECLARE v_huerfanos  INT DEFAULT 0;

    -- Comprobación 1: todos los id_modulo de origen deben existir en "modulos"
    SELECT COUNT(*) INTO v_faltantes
    FROM tmp_id_modulo_map_sigad m
    LEFT JOIN modulos mo ON mo.id_modulo = m.id_modulo_antiguo
    WHERE mo.id_modulo IS NULL;

    IF v_faltantes > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de origen que no existen en modulos (ejecuta el diagnostico para ver cuales)';
    END IF;

    -- Comprobación 2: ninguno de los id_modulo de destino debe existir ya
    SELECT COUNT(*) INTO v_colisiones
    FROM tmp_id_modulo_map_sigad m
    JOIN modulos mo ON mo.id_modulo = m.id_modulo_nuevo;

    IF v_colisiones > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Abortado: hay id_modulo de destino que ya existen en modulos (ejecuta el diagnostico para ver cuales)';
    END IF;

    -- Desactivamos temporalmente los checks de FK (las FK no tienen
    -- ON UPDATE CASCADE, así que necesitamos actualizar padre e hijas
    -- de forma coordinada sin que cada UPDATE individual falle).
    SET FOREIGN_KEY_CHECKS = 0;

    UPDATE ciclo_modulo cm
    JOIN tmp_id_modulo_map_sigad m ON m.id_modulo_antiguo = cm.id_modulo
    SET cm.id_modulo = m.id_modulo_nuevo;

    UPDATE imparte i
    JOIN tmp_id_modulo_map_sigad m ON m.id_modulo_antiguo = i.id_modulo
    SET i.id_modulo = m.id_modulo_nuevo;

    UPDATE docente_modulo_ciclo d
    JOIN tmp_id_modulo_map_sigad m ON m.id_modulo_antiguo = d.id_modulo
    SET d.id_modulo = m.id_modulo_nuevo;

    UPDATE modulos mo
    JOIN tmp_id_modulo_map_sigad m ON m.id_modulo_antiguo = mo.id_modulo
    SET mo.id_modulo = m.id_modulo_nuevo;

    SET FOREIGN_KEY_CHECKS = 1;

    -- Comprobación 3: no debe quedar ninguna fila huérfana en las tablas hijas
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

    SELECT 'OK: 217 codigos id_modulo actualizados segun Relacion IDs sigad cursos LFP y LOE' AS resultado;
END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- 2) Tabla temporal con el mapeo antiguo -> nuevo (217 pares, extraídos
--    literalmente de "Relación IDs sigad cursos LFP y LOE - Hoja 1.csv").
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map_sigad;

CREATE TEMPORARY TABLE tmp_id_modulo_map_sigad (
    id_modulo_antiguo VARCHAR(50) NOT NULL PRIMARY KEY,
    id_modulo_nuevo   VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_nuevo (id_modulo_nuevo)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

INSERT INTO tmp_id_modulo_map_sigad (id_modulo_antiguo, id_modulo_nuevo) VALUES
('5364', '14634'),
('5114', '14638'),
('5365', '14644'),
('5368', '14646'),
('5367', '14649'),
('5119', '14653'),
('5117', '14659'),
('5120', '14661'),
('5118', '14667'),
('5297', '14672'),
('5194', '14677'),
('5295', '14683'),
('5296', '14685'),
('5294', '14687'),
('5101', '14690'),
('5099', '14692'),
('5100', '14695'),
('5148', '14697'),
('5149', '14706'),
('7855', '14711'),
('7851', '14715'),
('7853', '14721'),
('7854', '14723'),
('7852', '14725'),
('7871', '14728'),
('7870', '14734'),
('7869', '14737'),
('7863', '14741'),
('5349', '16691'),
('5347', '16699'),
('5351', '16701'),
('5348', '16703'),
('4995', '16708'),
('4993', '16717'),
('4994', '16720'),
('4991', '16722'),
('13948', '15333'),
('13947', '15337'),
('13945', '15340'),
('13943', '15346'),
('13942', '15348'),
('13954', '15352'),
('13952', '15354'),
('13951', '15362'),
('13950', '15367'),
('13949', '15371'),
('5409', '15375'),
('5407', '15377'),
('5408', '15384'),
('5406', '15386'),
('5163', '15388'),
('5161', '15390'),
('5159', '15394'),
('5162', '15396'),
('5160', '15401'),
('5158', '15405'),
('7909', '15411'),
('7926', '15416'),
('7908', '15420'),
('7907', '15422'),
('7917', '15424'),
('7918', '15426'),
('7910', '15430'),
('7925', '15432'),
('7919', '15437'),
('7920', '15443'),
('5426', '15447'),
('5422', '15449'),
('5424', '15456'),
('5421', '15459'),
('5198', '15461'),
('5195', '15463'),
('5200', '15467'),
('5203', '15472'),
('5202', '15475'),
('5180', '16803'),
('5182', '16807'),
('5178', '16813'),
('5181', '16815'),
('5179', '16817'),
('5083', '16820'),
('5084', '16822'),
('5085', '16824'),
('5086', '16827'),
('7929', '17355'),
('7930', '17357'),
('7933', '17359'),
('7935', '17361'),
('7950', '17363'),
('7945', '17365'),
('7948', '17367'),
('7946', '17369'),
('5256', '17879'),
('5259', '17883'),
('5260', '17885'),
('5255', '17891'),
('5031', '17894'),
('5036', '17896'),
('5035', '17898'),
('5032', '17900'),
('5335', '15562'),
('12359', '15566'),
('5337', '15569'),
('5338', '15573'),
('4981', '15579'),
('4980', '15582'),
('4982', '15584'),
('12360', '15586'),
('4984', '15590'),
('12339', '18381'),
('12338', '18383'),
('12342', '18389'),
('12343', '18391'),
('12344', '18393'),
('12345', '18395'),
('12346', '18397'),
('12347', '18399'),
('12350', '18401'),
('12353', '18411'),
('5456', '16460'),
('5463', '16464'),
('5447', '16466'),
('5223', '16472'),
('5457', '16474'),
('5236', '16476'),
('5224', '16480'),
('5228', '16486'),
('5237', '16490'),
('5274', '16730'),
('5275', '16732'),
('5272', '16735'),
('5276', '16741'),
('5273', '16743'),
('5054', '16745'),
('5051', '16747'),
('5053', '16750'),
('5055', '16758'),
('5052', '16760'),
('5290', '16764'),
('5293', '16769'),
('5288', '16775'),
('5291', '16777'),
('5289', '16779'),
('5066', '16782'),
('5068', '16784'),
('5070', '16791'),
('5069', '16794'),
('5071', '16798'),
('13932', '15756'),
('13929', '15760'),
('13926', '15762'),
('13936', '15768'),
('13930', '15770'),
('13928', '15772'),
('13937', '15780'),
('13935', '15782'),
('13940', '15784'),
('13933', '15788'),
('5324', '17981'),
('5327', '17985'),
('5325', '17987'),
('5326', '17993'),
('5329', '17995'),
('5323', '17998'),
('4969', '18002'),
('4971', '18004'),
('4972', '18011'),
('5319', '18019'),
('5316', '18021'),
('5313', '18023'),
('5312', '18027'),
('5315', '18029'),
('5310', '18036'),
('4955', '18040'),
('4952', '18044'),
('4958', '18048'),
('4959', '18054'),
('5382', '18494'),
('5379', '18496'),
('5378', '18498'),
('5125', '18500'),
('5375', '18508'),
('5128', '18512'),
('5381', '18514'),
('5131', '18516'),
('5124', '18522'),
('5135', '18528'),
('5433', '18586'),
('5436', '18588'),
('5432', '18591'),
('5213', '18595'),
('5441', '18601'),
('5212', '18603'),
('5434', '18606'),
('5210', '18608'),
('5214', '18611'),
('7874', '18621'),
('7899', '18625'),
('7875', '18629'),
('7897', '18633'),
('7882', '18635'),
('7879', '18637'),
('7878', '18639'),
('7892', '18641'),
('7877', '18645'),
('7896', '18651'),
('14342', '19108'),
('14340', '19110'),
('14343', '19112'),
('14339', '19114'),
('14344', '19116'),
('14341', '19118'),
('14347', '19120'),
('14345', '19122'),
('14349', '19124'),
('14348', '19126'),
('14346', '19128');


-- ---------------------------------------------------------------------
-- 3) Ejecución dentro de una transacción explícita.
-- ---------------------------------------------------------------------
START TRANSACTION;

CALL sp_renombrar_id_modulo_sigad();

COMMIT;


-- ---------------------------------------------------------------------
-- 4) Limpieza (solo se llega aquí si el COMMIT anterior tuvo éxito).
-- ---------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_id_modulo_map_sigad;
DROP PROCEDURE IF EXISTS sp_renombrar_id_modulo_sigad;


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
