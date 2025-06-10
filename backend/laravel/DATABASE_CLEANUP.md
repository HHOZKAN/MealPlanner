# 🧹 Nettoyage de la Base de Données

## ✅ Tables Activement Utilisées

### Core
1. **users**
   - Authentification
   - Profils utilisateurs
   - Relations avec événements

2. **events**
   - Événements principaux
   - Gestion des repas partagés
   - Inclut emoji et catégories

3. **participants**
   - Participants aux événements
   - Statuts de participation
   - Notes et réponses

### Gestion des Ingrédients
4. **ingredients**
   - Liste des ingrédients par événement
   - Prix et quantités
   - Emoji

5. **ingredient_assignments**
   - Attribution des ingrédients aux participants
   - Statut d'achat
   - Quantités assignées

### Gestion des Dépenses
6. **expenses**
   - Dépenses liées aux événements
   - Catégorisation
   - Photos des reçus

7. **expense_shares**
   - Partage des dépenses
   - Montants par participant

8. **reimbursements**
   - Suivi des remboursements
   - Statuts de paiement

### Système d'Invitation
9. **pending_invitations**
   - Invitations en attente
   - Tokens uniques
   - Dates d'expiration

## ❌ Tables Non Utilisées ou Redondantes

1. **groups**, **group_members**, **group_preferences**
   - Fonctionnalité de groupes non implémentée
   - Peut être supprimée sans impact

2. **shared_ingredients**
   - Redondant avec ingredient_assignments
   - Pas utilisé dans l'application

3. **price_histories** et **price_history**
   - Deux tables similaires
   - Fonctionnalité non implémentée
   - Une seule suffirait si nécessaire

4. **manual_prices**
   - Non utilisé dans l'application
   - Redondant avec le champ price des ingrédients

5. **shareable_invitation_links**
   - Redondant avec pending_invitations
   - Non utilisé dans l'interface

6. **payments**
   - Remplacé par le système de reimbursements
   - Peut être supprimé

## 🔄 Tables Système (À Conserver)

1. **sessions**
   - Gestion des sessions Laravel
   - Nécessaire pour l'authentification

2. **personal_access_tokens**
   - Authentification API
   - Sanctum tokens

3. **cache**
   - Cache système
   - Performance

4. **jobs** et **failed_jobs**
   - Files d'attente Laravel
   - Nécessaire pour les emails et tâches async

## 📝 Actions Recommandées

### 1. Suppression des Tables
```sql
DROP TABLE IF EXISTS groups;
DROP TABLE IF EXISTS group_members;
DROP TABLE IF EXISTS group_preferences;
DROP TABLE IF EXISTS shared_ingredients;
DROP TABLE IF EXISTS price_histories;
DROP TABLE IF EXISTS price_history;
DROP TABLE IF EXISTS manual_prices;
DROP TABLE IF EXISTS shareable_invitation_links;
DROP TABLE IF EXISTS payments;
```

### 2. Suppression des Migrations Correspondantes
- Supprimer les fichiers de migration des tables non utilisées
- Mettre à jour le numéro de version de la base de données

### 3. Suppression des Modèles Non Utilisés
```bash
app/Models/Group.php
app/Models/GroupMember.php
app/Models/GroupPreference.php
app/Models/SharedIngredient.php
app/Models/PriceHistory.php
app/Models/ManualPrice.php
app/Models/Payment.php
```

### 4. Mise à Jour des Relations
- Vérifier et nettoyer les relations dans les modèles restants
- Supprimer les références aux modèles supprimés

## 🔍 Impact sur l'Application

### Aucun Impact Sur :
- ✅ Création et gestion d'événements
- ✅ Gestion des ingrédients
- ✅ Système de dépenses et remboursements
- ✅ Invitations et participations
- ✅ Authentification et sessions

### Bénéfices :
1. Base de données plus légère
2. Moins de maintenance
3. Code plus clair
4. Meilleure performance

## 📋 Plan d'Action

1. **Backup**
   - Sauvegarder la base de données
   - Sauvegarder les migrations

2. **Test**
   - Créer un environnement de test
   - Vérifier l'impact des suppressions

3. **Exécution**
   - Supprimer les tables
   - Nettoyer les migrations
   - Mettre à jour les modèles

4. **Vérification**
   - Tester toutes les fonctionnalités
   - Vérifier les performances

## 🎯 Résultat Final

Une base de données plus propre et efficace, concentrée sur les fonctionnalités réellement utilisées dans l'application :
- Gestion des événements
- Gestion des ingrédients
- Système de dépenses
- Invitations et participations
