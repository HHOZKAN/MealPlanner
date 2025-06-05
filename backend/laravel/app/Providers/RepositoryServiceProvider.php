<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Contracts\Repositories\EventRepositoryInterface;
use App\Repositories\EventRepository;
use App\Contracts\Services\InvitationServiceInterface;
use App\Services\Invitation\InvitationService;

class RepositoryServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Repositories
        $this->app->bind(EventRepositoryInterface::class, EventRepository::class);

        // Services
        $this->app->bind(InvitationServiceInterface::class, InvitationService::class);
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        //
    }
}
