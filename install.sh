#!/bin/bash
# =============================================================================
# Soteria — bootstrap script
# Run once on a fresh Rocky Linux 9.5 install.
# After this script: restore data from TrueNAS, restore secrets, then make up.
# =============================================================================

set -euo pipefail

# --- Guards ------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

echo "==> Starting Soteria bootstrap"

# --- System update + base dependencies ---------------------------------------

echo "==> Updating system and installing base dependencies"
dnf update -y
dnf install -y git make rsync curl

# --- Docker ------------------------------------------------------------------

echo "==> Installing Docker"
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
echo "    Docker $(docker --version) installed and running"

# --- Directory structure -----------------------------------------------------

echo "==> Creating /opt/stacks"
mkdir -p /opt/stacks

echo "==> Creating /var/lib/docker-compose data directories"
mkdir -p \
  /var/lib/docker-compose/sot-prod-auth-authentik_certs \
  /var/lib/docker-compose/sot-prod-auth-authentik_data \
  /var/lib/docker-compose/sot-prod-auth-authentik-postgres_data \
  /var/lib/docker-compose/sot-prod-auth-authentik_templates \
  /var/lib/docker-compose/sot-prod-dns-adguard/conf \
  /var/lib/docker-compose/sot-prod-dns-adguard/work \
  /var/lib/docker-compose/sot-prod-proxy-nginx_data \
  /var/lib/docker-compose/sot-prod-proxy-nginx_letsencrypt \
  /var/lib/docker-compose/sot-prod-wiki-wikijs-wiki_data_content \
  /var/lib/docker-compose/sot-prod-wiki-wikijs-wikidb_data

# --- Clone repo --------------------------------------------------------------

echo "==> Cloning soteria-compose"
if [[ -d /opt/stacks/soteria-compose ]]; then
  echo "    /opt/stacks/soteria-compose already exists, pulling latest"
  git -C /opt/stacks/soteria-compose pull
else
  git clone https://github.com/maakleerplek/soteria_compose.git /opt/stacks/soteria-compose
fi

# --- Done --------------------------------------------------------------------

echo ""
echo "==> Bootstrap complete. Next steps:"
echo ""
echo "  1. Restore data from TrueNAS:"
echo "       rsync -az hel-prod-nas-truenas:/mnt/pool/backups/soteria/docker_data/ /var/lib/docker-compose/"
echo ""
echo "  2. Restore secrets:"
echo "       rsync -az hel-prod-nas-truenas:/mnt/pool/backups/soteria/secrets/.env /opt/stacks/soteria-compose/secrets/.env"
echo "       # Or retrieve from Bitwarden and create secrets/.env manually"
echo ""
echo "  3. Deploy:"
echo "       cd /opt/stacks/soteria-compose && make up"
echo ""
