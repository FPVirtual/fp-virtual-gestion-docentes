<?php

use App\Models\Centro;
use App\Models\Usuario;

test('un docente se crea con el nombre y apellido normalizados', function () {
    $centro = Centro::forceCreate(['id_centro' => 'CT01', 'nombre' => 'Centro Test']);
    $usuario = Usuario::factory()->create(['id_centro' => 'CT01']);

    // Preparamos los datos con los símbolos que queremos que limpie
    $datos = [
        'dni' => '12345678Z',
        'nombre' => 'mario.',     // Con punto
        'apellido' => 'marioº',   // Con símbolo de grado
        'email' => 'mario@test.com',
        'id_centro' => 'CT01',
    ];

    $response = $this->actingAs($usuario)->post('/alta-docente', $datos);

    // Verificamos que en la base de datos se haya guardado limpio
    $this->assertDatabaseHas('docentes', [
        'dni' => '12345678Z',
        'nombre' => 'Mario',    // El punto desapareció y puso mayúscula
        'apellido' => 'Mario',  // El º desapareció
    ]);
});
