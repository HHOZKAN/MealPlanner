<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request;

class Authenticate extends Middleware
{
    protected function redirectTo(Request $request): ?string
    {
        if ($request->expectsJson()) {
            abort(response()->json([
                'status' => 'error',
                'message' => 'Non authentifié. Veuillez vous connecter.'
            ], 401));
        }
        return null;
    }

    protected function unauthenticated($request, array $guards)
    {
        abort(response()->json([
            'status' => 'error',
            'message' => 'Non authentifié. Veuillez vous connecter.'
        ], 401));
    }
}