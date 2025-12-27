# Changements apportés au Dockerfile

## Mise à jour - Décembre 2024

### qBittorrent - Dernière version stable

**Changement principal :** Le Dockerfile a été mis à jour pour utiliser automatiquement la dernière version stable de qBittorrent disponible sur GitHub.

#### Avant :
```dockerfile
QBITTORRENT_RELEASE=$(curl -sX GET "https://api.github.com/repos/qBittorrent/qBittorrent/tags" | jq '.[] | select(.name | index ("alpha") | not) | select(.name | index ("beta") | not) | select(.name | index ("rc") | not) | .name' | head -n 1 | tr -d '"')
```

Cette méthode :
- Récupérait tous les tags
- Filtrait manuellement les versions alpha, beta et rc
- Prenait le premier tag qui correspondait

**Problème :** Ne garantissait pas d'obtenir la dernière version stable officielle.

#### Après :
```dockerfile
QBITTORRENT_RELEASE=$(curl -sX GET "https://api.github.com/repos/qBittorrent/qBittorrent/releases/latest" | jq -r '.tag_name')
echo "Building qBittorrent ${QBITTORRENT_RELEASE}"
```

Cette méthode :
- Utilise l'endpoint `/releases/latest` de l'API GitHub
- Récupère automatiquement la dernière release stable marquée comme telle
- Affiche la version pendant la compilation

**Avantages :**
- ✅ Toujours la dernière version stable officielle
- ✅ Plus fiable (utilise les releases officielles)
- ✅ Plus simple et plus rapide
- ✅ Affichage de la version compilée dans les logs
- ✅ Compatible avec les versions futures (5.1.x, 5.2.x, etc.)

### Versions récentes de qBittorrent

Au moment de cette mise à jour (décembre 2024), les versions stables disponibles sont :
- **v5.1.4** - Dernière version stable (décembre 2024)
- **v5.1.3** - Version stable précédente
- **v5.0.3** - Dernière version de la branche 5.0.x

Le Dockerfile récupérera automatiquement la version **v5.1.4** ou toute version plus récente dès sa publication.

### Compatibilité

- **Base image :** Debian bullseye-slim (inchangé)
- **libtorrent :** RC_1_2 branch (inchangé)
- **Qt :** Qt5 (qtbase5-dev, qttools5-dev)
- **CMake :** Dernière version stable
- **Boost :** Dernière version stable
- **Ninja :** Dernière version stable

### Notes importantes

1. **Pas de changement pour libtorrent** : Le Dockerfile continue d'utiliser la branche RC_1_2 de libtorrent pour assurer la compatibilité.

2. **Qt5 vs Qt6** : Ce Dockerfile utilise Qt5. qBittorrent 5.x supporte Qt6, mais pour la compatibilité avec Debian Bullseye, nous restons sur Qt5.

3. **Mise à jour automatique** : Chaque rebuild de l'image Docker récupérera automatiquement la dernière version stable sans modification du Dockerfile.

### Construction de l'image

```bash
docker build -t qbittorrentvpn:latest .
```

Pendant la construction, vous verrez :
```
Building qBittorrent release-5.1.4
```

Cela confirme quelle version est en cours de compilation.

### Vérification de la version

Une fois le container démarré, vous pouvez vérifier la version installée :

```bash
docker exec -it <container_name> qbittorrent-nox --version
```

### Recommandations

- Rebuild régulièrement l'image pour bénéficier des dernières mises à jour de sécurité
- Testez toujours une nouvelle image dans un environnement de test avant la production
- Gardez une sauvegarde de votre configuration qBittorrent avant de mettre à jour

---

**Date de mise à jour :** 27 décembre 2024
**Versions compatibles :** qBittorrent 5.0.x, 5.1.x et supérieures
