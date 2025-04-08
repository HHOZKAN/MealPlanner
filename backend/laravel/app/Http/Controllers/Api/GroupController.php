<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Group;
use App\Models\GroupMember;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Traits\ApiResponse;
use Illuminate\Support\Facades\Log; // Ajoutez cette ligne en haut

class GroupController extends Controller
{
    use ApiResponse;

    /**
     * Liste des groupes de l'utilisateur
     */
    public function index()
    {
        try {
            $groups = Group::whereHas('members', function ($query) {
                $query->where('user_id', Auth::id());
            })
            ->with(['members.user', 'preferences'])
            ->get();

            return $this->successResponse($groups, 'Groupes récupérés avec succès');
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la récupération des groupes', 500);
        }
    }

    /**
     * Créer un nouveau groupe
     */
    public function store(Request $request)
    {
        try {
            Log::info('Tentative de création de groupe', ['data' => $request->all()]);
    
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'preferences' => 'nullable|array',
                'members' => 'nullable|array',
                'members.*' => 'exists:users,id'
            ]);
    
            Log::info('Données validées', ['validated' => $validated]);
    
            // Créer le groupe
            $group = Group::create([
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
                'created_by' => Auth::id(),
                'is_active' => true // Ajoutez cette ligne
            ]);
    
            Log::info('Groupe créé', ['group' => $group->toArray()]);
    
            // Ajouter le créateur comme admin
            $member = GroupMember::create([
                'group_id' => $group->id,
                'user_id' => Auth::id(),
                'role' => 'admin'
            ]);
    
            Log::info('Créateur ajouté comme admin', ['member' => $member->toArray()]);
    
            // Ajouter les autres membres
            if (!empty($validated['members'])) {
                foreach ($validated['members'] as $memberId) {
                    if ($memberId !== Auth::id()) {
                        GroupMember::create([
                            'group_id' => $group->id,
                            'user_id' => $memberId,
                            'role' => 'member'
                        ]);
                    }
                }
            }
    
            // Ajouter les préférences
            if (!empty($validated['preferences'])) {
                foreach ($validated['preferences'] as $key => $value) {
                    $group->preferences()->create([
                        'key' => $key,
                        'value' => $value
                    ]);
                }
            }
    
            $group->load(['members.user', 'preferences']);
    
            return $this->successResponse($group, 'Groupe créé avec succès');
    
        } catch (\Exception $e) {
            Log::error('Erreur lors de la création du groupe', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return $this->errorResponse(
                'Erreur lors de la création du groupe: ' . $e->getMessage(), 
                500
            );
        }
    }

    /**
     * Ajouter des membres au groupe
     */
    public function addMembers(Request $request, Group $group)
    {
        try {
            if (!$this->isGroupAdmin($group)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'members' => 'required|array',
                'members.*' => 'exists:users,id'
            ]);

            foreach ($validated['members'] as $memberId) {
                GroupMember::firstOrCreate(
                    [
                        'group_id' => $group->id,
                        'user_id' => $memberId
                    ],
                    ['role' => 'member']
                );
            }

            return $this->successResponse(
                $group->load('members.user'),
                'Membres ajoutés avec succès'
            );
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de l\'ajout des membres', 500);
        }
    }

    /**
     * Mettre à jour les préférences du groupe
     */
    public function updatePreferences(Request $request, Group $group)
    {
        try {
            if (!$this->isGroupMember($group)) {
                return $this->errorResponse('Non autorisé', 403);
            }

            $validated = $request->validate([
                'preferences' => 'required|array'
            ]);

            foreach ($validated['preferences'] as $key => $value) {
                $group->preferences()->updateOrCreate(
                    ['key' => $key],
                    ['value' => $value]
                );
            }

            return $this->successResponse(
                $group->load('preferences'),
                'Préférences mises à jour avec succès'
            );
        } catch (\Exception $e) {
            return $this->errorResponse('Erreur lors de la mise à jour des préférences', 500);
        }
    }

    private function isGroupAdmin(Group $group): bool
    {
        return $group->members()
            ->where('user_id', Auth::id())
            ->where('role', 'admin')
            ->exists();
    }

    private function isGroupMember(Group $group): bool
    {
        return $group->members()
            ->where('user_id', Auth::id())
            ->exists();
    }
}