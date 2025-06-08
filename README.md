# TP Flutter – RASALCONNECT

Ce projet Flutter a été réalisé dans le cadre d’un TP ayant pour objectif de découvrir et maîtriser les bases du développement mobile avec **Flutter**.

---

## Objectif

Le but de ce TP est de :

- Comprendre le fonctionnement de Flutter et son architecture.
- Apprendre à créer une application mobile multiplateforme.
- Mettre en place une communication en **peer-to-peer (P2P)** pour une application de messagerie simple.

---

## 💬 Projet : RASALCONNECT

**RASALCONNECT** est une application de messagerie P2P permettant à deux utilisateurs de se connecter directement et d’échanger des messages en temps réel.

---

## 📁 Structure du projet – Fichiers clés

Voici les fichiers principaux de l’application :

| Fichier                      | Rôle                                                                 |
|-----------------------------|----------------------------------------------------------------------|
| `lib/screens/chat_screen.dart`  | Interface de messagerie : permet d’envoyer et recevoir des messages. |
| `lib/screens/join_screen.dart`  | Écran d'accueil : permet à un utilisateur de rejoindre une session via un ID. |
| `server.js`                     | Serveur Node.js (WebSocket) : établit la connexion entre deux utilisateurs. |

---

## Fonctionnalités implémentées

- Connexion P2P entre deux utilisateurs via un identifiant.
- Interface de chat en temps réel. (en cours de débogage pour ne pas dire non fonctionnel haha)
- Communication avec un serveur WebSocket en Node.js.

---

### 1. Lancer le serveur WebSocket

```bash
node server.js
```

### 2. Run l'application dans Flutter


---

### EXPLICATION 

Le serveur initialise l’échange (offre/réponse/ICE) entre deux pairs (définit par des ID) pour qu'ils puissent établir une connexion P2P directe sans passer ensuite par le serveur :

![Screenshot from 2025-06-08 18-44-35](https://github.com/user-attachments/assets/eda1e9c7-3cd3-46a8-b817-e8a5af8d2edb)

Ensuite, une proposition de rejoindre est proposé au pair distant :

![Screenshot from 2025-06-08 18-43-41](https://github.com/user-attachments/assets/0c7008c8-f2b7-48ae-9d45-e580f9742336)

Pour finir, la connexion est établie, les utilisateurs peuvent s'envoyer des messages, normalement :

![Screenshot from 2025-06-08 18-43-57](https://github.com/user-attachments/assets/c3d9f53f-130a-41c1-aba5-c07d3e0eb2e4)

---

### AXE D'AMELIORATION :

L'application est capable d'établir une connexion entre 2 pairs, refuser ou accepter la demande coté utilisateur, mais ensuite les messages ne s'envoient pas 🤡




