<?php

use App\Models\Usuario;
use App\Models\Centro;
use App\Models\Docente;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

/** 1. ACCESIBILIDAD */
test('la página de alta de docente es accesible para usuarios autenticados', function () {
    $centro = Centro::forceCreate(['id_centro' => 'C100', 'nombre' => 'Centro Test']);
    $usuario = Usuario::factory()->create(['id_centro' => 'C100']);
    $response = $this->actingAs($usuario)->get('/alta-docente');
    $response->assertStatus(200);
});

/** 2. NORMALIZACIÓN DE NOMBRE */
test('el nombre y apellido se guardan con la primera letra en mayúscula', function () {
    $centro = Centro::forceCreate(['id_centro' => 'C200', 'nombre' => 'Centro Test']);
    $usuario = Usuario::factory()->create(['id_centro' => 'C200']);
    $datos = [
        'nombre' => 'juan ignacio', 'apellido' => 'pérez de la o',
        'dni' => '12345678Z', 'email' => 'j@t.com', 'email_virtual' => 'j@v.com', 'id_centro' => 'C200'
    ];
    $this->actingAs($usuario)->post('/alta-docente', $datos);
    $this->assertDatabaseHas('docentes', ['dni' => '12345678Z', 'nombre' => 'Juan Ignacio', 'apellido' => 'Pérez De La O']);
});

/** 3. NORMALIZACIÓN DE DNI */
test('el DNI se guarda siempre en mayúsculas aunque se introduzca en minúsculas', function () {
    $centro = Centro::forceCreate(['id_centro' => 'C300', 'nombre' => 'Centro Test']);
    $usuario = Usuario::factory()->create(['id_centro' => 'C300']);
    $datos = [
        'nombre' => 'Test', 'apellido' => 'Mayus',
        'dni' => '87654321s',
        'email' => 'm@t.com', 'email_virtual' => 'm@v.com', 'id_centro' => 'C300'
    ];
    $this->actingAs($usuario)->post('/alta-docente', $datos);
    $this->assertDatabaseHas('docentes', ['dni' => '87654321S']);
});

/** 4. VALIDACIÓN DNI DUPLICADO */
test('no se permite registrar dos docentes con el mismo DNI', function () {
    $centro = Centro::forceCreate(['id_centro' => 'C400', 'nombre' => 'Centro Test']);
    $usuario = Usuario::factory()->create(['id_centro' => 'C400']);
    Docente::forceCreate(['nombre' => 'O', 'apellido' => 'E', 'dni' => '99999999R', 'email_virtual' => 'o@v.com']);
    $datos = [
        'nombre' => 'I', 'apellido' => 'D', 'dni' => '99999999R',
        'email' => 'i@t.com', 'email_virtual' => 'i@v.com', 'id_centro' => 'C400'
    ];
    $response = $this->actingAs($usuario)->post('/alta-docente', $datos);
    $response->assertSessionHasErrors(['dni']);
});

/** 5. BAJA DE DOCENTE */
test('se puede dar de baja a un docente activo', function () {
    $centro = Centro::forceCreate(['id_centro' => 'C500', 'nombre' => 'C']);
    $usuario = Usuario::factory()->create(['id_centro' => 'C500']);
    $docente = Docente::forceCreate(['nombre' => 'B', 'apellido' => 'T', 'dni' => '00000000T', 'email_virtual' => 't@v.com', 'de_baja' => 0]);
    $this->actingAs($usuario)->post("/docentes/baja/{$docente->dni}");
    $this->assertDatabaseHas('docentes', ['dni' => '00000000T', 'de_baja' => 1]);
});

/** 6. REACTIVACIÓN */
test('se puede reactivar a un docente que estaba dado de baja', function () {
    $centro = Centro::forceCreate(['id_centro' => 'C600', 'nombre' => 'C']);
    $usuario = Usuario::factory()->create(['id_centro' => 'C600']);
    $docente = Docente::forceCreate(['nombre' => 'R', 'apellido' => 'T', 'dni' => '11111111A', 'email_virtual' => 'r@v.com', 'de_baja' => 1]);

    $this->actingAs($usuario)->post("/docentes/reactivar/{$docente->dni}");

    $this->assertDatabaseHas('docentes', ['dni' => '11111111A', 'de_baja' => 0]);
});
