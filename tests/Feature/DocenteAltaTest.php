<?php


test('un docente se crea con el nombre y apellido normalizados', function () {
    $this->withoutExceptionHandling();
    // 1. Preparamos los datos con los símbolos que queremos que limpie
    $datos = [
        'dni' => '12345678Z',
        'nombre' => 'mario.',     // Con punto
        'apellido' => 'marioº',   // Con símbolo de grado
        'email' => 'mario@test.com',
        'id_centro' => 1
    ];

    // 2. Simulamos que enviamos el formulario
    // Asegúrate de que '/docentes/guardar' sea la ruta real de tu formulario
    $response = $this->post('/docentes/guardar', $datos);

    // 3. Verificamos que en la base de datos se haya guardado limpio
    $this->assertDatabaseHas('docentes', [
        'dni' => '12345678Z',
        'nombre' => 'Mario',    // Comprobamos que el punto desapareció y puso mayúscula
        'apellido' => 'Mario',  // Comprobamos que el º desapareció
    ]);
});
