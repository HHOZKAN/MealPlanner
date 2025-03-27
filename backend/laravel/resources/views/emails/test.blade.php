<!DOCTYPE html>
<html>
<head>
    <title>Test Email</title>
</head>
<body>
    <h1>Test Email</h1>
    <p>Ceci est un email de test pour vérifier la configuration Mailtrap.</p>
    <p>Envoyé le : {{ now()->format('d/m/Y H:i') }}</p>
    <p>Depuis : {{ config('app.name') }}</p>
</body>
</html>