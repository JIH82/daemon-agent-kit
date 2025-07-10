#!/bin/bash

echo "🔧 Starting full daemon-agent-kit system..."

LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# 1. Start LLM
echo "🚀 Starting Ollama and model: llama3"
if ! pgrep -f "ollama serve" > /dev/null; then
    ollama serve > "$LOG_DIR/ollama_start.log" 2>&1 &
    sleep 2  # Let Ollama spin up
fi

# Load model if not already loaded
if ! curl -s http://localhost:11434/api/tags | grep -q "llama3"; then
    ollama run llama3 > /dev/null &
    sleep 3
fi

# 2. Start daemon
echo "🌀 Starting daemon..."
python3 scripts/daemon.py > "$LOG_DIR/daemon.log" 2>&1 &

# 3. Start instruction processor
echo "📋 Starting instruction processor..."
python3 scripts/process_instructions.py > "$LOG_DIR/system_agent.log" 2>&1 &

echo "✅ All components started."
