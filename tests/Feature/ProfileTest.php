<?php

use App\Models\Usuario;

test('profile page is displayed', function () {
    $this->withoutVite();

    $user = Usuario::factory()->create();

    $response = $this
        ->actingAs($user)
        ->get('/profile');

    $response->assertOk();
});

test('profile email can be updated', function () {
    $user = Usuario::factory()->create();

    $response = $this
        ->actingAs($user)
        ->patch('/profile', [
            'email' => 'nuevo@example.com',
        ]);

    $response
        ->assertSessionHasNoErrors()
        ->assertRedirect('/profile');

    $user->refresh();

    $this->assertSame('nuevo@example.com', $user->email);
});

test('profile email must be unique', function () {
    Usuario::factory()->create(['email' => 'ocupado@example.com']);
    $user = Usuario::factory()->create();

    $response = $this
        ->actingAs($user)
        ->from('/profile')
        ->patch('/profile', [
            'email' => 'ocupado@example.com',
        ]);

    $response->assertSessionHasErrors('email');
});

test('user can delete their account', function () {
    $user = Usuario::factory()->create();

    $response = $this
        ->actingAs($user)
        ->delete('/profile', [
            'password' => 'password',
        ]);

    $response
        ->assertSessionHasNoErrors()
        ->assertRedirect('/');

    $this->assertGuest();
    $this->assertNull($user->fresh());
});

test('correct password must be provided to delete account', function () {
    $user = Usuario::factory()->create();

    $response = $this
        ->actingAs($user)
        ->from('/profile')
        ->delete('/profile', [
            'password' => 'wrong-password',
        ]);

    $response
        ->assertSessionHasErrorsIn('userDeletion', 'password')
        ->assertRedirect('/profile');

    $this->assertNotNull($user->fresh());
});
