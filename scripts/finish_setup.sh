#!/bin/bash

set -e
cd "$(dirname "$0")/.."

mkdir -p agents/meta_decider lib logs output

# -----------------------------
# ✅ Add llm_client.py if missing
# -----------------------------
if [ ! -f lib/llm_client.py ]; then
  cat > lib/llm_client.py << 'EOF'
import requests

def query_llm(prompt, model="llama3"):
    url = "http://localhost:11434/api/generate"
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    try:
        response = requests.post(url, json=data)
        response.raise_for_status()
        return response.json().get("response", "(no response)").strip()
    except Exception as e:
        return f"(error contacting LLM: {e})"
EOF
fi

# -----------------------------
# ✅ Create meta_decider agent
# -----------------------------
mkdir -p agents/meta_decider
cat > agents/meta_decider/run.sh << 'EOF'
#!/bin/bash

INSTRUCTION_FILE="$1"
STATUS_FILE="$(dirname "$0")/status.json"

prompt="You are a helpful agent system. Given the contents of this file, describe what task should be performed: \n\n"
prompt+="$(cat "$INSTRUCTION_FILE")"

RESPONSE=$(python3 -c "from lib.llm_client import query_llm; print(query_llm(\"$prompt\"))")

echo "$RESPONSE" > output/meta_response.txt
echo "{ \"status\": \"complete\", \"message\": \"$RESPONSE\" }" > "$STATUS_FILE"
EOF
chmod +x agents/meta_decider/run.sh

echo '{"name": "meta_decider", "description": "Decides what to do based on instructions."}' > agents/meta_decider/agent.yaml

touch agents/meta_decider/status.json

# -----------------------------
# ✅ Modify process_instructions.py to fallback to meta_decider
# -----------------------------
PROCESSOR_PATH=scripts/process_instructions.py
if ! grep -q meta_decider "$PROCESSOR_PATH"; then
  sed -i '/# Load instruction/a \
        agent = "meta_decider"  # fallback to LLM if unknown
' "$PROCESSOR_PATH"
fi

# -----------------------------
# ✅ Add test instruction
# -----------------------------
echo "List all files in the home directory." > instructions/list_home_files

# -----------------------------
# ✅ Done
# -----------------------------
echo "✅ Phase 2 complete, Phase 3 started. Meta-agent created, test instruction queued."
echo "📂 Check output/meta_response.txt and logs/system_agent.log after processing."
