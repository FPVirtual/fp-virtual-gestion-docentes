<?php

use App\Models\Usuario;
use App\Models\Centro;

test('la página de alta de docente es accesible para usuarios con centro', function () {
    // 1. Creamos el centro con datos fijos
    $centro = Centro::create([
        'id_centro' => 1,
        'nombre' => 'Centro de Prueba',

    ]);

    // 2. Creamos el usuario vinculándolo al ID del centro que acabamos de crear
    $usuario = Usuario::factory()->create([
        'id_centro' => $centro->id_centro
    ]);

    // 3. Entramos en la web
    $response = $this->actingAs($usuario)->get('/alta-docente');

    $response->assertStatus(200);
});

test('el formulario de alta contiene los campos necesarios', function () {
    $usuario = Usuario::factory()->create();

    $response = $this->actingAs($usuario)->get('/alta-docente');

    // Comprobamos que en el HTML aparezcan palabras que seguro tienes en ese formulario
    $response->assertSee('DNI');
    $response->assertSee('Nombre');
});

test('la sección de administración de docentes carga bien', function () {
    $admin = Usuario::factory()->create();

    // Entramos en la ruta con el prefijo 'admin'
    $response = $this->actingAs($admin, 'admin')->get('/admin/docentes');

    $response->assertStatus(200);
});

test('el nombre del docente se normaliza correctamente', function () {
    $centro = Centro::forceCreate([
        'id_centro' => '999',
        'nombre' => 'Centro Test'
    ]);

    $usuario = Usuario::factory()->create([
        'id_centro' => '999',
    ]);


    // 1. Enviamos datos con minúsculas y puntos
    $datosDocente = [
        'nombre' => 'juan p',
        'apellido' => 'pérez g',
        'dni' => '12345678Z',
        'email' => 'test@example.com',
        'id_centro' => $centro->id_centro,
    ];

    // 2. Simulamos el envío del formulario al controlador
    $response = $this->actingAs($usuario)->post('/alta-docente', $datosDocente);


    $response->assertSessionHasNoErrors();

    // 3. Comprobamos en la base de datos que se ha guardado "limpio"
    $this->assertDatabaseHas('docentes', [
        'nombre' => 'Juan P',
        'apellido' => 'Pérez G',
    ]);
});
