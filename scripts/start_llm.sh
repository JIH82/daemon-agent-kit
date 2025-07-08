#!/bin/bash

LOGFILE="logs/ollama_start.log"
MODEL="${1:-llama3}"  # Default to llama3 if not passed as argument

echo "🚀 Starting Ollama and loading model: $MODEL" | tee "$LOGFILE"

# Start Ollama in the background if it's not running
if ! pgrep -f "ollama serve" >/dev/null; then
    nohup ollama serve >> "$LOGFILE" 2>&1 &
    echo "🌀 Ollama server started." | tee -a "$LOGFILE"
    sleep 3
else
    echo "✅ Ollama server already running." | tee -a "$LOGFILE"
fi

# Pull model if not available
if ! ollama list | grep -q "$MODEL"; then
    echo "⬇️ Pulling model: $MODEL" | tee -a "$LOGFILE"
    ollama pull "$MODEL" >> "$LOGFILE" 2>&1
else
    echo "📦 Model '$MODEL' already available." | tee -a "$LOGFILE"
fi

# Ping the model to ensure it's ready
echo "📡 Testing model response..." | tee -a "$LOGFILE"
curl -s http://localhost:11434/api/generate -d "{\"model\": \"$MODEL\", \"prompt\": \"Say hello\"}" \
    | tee -a "$LOGFILE"

echo "✅ Ollama startup script completed." | tee -a "$LOGFILE"
