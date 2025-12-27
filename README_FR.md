# qBittorrent avec VPN (WireGuard/OpenVPN)

[![Version](https://img.shields.io/badge/qBittorrent-5.1.4-blue)](https://github.com/qbittorrent/qBittorrent)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-GPL--3.0-orange)](LICENSE)

Container Docker incluant qBittorrent-nox (sans interface graphique) avec support VPN (WireGuard ou OpenVPN) et killswitch iptables pour éviter les fuites IP.

## ✨ Caractéristiques

- 🚀 **Toujours à jour** : Compilation automatique de la dernière version stable de qBittorrent
- 🔒 **Sécurisé** : Killswitch iptables pour bloquer le trafic si le VPN tombe
- 🌐 **Double VPN** : Support WireGuard ET OpenVPN
- 📦 **Léger** : Basé sur Debian Bullseye Slim
- ⚡ **Optimisé** : Compilation avec les dernières versions de libtorrent, Boost, CMake
- 🎯 **Interface Web** : Contrôle via WebUI sur port 8080
- 🔧 **Configurable** : Nombreuses options via variables d'environnement

## 🏗️ Versions incluses

Les versions sont récupérées automatiquement pendant le build :

| Composant | Version |
|-----------|---------|
| **qBittorrent** | Dernière release stable (actuellement v5.1.4) |
| **libtorrent** | RC_1_2 branch (dernière version) |
| **Boost** | Dernière version stable |
| **CMake** | Dernière version stable |
| **Qt** | Qt5 (pour compatibilité Debian Bullseye) |
| **Base** | Debian 11 (Bullseye) Slim |

## 📋 Prérequis

- Docker installé
- Support du kernel pour WireGuard (si utilisé)
- Configuration VPN (fichier .ovpn ou .conf)

## 🚀 Démarrage rapide

### 1. Build de l'image

#### Option A : Build manuel
```bash
docker build -t qbittorrentvpn:latest .
```

#### Option B : Script automatisé (recommandé)
```bash
chmod +x build.sh
./build.sh
```

Le script :
- ✅ Vérifie les prérequis
- ✅ Affiche la dernière version stable
- ✅ Build avec confirmation
- ✅ Affiche le temps de build
- ✅ Propose de tagger avec la version

### 2. Configuration VPN

#### Pour WireGuard

1. Placez votre fichier de configuration dans `/path/to/config/wireguard/`
2. **IMPORTANT** : Le fichier DOIT s'appeler `wg0.conf`

```bash
mkdir -p /path/to/config/wireguard
cp mon-vpn.conf /path/to/config/wireguard/wg0.conf
```

#### Pour OpenVPN

1. Placez votre fichier .ovpn dans `/path/to/config/openvpn/`
2. Si nécessaire, créez un fichier credentials.conf :

```bash
mkdir -p /path/to/config/openvpn
cp mon-vpn.ovpn /path/to/config/openvpn/
echo "username" > /path/to/config/openvpn/credentials.conf
echo "password" >> /path/to/config/openvpn/credentials.conf
```

### 3. Lancement du container

#### Avec WireGuard

```bash
docker run -d \
  --name qbittorrent-vpn \
  -v /path/to/config:/config \
  -v /path/to/downloads:/downloads \
  -e VPN_ENABLED=yes \
  -e VPN_TYPE=wireguard \
  -e LAN_NETWORK=192.168.1.0/24 \
  -p 8080:8080 \
  -p 8999:8999 \
  -p 8999:8999/udp \
  --cap-add NET_ADMIN \
  --sysctl "net.ipv4.conf.all.src_valid_mark=1" \
  --restart unless-stopped \
  qbittorrentvpn:latest
```

#### Avec OpenVPN

```bash
docker run -d \
  --name qbittorrent-vpn \
  -v /path/to/config:/config \
  -v /path/to/downloads:/downloads \
  -e VPN_ENABLED=yes \
  -e VPN_TYPE=openvpn \
  -e VPN_USERNAME=votre_username \
  -e VPN_PASSWORD=votre_password \
  -e LAN_NETWORK=192.168.1.0/24 \
  -p 8080:8080 \
  -p 8999:8999 \
  -p 8999:8999/udp \
  --cap-add NET_ADMIN \
  --sysctl "net.ipv4.conf.all.src_valid_mark=1" \
  --restart unless-stopped \
  qbittorrentvpn:latest
```

### 4. Accès à l'interface Web

Ouvrez votre navigateur : `https://VOTRE-IP:8080`

**Identifiants par défaut :**
- Username: `admin`
- Password: `adminadmin`

⚠️ **Changez immédiatement le mot de passe !**

## ⚙️ Variables d'environnement

| Variable | Obligatoire | Défaut | Description |
|----------|-------------|--------|-------------|
| `VPN_ENABLED` | Oui | `yes` | Activer le VPN (yes/no) |
| `VPN_TYPE` | Oui | `openvpn` | Type de VPN (wireguard/openvpn) |
| `VPN_USERNAME` | Non | - | Username VPN (OpenVPN) |
| `VPN_PASSWORD` | Non | - | Password VPN (OpenVPN) |
| `LAN_NETWORK` | Oui | - | Réseau local (ex: 192.168.1.0/24) |
| `NAME_SERVERS` | Non | `1.1.1.1,1.0.0.1` | Serveurs DNS |
| `PUID` | Non | `99` | User ID pour les fichiers |
| `PGID` | Non | `100` | Group ID pour les fichiers |
| `UMASK` | Non | `002` | Masque de permissions |
| `ENABLE_SSL` | Non | `yes` | Activer SSL pour WebUI |
| `HEALTH_CHECK_HOST` | Non | `one.one.one.one` | Host pour vérification réseau |
| `HEALTH_CHECK_INTERVAL` | Non | `300` | Intervalle de vérification (secondes) |
| `HEALTH_CHECK_SILENT` | Non | `1` | Masquer les messages de santé |
| `RESTART_CONTAINER` | Non | `yes` | Redémarrer si VPN tombe |
| `INSTALL_PYTHON3` | Non | `no` | Installer Python3 |
| `ADDITIONAL_PORTS` | Non | - | Ports additionnels (ex: 1234,8112) |
| `LEGACY_IPTABLES` | Non | - | Utiliser iptables legacy |

## 📂 Volumes

| Volume | Description |
|--------|-------------|
| `/config` | Configuration qBittorrent + VPN |
| `/downloads` | Dossier de téléchargements |

## 🔌 Ports

| Port | Protocole | Description |
|------|-----------|-------------|
| `8080` | TCP | Interface Web qBittorrent |
| `8999` | TCP | Port d'écoute BitTorrent |
| `8999` | UDP | Port d'écoute BitTorrent |

## 🐛 Dépannage

### Le VPN ne se connecte pas

1. Vérifiez les logs :
```bash
docker logs qbittorrent-vpn
```

2. Pour WireGuard, vérifiez que le fichier s'appelle bien `wg0.conf`

3. Pour OpenVPN, vérifiez le format de votre fichier .ovpn

### Fuites IP

Le container inclut un killswitch iptables. Si le VPN tombe, **aucun trafic ne passera**.

Pour tester :
```bash
# Dans le container
docker exec -it qbittorrent-vpn curl ifconfig.me
```

### Permissions sur les fichiers

Si vous avez des problèmes de permissions :

```bash
# Trouver votre UID/GID
id

# Ajustez PUID et PGID
docker run ... -e PUID=1000 -e PGID=1000 ...
```

### IPv6 et WireGuard

Si vous utilisez IPv6 avec WireGuard :

1. Ajoutez le range IPv6 à LAN_NETWORK :
```bash
-e LAN_NETWORK=192.168.1.0/24,fd00::/8
```

2. Ajoutez le paramètre sysctl :
```bash
--sysctl net.ipv6.conf.all.disable_ipv6=0
```

## 🔄 Mise à jour

Pour mettre à jour vers la dernière version de qBittorrent :

```bash
# 1. Arrêtez le container
docker stop qbittorrent-vpn
docker rm qbittorrent-vpn

# 2. Rebuild l'image
./build.sh

# 3. Relancez avec la même commande docker run
```

⚠️ **Vos configurations et téléchargements sont préservés dans les volumes !**

## 📊 Vérification de la version

Pour connaître la version de qBittorrent installée :

```bash
docker exec -it qbittorrent-vpn qbittorrent-nox --version
```

## 🎯 Docker Compose

Exemple de fichier `docker-compose.yml` :

```yaml
version: '3.8'

services:
  qbittorrent-vpn:
    image: qbittorrentvpn:latest
    container_name: qbittorrent-vpn
    cap_add:
      - NET_ADMIN
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    environment:
      - VPN_ENABLED=yes
      - VPN_TYPE=wireguard
      - LAN_NETWORK=192.168.1.0/24
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
    volumes:
      - ./config:/config
      - ./downloads:/downloads
    ports:
      - "8080:8080"
      - "8999:8999"
      - "8999:8999/udp"
    restart: unless-stopped
```

Lancement :
```bash
docker-compose up -d
```

## 📝 Notes importantes

1. **Première utilisation** : Le premier démarrage peut prendre quelques secondes le temps que qBittorrent génère sa configuration

2. **SSL** : Par défaut, l'interface Web utilise HTTPS avec un certificat auto-signé. Votre navigateur affichera un avertissement (normal).

3. **VPN obligatoire** : Si `VPN_ENABLED=yes`, le container ne démarrera pas sans fichier de configuration VPN valide

4. **Killswitch** : Le trafic est **complètement bloqué** si le VPN tombe (sécurité maximale)

5. **Performance** : Le build prend 20-30 minutes (compilation from source) mais le résultat est optimisé

## 🤝 Contribution

N'hésitez pas à :
- Signaler des bugs
- Proposer des améliorations
- Soumettre des pull requests

## 📜 Licence

Ce projet est sous licence GPL-3.0. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

Basé sur le travail de :
- [DyonR/docker-qbittorrentvpn](https://github.com/DyonR/docker-qbittorrentvpn)
- [MarkusMcNugen/docker-qBittorrentvpn](https://github.com/MarkusMcNugen/docker-qBittorrentvpn)

---

**Fait avec ❤️ par Mehdi**

*Dernière mise à jour : 27 décembre 2024*
