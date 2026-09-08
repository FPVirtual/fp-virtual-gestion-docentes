-- Diagnóstico para codigos-viejos-y-nuevos-cursos-flc-mi.csv. Solo lectura.

DROP TEMPORARY TABLE IF EXISTS tmp_diag_flcmi;

CREATE TEMPORARY TABLE tmp_diag_flcmi (
    id_modulo_antiguo VARCHAR(50) NOT NULL PRIMARY KEY,
    id_modulo_nuevo   VARCHAR(50) NOT NULL,
    UNIQUE KEY uq_nuevo (id_modulo_nuevo)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

INSERT INTO tmp_diag_flcmi (id_modulo_antiguo, id_modulo_nuevo) VALUES
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

-- 1) Códigos de origen (grupo A, 18 pares) que NO existen en "modulos"
SELECT m.id_modulo_antiguo AS id_modulo_origen_faltante
FROM tmp_diag_flcmi m
LEFT JOIN modulos mo ON mo.id_modulo = m.id_modulo_antiguo
WHERE mo.id_modulo IS NULL
ORDER BY m.id_modulo_antiguo;

-- 2) Códigos de destino (grupo A) que YA existen en "modulos" (colisión)
SELECT m.id_modulo_antiguo AS origen, m.id_modulo_nuevo AS destino_ya_existente, mo.nombre
FROM tmp_diag_flcmi m
JOIN modulos mo ON mo.id_modulo = m.id_modulo_nuevo
ORDER BY m.id_modulo_nuevo;

-- 3) Caso especial 0019 -> 20309 (fusión): ¿existen ambos?
SELECT
    (SELECT COUNT(*) FROM modulos WHERE id_modulo = '0019')  AS existe_0019,
    (SELECT COUNT(*) FROM modulos WHERE id_modulo = '20309') AS existe_20309;

-- 4) Cuántas filas de cada tabla hija hay que fusionar de 0019 a 20309
SELECT
    (SELECT COUNT(*) FROM ciclo_modulo WHERE id_modulo = '0019')         AS en_ciclo_modulo,
    (SELECT COUNT(*) FROM imparte WHERE id_modulo = '0019')              AS en_imparte,
    (SELECT COUNT(*) FROM docente_modulo_ciclo WHERE id_modulo = '0019') AS en_docente_modulo_ciclo;

-- 5) Resumen general
SELECT
    (SELECT COUNT(*) FROM tmp_diag_flcmi) AS total_pares_grupo_a,
    (SELECT COUNT(*) FROM tmp_diag_flcmi m LEFT JOIN modulos mo ON mo.id_modulo = m.id_modulo_antiguo WHERE mo.id_modulo IS NULL) AS origenes_faltantes,
    (SELECT COUNT(*) FROM tmp_diag_flcmi m JOIN modulos mo ON mo.id_modulo = m.id_modulo_nuevo) AS destinos_colisionando;

DROP TEMPORARY TABLE IF EXISTS tmp_diag_flcmi;
