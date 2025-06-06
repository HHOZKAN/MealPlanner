# Cas d'Utilisation Détaillés - MealPlanner

## 1. AUTHENTIFICATION ET SÉCURITÉ

### UC1.1 : Inscription d'un nouvel utilisateur

**Acteur principal :** Visiteur non authentifié

**Préconditions :**
- L'utilisateur n'est pas déjà connecté
- L'utilisateur a accès à l'application

**Scénario principal :**
1. L'utilisateur accède au formulaire d'inscription
2. L'utilisateur saisit les informations requises :
   - Nom complet
   - Adresse email
   - Mot de passe
   - Confirmation du mot de passe
3. L'utilisateur valide le formulaire
4. Le système vérifie les informations :
   - Format d'email valide
   - Mot de passe conforme aux règles de sécurité
   - Email non déjà utilisé
5. Le système crée le compte utilisateur
6. Le système envoie un email de confirmation
7. Le système connecte automatiquement l'utilisateur
8. Le système redirige vers la page d'accueil

**Scénarios alternatifs :**
- 4a. Email invalide : Le système affiche une erreur de format
- 4b. Mot de passe trop faible : Le système indique les règles non respectées
- 4c. Email déjà utilisé : Le système propose la connexion ou la récupération de mot de passe
- 6a. Échec d'envoi d'email : Le système notifie l'utilisateur de vérifier plus tard

**Postconditions :**
- Le compte utilisateur est créé
- L'utilisateur est connecté
- Un email de confirmation est envoyé

### UC1.2 : Connexion avec email et mot de passe

**Acteur principal :** Utilisateur enregistré

**Préconditions :**
- L'utilisateur possède un compte
- L'utilisateur n'est pas déjà connecté

**Scénario principal :**
1. L'utilisateur accède au formulaire de connexion
2. L'utilisateur saisit :
   - Son adresse email
   - Son mot de passe
3. L'utilisateur valide le formulaire
4. Le système vérifie les identifiants
5. Le système crée une session authentifiée
6. Le système redirige vers la dernière page visitée ou la page d'accueil

**Scénarios alternatifs :**
- 4a. Identifiants incorrects : Le système affiche un message d'erreur
- 4b. Compte désactivé : Le système informe l'utilisateur
- 4c. Trop de tentatives : Le système impose un délai d'attente

**Postconditions :**
- L'utilisateur est connecté
- Un token d'authentification est généré
- La session est créée

### UC1.3 : Connexion avec Google

**Acteur principal :** Utilisateur avec compte Google

**Préconditions :**
- L'utilisateur n'est pas connecté
- L'utilisateur a un compte Google

**Scénario principal :**
1. L'utilisateur clique sur "Se connecter avec Google"
2. Le système redirige vers la page d'authentification Google
3. L'utilisateur autorise l'application
4. Google renvoie les informations de l'utilisateur
5. Le système :
   - Crée un nouveau compte si l'email n'existe pas
   - Connecte l'utilisateur si le compte existe déjà
6. Le système redirige vers l'application

**Scénarios alternatifs :**
- 3a. Autorisation refusée : Retour à la page de connexion
- 4a. Erreur de communication : Le système affiche un message d'erreur
- 5a. Conflit d'email : Le système propose de lier les comptes

**Postconditions :**
- L'utilisateur est connecté
- Les informations Google sont liées au compte
- La session est créée

### UC1.4 : Déconnexion

**Acteur principal :** Utilisateur connecté

**Préconditions :**
- L'utilisateur est authentifié
- Une session active existe

**Scénario principal :**
1. L'utilisateur demande la déconnexion
2. Le système :
   - Invalide le token d'authentification
   - Supprime la session
   - Efface les données locales sensibles
3. Le système redirige vers la page de connexion

**Scénarios alternatifs :**
- 2a. Erreur de communication : Le système force la déconnexion locale
- 2b. Session déjà expirée : Le système nettoie les données locales

**Postconditions :**
- L'utilisateur est déconnecté
- La session est terminée
- Les données sensibles sont effacées

---

## 2. GESTION DES ÉVÉNEMENTS

### UC2.1 : Créer un nouvel événement

**Acteur principal :** Utilisateur connecté (Organisateur)

**Préconditions :**
- L'utilisateur est authentifié
- L'utilisateur a accès à l'interface de création d'événement

**Scénario principal :**
1. L'utilisateur accède à la page de création d'événement
2. Le système affiche le formulaire de création
3. L'utilisateur saisit les informations obligatoires :
   - Titre de l'événement
   - Date et heure
   - Lieu
4. L'utilisateur peut optionnellement saisir :
   - Description détaillée
   - Type d'événement (repas, fête, pique-nique, etc.)
   - Emoji représentatif
5. L'utilisateur valide la création
6. Le système enregistre l'événement
7. Le système assigne l'utilisateur comme organisateur
8. Le système redirige vers la page de détail de l'événement

**Scénarios alternatifs :**
- 3a. Informations manquantes : Le système affiche les erreurs de validation
- 5a. Erreur de sauvegarde : Le système affiche un message d'erreur

**Postconditions :**
- Un nouvel événement est créé dans le système
- L'utilisateur est défini comme organisateur
- L'événement a le statut "en préparation"

---

### UC2.2 : Gérer les participants

**Acteur principal :** Organisateur de l'événement

**Préconditions :**
- L'utilisateur est l'organisateur de l'événement
- L'événement existe dans le système

**Scénario principal :**
1. L'organisateur accède à la gestion des participants
2. Le système affiche la liste des participants actuels
3. L'organisateur peut :
   - Ajouter de nouveaux participants par email
   - Voir le statut des invitations (en attente, acceptée, refusée)
   - Relancer les invitations en attente
   - Supprimer des participants
4. Pour chaque invitation :
   - Le système envoie un email d'invitation
   - Le système crée une entrée "invitation en attente"
5. Les participants invités reçoivent un lien pour répondre
6. Le système met à jour automatiquement les statuts

**Scénarios alternatifs :**
- 3a. Email invalide : Le système affiche une erreur de validation
- 4a. Échec d'envoi d'email : Le système log l'erreur et notifie l'organisateur
- 6a. Participant déjà invité : Le système affiche un avertissement

**Postconditions :**
- Les invitations sont envoyées aux nouveaux participants
- Le statut des participants est mis à jour
- L'organisateur peut suivre les réponses

---

## 3. GESTION DES INGRÉDIENTS

### UC3.1 : Planification des ingrédients

**Acteur principal :** Organisateur ou Participant autorisé

**Préconditions :**
- L'utilisateur participe à l'événement
- L'événement est en phase de planification

**Scénario principal :**
1. L'utilisateur accède à la liste des ingrédients de l'événement
2. Le système affiche les ingrédients existants avec leur statut
3. L'utilisateur peut ajouter un nouvel ingrédient :
   - Nom de l'ingrédient
   - Quantité nécessaire
   - Unité de mesure (g, kg, ml, l, pièce, paquet)
   - Prix estimé
   - Notes optionnelles
   - Emoji représentatif
4. L'utilisateur valide l'ajout
5. Le système enregistre l'ingrédient avec le statut "needed"
6. Le système notifie les autres participants de l'ajout

**Scénarios alternatifs :**
- 3a. Ingrédient déjà existant : Le système propose de modifier la quantité
- 4a. Données invalides : Le système affiche les erreurs de validation
- 5a. Erreur de sauvegarde : Le système affiche un message d'erreur

**Postconditions :**
- L'ingrédient est ajouté à la liste de l'événement
- Les participants sont notifiés
- L'ingrédient est disponible pour attribution

---

### UC3.2 : Attribution des responsabilités

**Acteur principal :** Organisateur ou Participant

**Préconditions :**
- Des ingrédients sont définis pour l'événement
- L'utilisateur participe à l'événement

**Scénario principal :**
1. L'utilisateur consulte la liste des ingrédients
2. Le système affiche les ingrédients avec leur statut :
   - Rouge : Non assigné (needed)
   - Orange : Assigné mais non acheté (assigned)
   - Vert : Acheté (purchased)
3. L'utilisateur peut s'assigner un ingrédient non pris
4. Le système met à jour le statut à "assigned"
5. L'utilisateur peut marquer un ingrédient comme acheté
6. L'utilisateur saisit le prix réel payé
7. Le système met à jour le statut à "purchased"
8. Le système recalcule le coût total de l'événement

**Scénarios alternatifs :**
- 3a. Ingrédient déjà assigné : Le système affiche un message d'information
- 6a. Prix réel non saisi : Le système utilise le prix estimé
- 7a. Erreur de mise à jour : Le système affiche un message d'erreur

**Postconditions :**
- Les responsabilités sont clairement définies
- Le suivi des achats est mis à jour
- Les coûts réels sont enregistrés

--- 

## 4. GESTION DES DÉPENSES

### UC4.1 : Suivi des coûts

**Acteur principal :** Organisateur ou Participant

**Préconditions :**
- L'événement a des ingrédients avec des prix
- L'utilisateur participe à l'événement

**Scénario principal :**
1. L'utilisateur accède au tableau des dépenses
2. Le système affiche :
   - Coût total estimé vs réel
   - Détail par ingrédient
   - Répartition par participant
   - Historique des paiements
3. L'utilisateur peut ajouter une dépense supplémentaire
4. L'utilisateur peut modifier le prix d'un ingrédient acheté
5. Le système recalcule automatiquement tous les totaux
6. Le système met à jour la répartition des coûts

**Scénarios alternatifs :**
- 3a. Dépense invalide : Le système affiche une erreur de validation
- 4a. Modification non autorisée : Le système refuse la modification
- 5a. Erreur de calcul : Le système log l'erreur et affiche un message

**Postconditions :**
- Les coûts sont précisément suivis
- La répartition est calculée équitablement
- L'historique est maintenu

---

### UC4.2 : Gestion des remboursements

**Acteur principal :** Participant

**Préconditions :**
- L'événement a des dépenses enregistrées
- La répartition des coûts est calculée

**Scénario principal :**
1. Le système calcule automatiquement qui doit combien à qui
2. L'utilisateur consulte ses dettes et créances
3. Le système affiche les suggestions de remboursement optimisées
4. L'utilisateur peut marquer un remboursement comme effectué
5. Le système met à jour les soldes
6. Le système notifie les participants concernés
7. Quand tous les remboursements sont effectués, l'événement est "soldé"

**Scénarios alternatifs :**
- 2a. Aucune dette : Le système affiche "Vous êtes à jour"
- 4a. Remboursement contesté : Le système permet d'ajouter des commentaires
- 6a. Échec de notification : Le système log l'erreur

**Postconditions :**
- Les remboursements sont suivis
- Les participants sont notifiés
- L'équilibre financier est maintenu

---

## 5. PROFIL ET PRÉFÉRENCES

### UC5.1 : Gestion du profil

**Acteur principal :** Utilisateur connecté

**Préconditions :**
- L'utilisateur est authentifié

**Scénario principal :**
1. L'utilisateur accède à son profil
2. Le système affiche les informations actuelles
3. L'utilisateur peut modifier :
   - Nom et prénom
   - Email
   - Numéro de téléphone
   - Photo de profil
   - Préférences alimentaires
4. L'utilisateur valide les modifications
5. Le système met à jour les informations
6. Le système confirme la mise à jour

**Scénarios alternatifs :**
- 3a. Email déjà utilisé : Le système affiche une erreur
- 4a. Format de fichier invalide pour la photo : Le système refuse l'upload
- 5a. Erreur de sauvegarde : Le système affiche un message d'erreur

**Postconditions :**
- Le profil utilisateur est mis à jour
- Les modifications sont visibles dans tous les événements

---

### UC5.2 : Notifications

**Acteur principal :** Utilisateur connecté

**Préconditions :**
- L'utilisateur participe à des événements

**Scénario principal :**
1. Le système génère automatiquement des notifications pour :
   - Nouvelles invitations à des événements
   - Modifications d'événements
   - Nouveaux ingrédients ajoutés
   - Rappels d'achats assignés
   - Demandes de remboursement
2. L'utilisateur reçoit les notifications via :
   - Interface de l'application
   - Email (selon préférences)
   - Push notifications (mobile)
3. L'utilisateur peut marquer les notifications comme lues
4. L'utilisateur peut configurer ses préférences de notification

**Scénarios alternatifs :**
- 2a. Échec d'envoi email : Le système garde la notification dans l'app
- 4a. Préférences non sauvegardées : Le système utilise les paramètres par défaut

**Postconditions :**
- L'utilisateur est informé des événements importants
- Les préférences de notification sont respectées

---

## 6. GESTION DES GROUPES

### UC6.1 : Créer et gérer des groupes

**Acteur principal :** Utilisateur connecté

**Préconditions :**
- L'utilisateur est authentifié

**Scénario principal :**
1. L'utilisateur accède à la gestion des groupes
2. L'utilisateur peut créer un nouveau groupe :
   - Nom du groupe
   - Description
   - Paramètres de visibilité
3. L'utilisateur devient automatiquement administrateur du groupe
4. L'utilisateur peut inviter des membres au groupe
5. Le système envoie des invitations aux nouveaux membres
6. Les membres peuvent accepter ou refuser l'invitation
7. L'administrateur peut gérer les membres (ajouter, supprimer, changer les rôles)

**Scénarios alternatifs :**
- 2a. Nom de groupe déjà existant : Le système propose des alternatives
- 5a. Échec d'envoi d'invitation : Le système log l'erreur
- 7a. Tentative de suppression du dernier administrateur : Le système refuse l'action

**Postconditions :**
- Le groupe est créé et actif
- Les membres peuvent organiser des événements ensemble
- Les préférences de groupe sont configurables

---

### UC6.2 : Utiliser les groupes pour les événements

**Acteur principal :** Membre d'un groupe

**Préconditions :**
- L'utilisateur appartient à au moins un groupe
- Le groupe a des membres actifs

**Scénario principal :**
1. Lors de la création d'un événement, l'utilisateur peut sélectionner un groupe
2. Le système pré-remplit automatiquement la liste des participants avec les membres du groupe
3. L'utilisateur peut ajuster la liste (retirer ou ajouter des participants)
4. Le système applique les préférences du groupe (préférences alimentaires communes)
5. L'événement est créé avec les participants du groupe
6. Tous les membres du groupe reçoivent une notification

**Scénarios alternatifs :**
- 2a. Groupe inactif : Le système affiche un avertissement
- 4a. Conflits de préférences : Le système demande une résolution manuelle
- 6a. Membre ayant quitté le groupe : Le système exclut automatiquement

**Postconditions :**
- L'événement est créé avec les bons participants
- Les préférences de groupe sont appliquées
- La collaboration est facilitée

---

## 7. TABLEAU DE BORD

### UC7.1 : Vue d'ensemble

**Acteur principal :** Utilisateur connecté

**Préconditions :**
- L'utilisateur est authentifié
- L'utilisateur participe à des événements

**Scénario principal :**
1. L'utilisateur accède au tableau de bord
2. Le système affiche :
   - Événements à venir (prochains 30 jours)
   - Événements en cours d'organisation
   - Tâches en attente (ingrédients à acheter, remboursements)
   - Statistiques personnelles (événements organisés, participation)
   - Historique récent des événements
3. L'utilisateur peut cliquer sur un élément pour accéder aux détails
4. Le système met à jour les informations en temps réel

**Scénarios alternatifs :**
- 2a. Aucun événement : Le système affiche un message d'accueil avec suggestions
- 4a. Erreur de chargement : Le système affiche les données en cache

**Postconditions :**
- L'utilisateur a une vue complète de ses activités
- L'accès rapide aux actions importantes est disponible

---

## FLUX COMPLET D'UTILISATION

### Scénario type : Organisation d'un repas entre amis

1. **Création** : Marie crée un événement "Dîner chez Marie" pour samedi prochain
2. **Invitations** : Elle invite Paul, Julie et Thomas par email
3. **Planification** : Ensemble, ils ajoutent les ingrédients nécessaires (entrée, plat, dessert, boissons)
4. **Attribution** : Chacun se charge de certains ingrédients
5. **Achats** : Ils marquent leurs achats comme effectués avec les prix réels
6. **Événement** : Le dîner a lieu
7. **Règlement** : L'application calcule qui doit combien à qui
8. **Remboursements** : Les participants se remboursent selon les suggestions de l'app
9. **Clôture** : L'événement est marqué comme "soldé"

Ce flux illustre l'utilisation complète de l'application du début à la fin d'un événement.
