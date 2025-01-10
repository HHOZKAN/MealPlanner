<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth; // Modifiez cette ligne
use Illuminate\Foundation\Auth\Access\AuthorizesRequests; // Ajoutez cette ligne

class EventController extends Controller
{
    use AuthorizesRequests;
    public function index()
    {
        $events = Event::with(['organizer', 'participants'])
            ->where('organizer_id', Auth::id())
            ->orWhereHas('participants', function ($query) {
                $query->where('user_id', Auth::id());
            })
            ->latest()
            ->get();

        return response()->json($events);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'date' => 'required|date|after:now',
            'location' => 'nullable|string',
            'type' => 'required|string',
        ]);

        $event = Event::create([
            ...$validated,
            'organizer_id' => Auth::id(),
            'status' => 'draft'
        ]);

        return response()->json($event, 201);
    }

    public function show(Event $event)
    {
        $this->authorize('view', $event);

        return response()->json($event->load([
            'organizer',
            'participants.user',
            'ingredients.assignments'
        ]));
    }

    public function update(Request $request, Event $event)
    {
        $this->authorize('update', $event);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'date' => 'sometimes|required|date',
            'location' => 'nullable|string',
            'type' => 'sometimes|required|string',
            'status' => 'sometimes|required|in:draft,planning,confirmed,cancelled,completed',
        ]);

        $event->update($validated);

        return response()->json($event);
    }

    public function destroy(Event $event)
    {
        $this->authorize('delete', $event);

        $event->delete();

        return response()->json(null, 204);
    }
}
