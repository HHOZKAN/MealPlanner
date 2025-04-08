<?php

namespace App\Services;

use App\Services\Contracts\PriceScraperInterface;
use App\Services\Scrapers\CarrefourScraper;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class PriceScraperService implements PriceScraperInterface
{
    protected $carrefourScraper;
    protected $cacheMinutes = 60; // Cache d'une heure

    public function __construct(CarrefourScraper $carrefourScraper)
    {
        $this->carrefourScraper = $carrefourScraper;
    }

    public function searchPrice(string $productName): array
    {
        try {
            Log::info('Recherche de prix', ['product' => $productName]);

            $cacheKey = 'price_' . md5($productName);
            
            // Vérifier le cache
            if (Cache::has($cacheKey)) {
                Log::info('Prix trouvé dans le cache');
                return Cache::get($cacheKey);
            }

            $prices = [];

            // Carrefour
            $carrefourPrice = $this->carrefourScraper->scrape($productName);
            if ($carrefourPrice) {
                $prices[] = $carrefourPrice;
            }

            $result = [
                'prices' => $prices,
                'average' => count($prices) > 0 ? array_sum(array_column($prices, 'price')) / count($prices) : 0,
                'timestamp' => now()
            ];

            // Mettre en cache
            Cache::put($cacheKey, $result, now()->addMinutes($this->cacheMinutes));

            return $result;

        } catch (\Exception $e) {
            Log::error('Erreur dans searchPrice', [
                'product' => $productName,
                'error' => $e->getMessage()
            ]);
            return [
                'prices' => [],
                'average' => 0,
                'timestamp' => now()
            ];
        }
    }
}