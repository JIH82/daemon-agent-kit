#!/bin/bash
echo "📄 Listing files in \$HOME..."
ls ~ > output/list_home_files.txt
echo '{"status": "complete", "timestamp": "'$(date)'"}' > agents/list_home_files/status.json
