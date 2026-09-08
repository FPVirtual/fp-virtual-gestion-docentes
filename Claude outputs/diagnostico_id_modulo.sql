-- Diagnóstico: ¿qué códigos feoe-XX del mapeo NO existen tal cual en "modulos"?
-- Solo lectura, no modifica nada.

SELECT origen.id_modulo_esperado
FROM (
    SELECT 'feoe-AC'   AS id_modulo_esperado UNION ALL
    SELECT 'feoe-AD'   UNION ALL
    SELECT 'feoe-AF'   UNION ALL
    SELECT 'feoe-APSD' UNION ALL
    SELECT 'feoe-ASIR' UNION ALL
    SELECT 'feoe-AVGE' UNION ALL
    SELECT 'feoe-CI'   UNION ALL
    SELECT 'feoe-DAM'  UNION ALL
    SELECT 'feoe-DAW'  UNION ALL
    SELECT 'feoe-ECA'  UNION ALL
    SELECT 'feoe-EI'   UNION ALL
    SELECT 'feoe-ES'   UNION ALL
    SELECT 'feoe-FP'   UNION ALL
    SELECT 'feoe-GA'   UNION ALL
    SELECT 'feoe-GVEC' UNION ALL
    SELECT 'feoe-IEA'  UNION ALL
    SELECT 'feoe-IS'   UNION ALL
    SELECT 'feoe-LACC' UNION ALL
    SELECT 'feoe-MI'   UNION ALL
    SELECT 'feoe-PAE'  UNION ALL
    SELECT 'feoe-SMR'  UNION ALL
    SELECT 'feoe-STI'  UNION ALL
    SELECT 'feoe-TL'
) AS origen
LEFT JOIN modulos mo ON mo.id_modulo = origen.id_modulo_esperado
WHERE mo.id_modulo IS NULL;

-- Para comparar, esto muestra TODOS los id_modulo que empiezan por "feoe"
-- realmente presentes en producción (por si hay mayúsculas/espacios distintos):
SELECT id_modulo, nombre
FROM modulos
WHERE id_modulo LIKE 'feoe%' OR id_modulo LIKE 'FEOE%' OR id_modulo LIKE '%feoe%'
ORDER BY id_modulo;
