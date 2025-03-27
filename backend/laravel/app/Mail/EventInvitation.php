<?php

namespace App\Mail;

use App\Models\Event;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class EventInvitation extends Mailable
{
    use Queueable, SerializesModels;

    public $event;
    public $message;
    public $isNewUser;
    public $token;
    public $appStoreUrl;
    public $playStoreUrl;
    public $webAppUrl;

    public function __construct(Event $event, ?string $message = null, bool $isNewUser = false, ?string $token = null)
    {
        $this->event = $event;
        $this->message = $message;
        $this->isNewUser = $isNewUser;
        $this->token = $token;

        // URLs des stores et de l'application web
        $this->appStoreUrl = config('app.store_urls.ios', 'https://apps.apple.com/app/meal-planner');
        $this->playStoreUrl = config('app.store_urls.android', 'https://play.google.com/store/apps/meal-planner');
        $this->webAppUrl = config('app.url') . '/events/' . $event->id . ($token ? '?token=' . $token : '');

        Log::info('Email d\'invitation construit', [
            'event_id' => $event->id,
            'isNewUser' => $isNewUser,
            'hasToken' => !empty($token)
        ]);
    }

    public function build()
{
    return $this->view('emails.event-invitation')
                ->with([
                    'event' => $this->event,
                    'message' => is_string($this->message) ? $this->message : '', // Validation de $message
                    'isNewUser' => $this->isNewUser,
                    'appStoreUrl' => $this->appStoreUrl,
                    'playStoreUrl' => $this->playStoreUrl,
                    'webAppUrl' => $this->webAppUrl,
                ])
                ->subject("Invitation à {$this->event->title}");
}
}