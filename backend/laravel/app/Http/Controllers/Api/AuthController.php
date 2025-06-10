<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    use ApiResponse;

    public function register(Request $request)
    {
        try {
            Log::info('Début de l\'inscription', ['email' => $request->email]);

            $validator = Validator::make($request->all(), [
                'name' => ['required', 'string', 'max:255'],
                'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
                'password' => [
                    'required',
                    'confirmed',
                    Rules\Password::min(8)
                        ->mixedCase()
                        ->numbers()
                        ->symbols()
                        ->uncompromised()
                ],
                'phone_number' => ['nullable', 'string', 'max:20', 'regex:/^([0-9\s\-\+\(\)]*)$/'],
                'event_id' => ['nullable', 'integer', 'exists:events,id'],
                'token' => ['nullable', 'string'],
            ], [
                'name.required' => 'Le nom est obligatoire',
                'email.required' => 'L\'email est obligatoire',
                'email.email' => 'L\'email n\'est pas valide',
                'email.unique' => 'Cet email est déjà utilisé',
                'password.required' => 'Le mot de passe est obligatoire',
                'password.confirmed' => 'Les mots de passe ne correspondent pas',
                'phone_number.regex' => 'Le numéro de téléphone n\'est pas valide',
            ]);

            if ($validator->fails()) {
                Log::warning('Validation échouée', ['errors' => $validator->errors()->toArray()]);
                return response()->json([
                    'status' => 'error',
                    'message' => $validator->errors()->first(),
                    'errors' => $validator->errors()
                ], 422);
            }

            DB::beginTransaction();
            try {
                $user = User::create([
                    'name' => $request->name,
                    'email' => $request->email,
                    'password' => Hash::make($request->password),
                    'phone_number' => $request->phone_number,
                    'preferences' => [],
                ]);

                event(new Registered($user));

                $token = $user->createToken('auth_token')->plainTextToken;

                // If token and event_id are provided, accept the invitation
                if ($request->filled('token') && $request->filled('event_id')) {
                    // Manually set the authenticated user for the request
                    \Illuminate\Support\Facades\Auth::login($user);
                    $invitationService = new \App\Services\InvitationService();
                    $invitationService->acceptInvitation($request->input('token'));
                }

                DB::commit();

        return response()->json([
            'status' => 'success',
            'message' => 'Inscription réussie',
            'data' => [
                'user' => $this->sanitizeForJson($user),
                'token' => $token
            ]
        ], 201, [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            } catch (\Exception $e) {
                DB::rollBack();
                Log::error('Erreur lors de la création de l\'utilisateur', [
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                throw $e;
            }
        } catch (\Exception $e) {
            Log::error('Exception lors de l\'inscription', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Une erreur est survenue lors de l\'inscription',
                'debug' => config('app.debug') ? [
                    'message' => $e->getMessage(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine()
                ] : null
            ], 500);
        }
    }

    /**
     * Login user
     */
    public function login(Request $request)
{
    try {
        Log::info('Tentative de connexion', ['email' => $request->email]);
        
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            Log::warning('Validation échouée', ['errors' => $validator->errors()->toArray()]);
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first(),
                'errors' => $validator->errors()
            ], 422);
        }

        // Vérifier si l'utilisateur existe
        $user = User::where('email', $request->email)->first();
        
        if (!$user) {
            Log::warning('Utilisateur non trouvé', ['email' => $request->email]);
            return response()->json([
                'status' => 'error',
                'message' => 'Identifiants incorrects'
            ], 401);
        }

        // Vérifier le mot de passe
        if (!Hash::check($request->password, $user->password)) {
            Log::warning('Mot de passe incorrect', ['email' => $request->email]);
            return response()->json([
                'status' => 'error',
                'message' => 'Identifiants incorrects'
            ], 401);
        }

        // Supprimer les anciens tokens
        $user->tokens()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;
        
        Log::info('Connexion réussie', ['email' => $request->email, 'user_id' => $user->id]);

        return response()->json([
            'status' => 'success',
            'message' => 'Connexion réussie',
            'data' => [
                'user' => $this->sanitizeForJson($user),
                'token' => $token
            ]
        ], 200, [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

    } catch (\Exception $e) {
        Log::error('Erreur lors de la connexion', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        return response()->json([
            'status' => 'error',
            'message' => 'Une erreur est survenue lors de la connexion',
            'debug' => config('app.debug') ? $e->getMessage() : null
        ], 500);
    }
}
    /**
     * Logout user
     */
    public function logout(Request $request)
    {
        try {
            if ($request->user()) {
                $request->user()->tokens()->delete();

                return response()->json([
                    'status' => 'success',
                    'message' => 'Déconnexion réussie'
                ]);
            }

            return response()->json([
                'status' => 'error',
                'message' => 'Non authentifié'
            ], 401);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Une erreur est survenue lors de la déconnexion',
                'debug' => config('app.debug') ? $e->getMessage() : null
            ], 500);
        }
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request)
    {
        try {
            return $this->successResponse($request->user());
        } catch (\Exception $e) {
            return $this->errorResponse('Une erreur est survenue', 500);
        }
    }

    /**
     * Update user profile
     */
    public function updateProfile(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => ['sometimes', 'string', 'max:255'],
                'phone_number' => ['sometimes', 'string', 'max:20', 'regex:/^([0-9\s\-\+\(\)]*)$/'],
                'avatar' => ['sometimes', 'image', 'max:1024', 'mimes:jpeg,png,jpg,gif'],
            ], [
                'name.string' => 'Le nom doit être une chaîne de caractères',
                'phone_number.regex' => 'Le numéro de téléphone n\'est pas valide',
                'avatar.image' => 'Le fichier doit être une image',
                'avatar.max' => 'L\'image ne doit pas dépasser 1Mo',
                'avatar.mimes' => 'L\'image doit être au format jpeg, png, jpg ou gif',
            ]);

            if ($validator->fails()) {
                return $this->errorResponse($validator->errors()->first(), 422);
            }

            $user = $request->user();

            if ($request->hasFile('avatar')) {
                // Supprimer l'ancien avatar s'il existe
                if ($user->avatar) {
                    Storage::disk('public')->delete($user->avatar);
                }

                $path = $request->file('avatar')->store('avatars', 'public');
                $user->avatar = $path;
            }

            $user->fill($request->only(['name', 'phone_number']));
            $user->save();

            return $this->successResponse([
                'user' => $this->sanitizeForJson($user)
            ], 'Profil mis à jour avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Une erreur est survenue lors de la mise à jour du profil', 500);
        }
    }

    /**
     * Change password
     */
    public function changePassword(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'current_password' => ['required', 'string'],
                'password' => [
                    'required',
                    'confirmed',
                    Rules\Password::min(8)
                        ->mixedCase()
                        ->numbers()
                        ->symbols()
                        ->uncompromised()
                ],
            ], [
                'current_password.required' => 'Le mot de passe actuel est obligatoire',
                'password.required' => 'Le nouveau mot de passe est obligatoire',
                'password.confirmed' => 'Les mots de passe ne correspondent pas',
            ]);

            if ($validator->fails()) {
                return $this->errorResponse($validator->errors()->first(), 422);
            }

            $user = $request->user();

            if (!Hash::check($request->current_password, $user->password)) {
                return $this->errorResponse('Le mot de passe actuel est incorrect', 422);
            }

            $user->password = Hash::make($request->password);
            $user->save();

            // Déconnecter tous les autres appareils
            $user->tokens()->delete();

            return $this->successResponse(null, 'Mot de passe modifié avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Une erreur est survenue lors du changement de mot de passe', 500);
        }
    }

    /**
     * Send password reset link
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $status = Password::sendResetLink(
            $request->only('email')
        );

        if ($status === Password::RESET_LINK_SENT) {
            return response()->json(['message' => 'Reset password link sent to email']);
        }

        throw ValidationException::withMessages([
            'email' => [trans($status)],
        ]);
    }

    /**
     * Reset password
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->password = Hash::make($password);
                $user->save();
            }
        );

        if ($status === Password::PASSWORD_RESET) {
            return response()->json(['message' => 'Password reset successfully']);
        }

        throw ValidationException::withMessages([
            'email' => [trans($status)],
        ]);
    }
}
