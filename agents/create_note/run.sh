#!/bin/bash
echo "📝 Creating test note..."
echo "This is a test note created by the agent system." > /tmp/test_note.txt

if [[ -f /tmp/test_note.txt ]]; then
  echo '{ "status": "complete", "message": "Note created at /tmp/test_note.txt" }' > "$(dirname "$0")/status.json"
  exit 0
else
  echo '{ "status": "error", "message": "Failed to create note." }' > "$(dirname "$0")/status.json"
  exit 1
fi
