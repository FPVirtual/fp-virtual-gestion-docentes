-- Solo lectura: comprueba si el renombrado (feoe-XX o el del CSV) ya se aplicó.

-- ¿Quedan códigos "feoe-XX" en modulos? (deberían ser 0 si el primer script se aplicó)
SELECT COUNT(*) AS feoe_restantes FROM modulos WHERE id_modulo LIKE 'feoe%';

-- ¿Existe ya el módulo 20309 (feoe-MI creado en el primer script)?
SELECT COUNT(*) AS existe_20309 FROM modulos WHERE id_modulo = '20309';

-- Para el CSV: ¿cuántos de los 217 códigos "SIGAD LOE" originales siguen existiendo tal cual?
-- (si el script ya se aplicó, este número debería ser 0 o muy bajo)
SELECT COUNT(*) AS loe_originales_restantes
FROM modulos
WHERE id_modulo IN (
    '5364','5114','5365','5368','5367','5119','5117','5120','5118','5297',
    '5194','5295','5296','5294','5101','5099','5100','5148','5149','7855'
    -- (muestra de los primeros 20 códigos de origen del CSV, suficiente para diagnosticar)
);

-- Y cuántos de los correspondientes códigos "SIGAD LFP" nuevos ya existen:
SELECT COUNT(*) AS lfp_nuevos_presentes
FROM modulos
WHERE id_modulo IN (
    '14634','14638','14644','14646','14649','14653','14659','14661','14667','14672',
    '14677','14683','14685','14687','14690','14692','14695','14697','14706','14711'
);
