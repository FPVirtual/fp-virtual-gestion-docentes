<?php

use App\Models\Usuario;

test('login screen can be rendered', function () {
    $this->withoutVite();

    $response = $this->get('/login');

    $response->assertStatus(200);
});

test('users can authenticate using the login screen', function () {
    $user = Usuario::factory()->create();

    $response = $this->post('/login', [
        'nombre' => $user->nombre,
        'password' => 'password',
    ]);

    $this->assertAuthenticated();
    $response->assertRedirect(route('dashboard', absolute: false));
});

test('users can not authenticate with invalid password', function () {
    $user = Usuario::factory()->create();

    $this->post('/login', [
        'nombre' => $user->nombre,
        'password' => 'wrong-password',
    ]);

    $this->assertGuest();
});

test('users can logout', function () {
    $user = Usuario::factory()->create();

    $response = $this->actingAs($user)->post('/logout');

    $this->assertGuest();
    $response->assertRedirect('/');
});
