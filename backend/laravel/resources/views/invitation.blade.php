@component('mail::message')
# Invitation à {{ $event->title }}

Vous avez été invité(e) à participer à l'événement "{{ $event->title }}" !

@if($message)
Message de l'organisateur :
> {{ $message }}
@endif

**Détails de l'événement :**
- Date : {{ $event->date->format('d/m/Y H:i') }}
- Lieu : {{ $event->location }}

@if(!auth()->check())
@component('mail::button', ['url' => url("/register?token={$invitationToken}")])
Créer un compte pour répondre
@endcomponent
@else
@component('mail::button', ['url' => url("/events/{$event->id}")])
Voir l'événement
@endcomponent
@endif

Merci,<br>
{{ config('app.name') }}
@endcomponent