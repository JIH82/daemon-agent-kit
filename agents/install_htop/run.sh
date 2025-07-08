#!/bin/bash
echo "🛠 Installing htop..."
sudo apt update && sudo apt install -y htop
echo '{ "status": "complete", "message": "htop installed." }' > "$(dirname "$0")/status.json"

