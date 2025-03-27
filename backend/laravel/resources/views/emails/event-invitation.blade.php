<!DOCTYPE html>
<html>

<head>
    <title>Invitation à {{ $event->title }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            background-color: #4CAF50;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px;
            margin-bottom: 20px;
        }

        .message-box {
            background-color: #f8f9fa;
            border-left: 4px solid #4CAF50;
            padding: 15px;
            margin: 20px 0;
        }

        .event-details {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }

        .button {
            display: inline-block;
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 10px 0;
        }

        .store-buttons {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin: 20px 0;
        }

        .store-button {
            display: inline-block;
            padding: 10px 20px;
            background-color: #333;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 5px;
        }
    </style>
</head>

<body>
    <div class="header">
        <h1>Invitation à {{ $event->title }}</h1>
    </div>

    <p>Vous avez été invité(e) à participer à un événement sur Meal Planner !</p>

    @if (is_string($message) && !empty($message))
        <div class="message-box">
            <strong>Message de l'organisateur :</strong><br>
            {{ $message }}
        </div>
    @endif

    <div class="event-details">
        <h2>Détails de l'événement</h2>
        <p><strong>Date :</strong> {{ \Carbon\Carbon::parse($event->date)->format('d/m/Y H:i') }}</p>
        <p><strong>Lieu :</strong> {{ $event->location }}</p>
        <p><strong>Type :</strong> {{ $event->type }}</p>
    </div>

    @if ($isNewUser)
        <div style="text-align: center;">
            <h3>Pour participer, téléchargez l'application Meal Planner :</h3>

            <div class="store-buttons">
                <a href="{{ $appStoreUrl }}" class="store-button">
                    Télécharger sur App Store
                </a>
                <a href="{{ $playStoreUrl }}" class="store-button">
                    Télécharger sur Play Store
                </a>
            </div>

            <p>Ou accédez directement via votre navigateur :</p>
            <a href="{{ $webAppUrl }}" class="button">
                Accéder à l'événement
            </a>
        </div>
    @else
        <div style="text-align: center;">
            <a href="{{ $webAppUrl }}" class="button">
                Voir l'événement
            </a>
        </div>
    @endif

    <div style="margin-top: 40px; text-align: center; color: #666;">
        <p>
            Meal Planner - Organisez vos repas en groupe facilement<br>
            <small>Si vous ne souhaitez plus recevoir ces invitations, vous pouvez vous désabonner.</small>
        </p>
    </div>
</body>

</html>
