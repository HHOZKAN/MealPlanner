<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use App\Traits\ApiResponse;

class PriceController extends Controller
{
    use ApiResponse;

    /**
     * Ajouter un nouveau prix
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'product_name' => 'required|string|max:255',
                'price' => 'required|numeric|min:0',
                'store_name' => 'nullable|string|max:255',
                'receipt_image' => 'nullable|image|max:5120', // 5MB max
                'notes' => 'nullable|string'
            ]);

            // Gérer l'upload de l'image du ticket
            if ($request->hasFile('receipt_image')) {
                $path = $request->file('receipt_image')->store('receipts', 'public');
                $validated['receipt_image'] = $path;
            }

            $price = 

            return $this->successResponse(
                $price->load('user'),
                'Prix ajouté avec succès'
            );

        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de l\'ajout du prix', 500);
        }
    }

    /**
     * Obtenir l'historique des prix pour un produit
     */
    public function history(Request $request)
    {
        try {
            $validated = $request->validate([
                'product_name' => 'required|string'
            ]);

            $prices = 

            $stats = [
                'average' => $prices->flatten()->avg('price'),
                'min' => $prices->flatten()->min('price'),
                'max' => $prices->flatten()->max('price'),
                'count' => $prices->flatten()->count(),
            ];

            return $this->successResponse([
                'prices' => $prices,
                'stats' => $stats
            ], 'Historique des prix récupéré avec succès');

        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la récupération de l\'historique', 500);
        }
    }

    /**
     * Obtenir les statistiques de prix par magasin
     */
    public function storeStats(Request $request)
    {
        try {
            $validated = $request->validate([
                'product_name' => 'required|string'
            ]);

            $stats = 
                });

            return $this->successResponse($stats, 'Statistiques récupérées avec succès');

        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la récupération des statistiques', 500);
        }
    }
}