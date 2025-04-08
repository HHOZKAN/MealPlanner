<?php

namespace App\Services\Scrapers;

use GuzzleHttp\Client;
use Symfony\Component\DomCrawler\Crawler;
use Illuminate\Support\Facades\Log;
use GuzzleHttp\Exception\RequestException;

class CarrefourScraper
{
    protected $client;
    protected $baseUrl = 'https://www.carrefour.fr';

    public function __construct()
    {
        $this->client = new Client([
            'timeout' => 30,
            'verify' => false, // Pour le développement uniquement
            'headers' => [
                'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language' => 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
                'Cache-Control' => 'no-cache',
                'Pragma' => 'no-cache',
            ]
        ]);
    }

    public function scrape(string $productName): ?array
    {
        try {
            Log::info('Début du scraping Carrefour', ['product' => $productName]);

            // Construire l'URL de recherche
            $searchUrl = $this->baseUrl . '/s?' . http_build_query([
                'q' => $productName
            ]);

            Log::info('URL de recherche', ['url' => $searchUrl]);

            // Faire la requête
            $response = $this->client->get($searchUrl);
            $html = $response->getBody()->getContents();

            // Parser le HTML
            $crawler = new Crawler($html);

            // Récupérer les résultats
            $products = [];
            
            // Adapter les sélecteurs selon la structure réelle du site
            $crawler->filter('.product-grid-item')->each(function (Crawler $node) use (&$products) {
                try {
                    $name = $node->filter('.product-name')->text();
                    $priceText = $node->filter('.product-price')->text();
                    $url = $node->filter('a')->attr('href');
                    
                    // Nettoyer le prix
                    $price = $this->cleanPrice($priceText);

                    if ($price > 0) {
                        $products[] = [
                            'name' => trim($name),
                            'price' => $price,
                            'url' => $this->baseUrl . $url,
                        ];
                    }
                } catch (\Exception $e) {
                    Log::warning('Erreur lors du parsing d\'un produit', [
                        'error' => $e->getMessage()
                    ]);
                }
            });

            // Si des produits ont été trouvés
            if (!empty($products)) {
                // Prendre le premier résultat pertinent
                $bestMatch = $this->findBestMatch($products, $productName);
                
                return [
                    'store_name' => 'Carrefour',
                    'price' => $bestMatch['price'],
                    'url' => $bestMatch['url'],
                    'product_name' => $bestMatch['name'],
                    'fetched_at' => now()
                ];
            }

            Log::info('Aucun produit trouvé');
            return null;

        } catch (RequestException $e) {
            Log::error('Erreur de requête HTTP', [
                'url' => $searchUrl ?? 'unknown',
                'error' => $e->getMessage(),
                'response' => $e->hasResponse() ? $e->getResponse()->getBody()->getContents() : null
            ]);
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur dans CarrefourScraper', [
                'product' => $productName,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return null;
        }
    }

    protected function cleanPrice(string $price): float
    {
        // Nettoyer le texte du prix
        $price = preg_replace('/[^0-9,.]/', '', $price);
        $price = str_replace(',', '.', $price);
        return (float) $price;
    }

    protected function findBestMatch(array $products, string $searchTerm): array
    {
        $searchTerm = strtolower($searchTerm);
        $bestMatch = null;
        $bestScore = -1;

        foreach ($products as $product) {
            $productName = strtolower($product['name']);
            
            // Calcul simple de pertinence
            $score = 0;
            if (str_contains($productName, $searchTerm)) {
                $score += 2;
            }
            foreach (explode(' ', $searchTerm) as $word) {
                if (str_contains($productName, $word)) {
                    $score += 1;
                }
            }

            if ($score > $bestScore) {
                $bestScore = $score;
                $bestMatch = $product;
            }
        }

        return $bestMatch ?? $products[0];
    }
}