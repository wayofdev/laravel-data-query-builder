<?php

declare(strict_types=1);

namespace WayOfDev\QueryBuilder\Bridge\Laravel\Providers;

use Illuminate\Support\ServiceProvider;

final class QueryBuilderServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__ . '/../../../../config/query-builder.php' => config_path('query-builder.php'),
            ], 'config');

            $this->registerConsoleCommands();
        }
    }

    public function register(): void
    {
        // @phpstan-ignore-next-line
        if (! $this->app->configurationIsCached()) {
            $this->mergeConfigFrom(
                __DIR__ . '/../../../../config/query-builder.php',
                'query-builder'
            );
        }
    }

    private function registerConsoleCommands(): void
    {
        $this->commands([]);
    }
}
