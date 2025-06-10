# 📊 Modèle Conceptuel de Données - MealPlanner

## 👤 Entités Principales

### User (Utilisateur)
```
User {
    id              INT (PK)
    name            VARCHAR(255)
    email           VARCHAR(255) UNIQUE
    password        VARCHAR(255)
    phone_number    VARCHAR(20) NULL
    avatar          VARCHAR(255) NULL
    preferences     JSON NULL
    is_active       BOOLEAN
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
}
```

### Event (Événement)
```
Event {
    id              INT (PK)
    organizer_id    INT (FK -> User)
    title           VARCHAR(255)
    description     TEXT NULL
    date            DATETIME
    location        VARCHAR(255) NULL
    type            VARCHAR(50)
    emoji           VARCHAR(10) NULL
    status          VARCHAR(50)
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
    deleted_at      TIMESTAMP NULL
}
```

### Ingredient (Ingrédient)
```
Ingredient {
    id              INT (PK)
    event_id        INT (FK -> Event)
    name            VARCHAR(255)
    quantity        DECIMAL(8,2)
    unit            VARCHAR(20)
    estimated_price DECIMAL(10,2) NULL
    actual_price    DECIMAL(10,2) NULL
    added_by        INT (FK -> User)
    status          ENUM('needed','assigned','purchased')
    notes           TEXT NULL
    emoji           VARCHAR(10) NULL
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
    deleted_at      TIMESTAMP NULL
}
```

### Expense (Dépense)
```
Expense {
    id              INT (PK)
    event_id        INT (FK -> Event)
    ingredient_id   INT NULL (FK -> Ingredient)
    payer_id        INT (FK -> User)
    amount          DECIMAL(10,2)
    description     TEXT NULL
    category        VARCHAR(50) NULL
    receipt_image   VARCHAR(255) NULL
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
}
```

## 🔄 Tables de Relations

### Participant (Participation à un événement)
```
Participant {
    id              INT (PK)
    event_id        INT (FK -> Event)
    user_id         INT (FK -> User)
    status          VARCHAR(50)
    responded_at    TIMESTAMP NULL
    note            TEXT NULL
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
}
```

### IngredientAssignment (Attribution d'ingrédient)
```
IngredientAssignment {
    id              INT (PK)
    ingredient_id   INT (FK -> Ingredient)
    user_id         INT (FK -> User)
    status          VARCHAR(50)
    quantity        DECIMAL(8,2)
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
}
```

### ExpenseShare (Part de dépense)
```
ExpenseShare {
    id              INT (PK)
    expense_id      INT (FK -> Expense)
    user_id         INT (FK -> User)
    amount          DECIMAL(10,2)
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
}
```

### PendingInvitation (Invitation en attente)
```
PendingInvitation {
    id              INT (PK)
    event_id        INT (FK -> Event)
    email           VARCHAR(255)
    token           VARCHAR(100)
    status          VARCHAR(50)
    expires_at      TIMESTAMP
    created_at      TIMESTAMP
    updated_at      TIMESTAMP
}
```

## 🔗 Relations

### One-to-Many
- User ➜ Event (organizer_id)
- Event ➜ Ingredient
- Event ➜ Expense
- Event ➜ PendingInvitation
- Ingredient ➜ IngredientAssignment
- Expense ➜ ExpenseShare

### Many-to-Many
- User <-> Event (via Participant)
- User <-> Ingredient (via IngredientAssignment)
- User <-> Expense (via ExpenseShare)

## 📝 Contraintes

### Clés Étrangères
```sql
ALTER TABLE Event
ADD CONSTRAINT fk_event_organizer
FOREIGN KEY (organizer_id) REFERENCES User(id);

ALTER TABLE Ingredient
ADD CONSTRAINT fk_ingredient_event
FOREIGN KEY (event_id) REFERENCES Event(id);

ALTER TABLE Expense
ADD CONSTRAINT fk_expense_event
FOREIGN KEY (event_id) REFERENCES Event(id);
```

### Contraintes d'Unicité
```sql
ALTER TABLE User
ADD CONSTRAINT unique_email
UNIQUE (email);

ALTER TABLE PendingInvitation
ADD CONSTRAINT unique_token
UNIQUE (token);
```

### Contraintes de Validation
```sql
-- Statut d'ingrédient valide
ALTER TABLE Ingredient
ADD CONSTRAINT check_ingredient_status
CHECK (status IN ('needed', 'assigned', 'purchased'));

-- Montant positif pour les dépenses
ALTER TABLE Expense
ADD CONSTRAINT check_expense_amount
CHECK (amount > 0);
```

## 📊 Diagramme des Relations

```
User ────┬──────> Event <──────┬── Ingredient
         │          ▲          │       ▲
         │          │          │       │
         ▼          │          ▼       │
    Participant     │       Expense    │
         ▲          │          ▲       │
         │          │          │       │
         └──────────┴──────────┘       │
                    ▲                  │
                    │                  │
              ExpenseShare    IngredientAssignment
```

## 🎯 Points Clés

1. **Centralisation autour de Event**
   - Tous les éléments sont liés à un événement
   - Gestion des participants via table pivot
   - Suivi des ingrédients et dépenses

2. **Gestion des Dépenses**
   - Lien optionnel avec les ingrédients
   - Système de partage des coûts
   - Suivi des paiements et remboursements

3. **Système d'Invitation**
   - Invitations en attente avec tokens
   - Statuts de participation
   - Gestion des réponses

4. **Traçabilité**
   - Timestamps sur toutes les tables
   - Soft deletes sur Event et Ingredient
   - Historique des modifications

## 🔄 Flux Typique

1. **Création d'Événement**
   ```
   User -> Event -> PendingInvitation
   ```

2. **Gestion des Ingrédients**
   ```
   Event -> Ingredient -> IngredientAssignment -> User
   ```

3. **Gestion des Dépenses**
   ```
   User -> Expense -> ExpenseShare -> Participants
   ```

Cette structure permet une gestion complète des événements de repas partagés, du planning à la répartition des coûts.
