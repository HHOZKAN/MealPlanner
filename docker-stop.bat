@echo off
echo 🛑 Arrêt des containers...
docker-compose down

echo 🧹 Nettoyage des volumes non utilisés...
docker volume prune -f

echo ✅ Arrêt terminé !
pause
