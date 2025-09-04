<?php

use Illuminate\Support\Facades\Route;

it('returns ok on /healthz', function () {
    $this->getJson('/api/healthz')->assertOk()->assertJson(['ok' => true]);
});

it('returns ready on /readyz', function () {
    $this->getJson('/api/readyz')->assertOk()->assertJson(['ready' => true]);
});

