<?php 

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckTokenExpiration
{
    public function handle(Request $request, Closure $next)
    {
        if ($request->user() && $request->user()->tokenCan('*')) {
            $token = $request->user()->currentAccessToken();
            
            if ($token->created_at->addDays(7) < now()) {
                $token->delete();
                return response()->json([
                    'status' => 'error',
                    'message' => 'Token expiré'
                ], 401);
            }
        }

        return $next($request);
    }
}

?>