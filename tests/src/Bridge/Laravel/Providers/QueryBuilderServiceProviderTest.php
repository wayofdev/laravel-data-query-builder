<?php

declare(strict_types=1);

namespace WayOfDev\Tests\Bridge\Laravel\Providers;

use PHPUnit\Framework\Attributes\Test;
use WayOfDev\QueryBuilder\Bridge\Laravel\Providers\QueryBuilderServiceProvider;
use WayOfDev\Tests\TestCase;

class QueryBuilderServiceProviderTest extends TestCase
{
    #[Test]
    public function it_publishes_configuration(): void
    {
        $this->artisan('vendor:publish', [
            '--provider' => QueryBuilderServiceProvider::class,
        ])->assertExitCode(0);

        $this::assertFileExists(config_path('package.php'));
    }
}
