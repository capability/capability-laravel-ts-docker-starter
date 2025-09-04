<?php
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

Route::get('/healthz', fn () => response()->json(['ok' => true]));
Route::get('/readyz', function () {
    DB::select('SELECT 1');
    try { Redis::connection()->ping(); } catch (\Throwable $e) {}
    return response()->json(['ready' => true]);
});
