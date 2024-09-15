# Jeedom docker environment

Environement de développment pour jeedom.

## Installation

Créer le fichier `.env` via la commande `make .env` et personnaliser les variables, principalement le repository.

Pour installer et lancer le projet : `make up`

## Commandes utiles

```bash
# Build les images
make build
```

```bash
# Lancer l’environement
make up
```

```bash
# Suivre les logs
make logs
```

```bash
# Ouvrir un bash dans le container docker
make bash
```
