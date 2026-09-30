<?php

it('redirects guests from / to the login page', function () {
    $response = $this->get('/');

    $response->assertRedirect('/login');
});
