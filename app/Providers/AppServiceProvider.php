<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Modo sin base de datos: si no hay DB_CONNECTION definido en runtime
        if (empty(env('DB_CONNECTION'))) {
            // Forzar drivers in-memory / stateless para evitar intentos de conectar
            config([
                'session.driver' => 'cookie',
                'cache.default' => 'array',
                'queue.default' => 'sync',
                'database.default' => 'pgsql', // valor neutro que no se usa porque no accedemos a DB
            ]);
        }
    }
}
