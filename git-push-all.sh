#!/bin/bash

# Couleurs pour une meilleure lisibilité
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages avec un préfixe
log() {
    echo -e "${GREEN}[GIT]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier s'il y a des modifications
if [ -z "$(git status --porcelain)" ]; then
    warning "Aucune modification détectée."
    exit 0
fi

# Afficher le status actuel
log "Status actuel des fichiers :"
git status

# Demander confirmation pour continuer
read -p "$(echo -e ${YELLOW}"Voulez-vous continuer ? (y/n) "${NC})" choice
case "$choice" in 
  y|Y ) ;;
  n|N ) exit 0 ;;
  * ) error "Réponse invalide"; exit 1 ;;
esac

# Ajouter tous les fichiers (y compris non suivis)
log "Ajout des fichiers modifiés et non suivis..."
git add -A

# Demander le message de commit
read -p "$(echo -e ${GREEN}"Message de commit : "${NC})" commit_message

# Vérifier si le message de commit n'est pas vide
if [ -z "$commit_message" ]; then
    error "Le message de commit ne peut pas être vide"
    exit 1
fi

# Faire le commit
log "Création du commit..."
git commit -m "$commit_message"

# Vérifier les remotes
log "Liste des remotes configurées :"
git remote -v

# Push vers GitHub
log "Push vers GitHub..."
if git push github; then
    log "Push vers GitHub réussi ✅"
else
    error "Erreur lors du push vers GitHub ❌"
fi

# Push vers GitLab
log "Push vers GitLab..."
if git push gitlab; then
    log "Push vers GitLab réussi ✅"
else
    error "Erreur lors du push vers GitLab ❌"
fi

log "Opération terminée avec succès! 🎉"

# Afficher le dernier status
git status
