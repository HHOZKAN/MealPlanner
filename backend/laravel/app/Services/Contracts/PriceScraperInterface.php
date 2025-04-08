<?php

namespace App\Services\Contracts;

interface PriceScraperInterface
{
    public function searchPrice(string $productName): array;
}

