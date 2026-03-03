#!/usr/bin/env bash
# FitRPG Pi 5 Setup Script
# Run on a fresh Raspberry Pi OS Bookworm (64-bit) installation.
# Usage: bash setup.sh

set -e

REPO_DIR="$HOME/FitRPG"
REPO_URL="https://github.com/brcewayne80-dev/FitRPG.git"  # Update this

echo "=== FitRPG Pi Setup ==="

# System packages
sudo apt-get update
sudo apt-get install -y nginx flare-game unclutter git curl

# Install nvm (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

# Install Node 20 (required for Kaetram uWS)
nvm install 20
nvm use 20

# Clone or pull repo
if [ -d "$REPO_DIR" ]; then
  echo "Pulling latest..."
  git -C "$REPO_DIR" pull
else
  echo "Cloning repo..."
  git clone --depth=1 "$REPO_URL" "$REPO_DIR"
fi

# Copy .env.local
if [ ! -f "$REPO_DIR/web/.env.local" ]; then
  cp "$REPO_DIR/pi/.env.local.example" "$REPO_DIR/web/.env.local"
  echo "!! Edit $REPO_DIR/web/.env.local with your Supabase credentials"
fi

# Build Next.js dashboard
echo "=== Building Next.js dashboard ==="
cd "$REPO_DIR/web"
npm ci
npm run build

# Build Defend the Valley (Phaser)
echo "=== Building Defend the Valley ==="
cd "$REPO_DIR/games/defend-the-valley"
npm ci
npm run build

# Install Kaetram dependencies (needs Node 20)
echo "=== Installing Kaetram ==="
cd "$REPO_DIR/games/kaetram"
nvm use 20
yarn install

# Install systemd services
echo "=== Installing systemd services ==="
sudo cp "$REPO_DIR/pi/services/"*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fitrpg-dashboard kaetram-server fitrpg-kiosk
sudo systemctl start fitrpg-dashboard kaetram-server

# Configure nginx
echo "=== Configuring nginx ==="
sudo cp "$REPO_DIR/pi/nginx.conf" /etc/nginx/sites-available/fitrpg
sudo ln -sf /etc/nginx/sites-available/fitrpg /etc/nginx/sites-enabled/fitrpg
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo ""
echo "=== Setup complete! ==="
echo "Reboot to start the kiosk: sudo reboot"
echo ""
echo "Service status:"
sudo systemctl status fitrpg-dashboard --no-pager
sudo systemctl status kaetram-server --no-pager
