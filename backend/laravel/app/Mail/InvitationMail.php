<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;

class InvitationMail extends Mailable
{
    public $event;
    public $invitationToken;
    public $message;

    public function __construct($event, $token, $message = null)
    {
        $this->event = $event;
        $this->invitationToken = $token;
        $this->message = $message;
    }

    public function build()
    {
        return $this->markdown('emails.invitation')
                    ->subject('Invitation à ' . $this->event->title);
    }
}