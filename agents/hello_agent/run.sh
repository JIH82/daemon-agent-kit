#!/bin/bash
echo "👋 Hello from hello_agent!" | tee -a "$(dirname "$0")/../../logs/hello_agent.log"
echo '{ "status": "complete", "message": "Hello agent ran successfully." }' > "$(dirname "$0")/status.json"
