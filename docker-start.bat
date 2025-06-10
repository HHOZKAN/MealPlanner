@echo off
echo 📝 Configuration de l'environnement...
copy backend\laravel\.env.docker backend\laravel\.env

echo 🏗️  Construction et démarrage des containers...
docker-compose up -d --build

echo ⏳ Attente du démarrage des services...
timeout /t 10 /nobreak > nul

echo 📦 Installation des dépendances Laravel...
docker-compose exec -T backend composer install

echo 🔑 Génération de la clé d'application...
docker-compose exec -T backend php artisan key:generate --no-interaction

echo 🗄️  Exécution des migrations...
docker-compose exec -T backend php artisan migrate --no-interaction

echo ✅ Installation terminée !
echo.
echo 🌐 Accès aux services :
echo    - Application : http://localhost:8001
echo    - pgAdmin    : http://localhost:5050
echo      - Email    : admin@admin.com
echo      - Password : admin
pause
