<?php

namespace App\Providers;

use App\Services\Contracts\PriceScraperInterface;
use App\Services\PriceScraperService;
use App\Services\Scrapers\CarrefourScraper;
use App\Services\Scrapers\LeclercScraper;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register()
    {
        $this->app->singleton(LeclercScraper::class, function ($app) {
            return new LeclercScraper();
        });
    
        $this->app->singleton(PriceScraperInterface::class, PriceScraperService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
