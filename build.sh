#!/bin/bash
# Script de build amélioré pour qBittorrent VPN Docker
# Auteur: Mehdi
# Date: 27 décembre 2024

set -e  # Arrêt en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║      qBittorrent VPN Docker - Script de Build            ║
║      Version automatique avec dernière release stable     ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Vérification des prérequis
info "Vérification des prérequis..."

if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé!"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    warning "jq n'est pas installé. Installation recommandée pour voir la version."
    warning "Sous Debian/Ubuntu: sudo apt install jq"
fi

# Récupération de la dernière version de qBittorrent
info "Récupération de la dernière version stable de qBittorrent..."

if command -v jq &> /dev/null; then
    LATEST_VERSION=$(curl -s https://api.github.com/repos/qBittorrent/qBittorrent/releases/latest | jq -r '.tag_name')
    if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
        warning "Impossible de récupérer la version. Le build utilisera l'API automatiquement."
        LATEST_VERSION="latest"
    else
        success "Dernière version stable: ${GREEN}${LATEST_VERSION}${NC}"
    fi
else
    LATEST_VERSION="latest"
    info "Version: ${LATEST_VERSION} (sera récupérée pendant le build)"
fi

# Configuration
IMAGE_NAME="${IMAGE_NAME:-qbittorrentvpn}"
TAG="${TAG:-latest}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

info "Image qui sera créée: ${GREEN}${FULL_IMAGE_NAME}${NC}"

# Demande de confirmation
read -p "$(echo -e ${YELLOW}Voulez-vous continuer avec le build? [Y/n]${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    warning "Build annulé par l'utilisateur."
    exit 0
fi

# Build de l'image
info "Démarrage du build Docker..."
info "Cela peut prendre 20-30 minutes selon votre connexion et CPU..."

BUILD_START=$(date +%s)

if docker build -t "${FULL_IMAGE_NAME}" .; then
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    BUILD_TIME_MIN=$((BUILD_TIME / 60))
    BUILD_TIME_SEC=$((BUILD_TIME % 60))
    
    echo ""
    success "╔═══════════════════════════════════════════════════════╗"
    success "║         Build terminé avec succès! 🎉                ║"
    success "╚═══════════════════════════════════════════════════════╝"
    success "Image: ${FULL_IMAGE_NAME}"
    success "Temps de build: ${BUILD_TIME_MIN}m ${BUILD_TIME_SEC}s"
    
    # Affichage de la taille de l'image
    IMAGE_SIZE=$(docker images "${FULL_IMAGE_NAME}" --format "{{.Size}}")
    info "Taille de l'image: ${IMAGE_SIZE}"
    
    echo ""
    info "Pour démarrer le container, utilisez:"
    echo -e "${GREEN}docker run -d \\"
    echo "  --name qbittorrent-vpn \\"
    echo "  -v /path/to/config:/config \\"
    echo "  -v /path/to/downloads:/downloads \\"
    echo "  -e VPN_ENABLED=yes \\"
    echo "  -e VPN_TYPE=wireguard \\"
    echo "  -e LAN_NETWORK=192.168.1.0/24 \\"
    echo "  -p 8080:8080 \\"
    echo "  -p 8999:8999 \\"
    echo "  -p 8999:8999/udp \\"
    echo "  --cap-add NET_ADMIN \\"
    echo "  --sysctl \"net.ipv4.conf.all.src_valid_mark=1\" \\"
    echo "  --restart unless-stopped \\"
    echo "  ${FULL_IMAGE_NAME}${NC}"
    
else
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    error "Le build a échoué après ${BUILD_TIME} secondes!"
    exit 1
fi

# Option pour tagger l'image avec la version
if [ "$LATEST_VERSION" != "latest" ] && [ ! -z "$LATEST_VERSION" ]; then
    echo ""
    read -p "$(echo -e ${YELLOW}Voulez-vous aussi tagger l\'image avec la version ${LATEST_VERSION}? [Y/n]${NC} )" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        VERSIONED_TAG="${IMAGE_NAME}:${LATEST_VERSION}"
        docker tag "${FULL_IMAGE_NAME}" "${VERSIONED_TAG}"
        success "Image également taggée comme: ${VERSIONED_TAG}"
    fi
fi

echo ""
success "Build terminé! 🚀"
