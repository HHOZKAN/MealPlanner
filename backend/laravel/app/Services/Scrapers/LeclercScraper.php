<?php

namespace App\Services\Scrapers;

use GuzzleHttp\Client;
use Symfony\Component\DomCrawler\Crawler;
use Illuminate\Support\Facades\Log;
use GuzzleHttp\Exception\RequestException;

class LeclercScraper
{
    protected $client;
    protected $baseUrl = 'https://fd8-courses.leclercdrive.fr';

    public function __construct()
    {
        $this->client = new Client([
            'timeout' => 30,
            'verify'  => false,
            'headers' => [
                'User-Agent'      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                'Accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
                'Accept-Language' => 'fr-FR,fr;q=0.9',
                'Cache-Control'   => 'no-cache',
            ],
        ]);
    }

    /**
     * Scrape les détails d'une page produit Leclerc Drive.
     *
     * @param string $productUrl URL complète de la page produit
     * @return array|null Retourne un tableau contenant les informations extraites ou null en cas d'erreur
     */
    public function scrapeProduct(string $productUrl): ?array
    {
        try {
            Log::info('Début du scraping de la page produit', [
                'url'       => $productUrl,
                'timestamp' => now(),
            ]);

            $response = $this->client->get($productUrl);
            $html = $response->getBody()->getContents();

            Log::debug('HTML reçu', ['html' => substr($html, 0, 500) . '...']);

            $crawler = new Crawler($html);

            // Extraction du titre du produit
            // Exemple : un h1 peut contenir le titre ; à adapter selon le HTML réel
            $title = trim($crawler->filter('h1')->text(''));

            // Extraction du prix
            // Le prix peut être dans un span avec une classe comme .prix ou .product-price
            $priceText = '';
            try {
                $priceText = $crawler->filter('.prix')->text();
            } catch (\Exception $e) {
                try {
                    $priceText = $crawler->filter('.product-price')->text();
                } catch (\Exception $ex) {
                    Log::warning('Prix non trouvé', ['error' => $ex->getMessage()]);
                }
            }
            $price = $this->cleanPrice($priceText);

            // Extraction de l'image principale du produit
            $imageUrl = '';
            try {
                // L'image peut être en lazy load via data-src ou directement dans src
                $imageUrl = $crawler->filter('.product-main-image img')->attr('data-src');
                if (empty($imageUrl)) {
                    $imageUrl = $crawler->filter('.product-main-image img')->attr('src');
                }
            } catch (\Exception $e) {
                Log::warning('Image non trouvée', ['error' => $e->getMessage()]);
            }

            // Extraction d'une description éventuelle
            $description = '';
            try {
                $description = trim($crawler->filter('.product-description')->text());
            } catch (\Exception $e) {
                // Pas de description trouvée, pas d'inquiétude
            }

            return [
                'title'       => $title,
                'price'       => $price,
                'image_url'   => $imageUrl,
                'description' => $description,
                'fetched_at'  => now(),
            ];
        } catch (RequestException $e) {
            Log::error('Erreur de requête HTTP', [
                'url'   => $productUrl,
                'error' => $e->getMessage(),
            ]);
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur lors du scraping de la page produit', [
                'url'   => $productUrl,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Nettoie une chaîne de caractères pour en extraire un prix sous forme de float.
     *
     * @param string $price Chaîne contenant le prix
     * @return float
     */
    protected function cleanPrice(string $price): float
    {
        // Conserver uniquement les chiffres et les séparateurs
        $price = preg_replace('/[^0-9,\.]/', '', $price);
        $price = str_replace(',', '.', $price);
        return (float) $price;
    }
}
