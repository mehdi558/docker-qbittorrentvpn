# 🚀 Guide de Démarrage Rapide - qBittorrent VPN

## Prérequis (5 minutes)

### 1. Installer Docker

**Debian/Ubuntu :**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Déconnectez-vous et reconnectez-vous
```

### 2. Vérifier l'installation
```bash
docker --version
docker ps
```

## Installation WireGuard (10 minutes)

### 1. Créer la structure
```bash
mkdir -p ~/qbittorrent-docker/{config/wireguard,downloads}
cd ~/qbittorrent-docker
```

### 2. Récupérer le projet
```bash
# Téléchargez ou clonez le Dockerfile et les scripts
# Copiez vos fichiers ici
```

### 3. Configurer WireGuard
```bash
# Copiez votre fichier de configuration VPN
# IMPORTANT: Il DOIT s'appeler wg0.conf
cp /chemin/vers/votre-config.conf config/wireguard/wg0.conf
```

**Vérification :**
```bash
cat config/wireguard/wg0.conf
# Vous devriez voir [Interface] et [Peer]
```

### 4. Build de l'image (20-30 minutes)
```bash
chmod +x build.sh
./build.sh
```

**Attendez** - C'est normal que ça prenne du temps (compilation from source)

### 5. Configurer votre réseau local
```bash
# Trouvez votre plage IP
ip route | grep default
# Exemple de sortie: default via 192.168.1.1 dev eth0
# Votre réseau est probablement: 192.168.1.0/24
```

### 6. Trouver votre PUID/PGID
```bash
id
# uid=1000(mehdi) gid=1000(mehdi)
# Utilisez ces valeurs pour PUID et PGID
```

### 7. Lancement
```bash
docker run -d \
  --name qbittorrent-vpn \
  -v $(pwd)/config:/config \
  -v $(pwd)/downloads:/downloads \
  -e VPN_ENABLED=yes \
  -e VPN_TYPE=wireguard \
  -e LAN_NETWORK=192.168.1.0/24 \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 8080:8080 \
  -p 8999:8999 \
  -p 8999:8999/udp \
  --cap-add NET_ADMIN \
  --sysctl "net.ipv4.conf.all.src_valid_mark=1" \
  --restart unless-stopped \
  qbittorrentvpn:latest
```

### 8. Vérifier les logs
```bash
docker logs -f qbittorrent-vpn
```

**Attendez de voir :**
- `[INFO] Starting WireGuard...`
- `[INFO] Started qBittorrent daemon successfully...`

### 9. Accéder à l'interface
Ouvrez votre navigateur : `https://VOTRE-IP:8080`

**Identifiants :**
- Username: `admin`
- Password: `adminadmin`

**⚠️ CHANGEZ LE MOT DE PASSE IMMÉDIATEMENT !**

### 10. Vérifier l'IP (Important !)
Dans le container :
```bash
docker exec -it qbittorrent-vpn curl ifconfig.me
```

Cette IP doit être celle de votre VPN, **PAS votre IP réelle !**

## Installation OpenVPN (10 minutes)

Même procédure, mais :

### Étape 3 bis : Configurer OpenVPN
```bash
# Copier le fichier .ovpn
cp /chemin/vers/votre-vpn.ovpn config/openvpn/

# Créer le fichier de credentials (si nécessaire)
echo "votre_username" > config/openvpn/credentials.conf
echo "votre_password" >> config/openvpn/credentials.conf
chmod 600 config/openvpn/credentials.conf
```

### Étape 7 bis : Lancement OpenVPN
```bash
docker run -d \
  --name qbittorrent-vpn \
  -v $(pwd)/config:/config \
  -v $(pwd)/downloads:/downloads \
  -e VPN_ENABLED=yes \
  -e VPN_TYPE=openvpn \
  -e VPN_USERNAME=votre_username \
  -e VPN_PASSWORD=votre_password \
  -e LAN_NETWORK=192.168.1.0/24 \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 8080:8080 \
  -p 8999:8999 \
  -p 8999:8999/udp \
  --cap-add NET_ADMIN \
  --sysctl "net.ipv4.conf.all.src_valid_mark=1" \
  --restart unless-stopped \
  qbittorrentvpn:latest
```

## Avec Docker Compose (5 minutes)

### 1. Modifier le fichier docker-compose.yml
```bash
nano docker-compose.yml
```

Modifiez au minimum :
- `LAN_NETWORK` (votre réseau local)
- `PUID` et `PGID` (votre uid/gid)
- `VPN_TYPE` (wireguard ou openvpn)

### 2. Lancer
```bash
docker-compose up -d
```

### 3. Vérifier
```bash
docker-compose logs -f
```

## Commandes Utiles

### Logs en temps réel
```bash
docker logs -f qbittorrent-vpn
```

### Arrêter
```bash
docker stop qbittorrent-vpn
```

### Démarrer
```bash
docker start qbittorrent-vpn
```

### Redémarrer
```bash
docker restart qbittorrent-vpn
```

### Entrer dans le container
```bash
docker exec -it qbittorrent-vpn bash
```

### Vérifier l'IP du VPN
```bash
docker exec -it qbittorrent-vpn curl ifconfig.me
```

### Supprimer le container
```bash
docker stop qbittorrent-vpn
docker rm qbittorrent-vpn
```

### Supprimer l'image
```bash
docker rmi qbittorrentvpn:latest
```

## Problèmes Courants

### "VPN config file not found"
- Vérifiez que le fichier existe dans le bon dossier
- Pour WireGuard: DOIT être `wg0.conf`
- Pour OpenVPN: doit avoir l'extension `.ovpn`

### "Permission denied" sur /downloads
```bash
# Vérifiez vos PUID/PGID
id

# Changez les permissions
sudo chown -R 1000:1000 downloads/
```

### Interface Web inaccessible
```bash
# Vérifiez que le container tourne
docker ps | grep qbittorrent

# Vérifiez les logs
docker logs qbittorrent-vpn

# Vérifiez le port
netstat -tlnp | grep 8080
```

### Le VPN ne se connecte pas
```bash
# Vérifiez les logs en détail
docker logs qbittorrent-vpn 2>&1 | grep -i error

# Vérifiez la config WireGuard
docker exec -it qbittorrent-vpn cat /config/wireguard/wg0.conf

# Vérifiez la config OpenVPN
docker exec -it qbittorrent-vpn cat /config/openvpn/*.ovpn
```

### Téléchargements lents
1. Vérifiez votre connexion VPN
2. Configurez les limites dans qBittorrent
3. Testez votre vitesse : https://fast.com

## Configuration Post-Installation

### 1. Changer le mot de passe
WebUI → Tools → Options → Web UI → Authentication

### 2. Configurer les chemins
WebUI → Tools → Options → Downloads
- Default Save Path: `/downloads`
- Temp Path: `/downloads/temp`

### 3. Activer le port forwarding (si supporté par votre VPN)
WebUI → Tools → Options → Connection
- Listening Port: 8999

### 4. Optimiser les performances
WebUI → Tools → Options → BitTorrent
- Maximum active downloads: 5
- Maximum active torrents: 10

### 5. Activer les recherches (optionnel)
WebUI → Search → Search plugins → Install new plugin

## Checklist Finale

- [ ] Build réussi
- [ ] Container démarré sans erreur
- [ ] WebUI accessible
- [ ] Mot de passe changé
- [ ] IP VPN vérifiée (curl ifconfig.me)
- [ ] Test de téléchargement d'un torrent légal
- [ ] Vérification des permissions sur /downloads

## Support

Si vous avez des problèmes :

1. Consultez les logs : `docker logs qbittorrent-vpn`
2. Vérifiez le README complet
3. Ouvrez une issue sur GitHub

---

**Temps total estimé : 45-60 minutes**

Bon téléchargement ! 🚀
