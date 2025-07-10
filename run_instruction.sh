#!/bin/bash

# ============================================================
# 🚀 One-Shot Instruction Executor (Phase 2.5)
# ============================================================

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="logs"
OUT_DIR="output"
INSTRUCTIONS_DIR="instructions"
mkdir -p "$LOG_DIR" "$OUT_DIR" "$INSTRUCTIONS_DIR"
LOG_FILE="$LOG_DIR/instruction_run_${TIMESTAMP}.log"

FORMAT="plain"
[[ "$1" == "--json" ]] && FORMAT="json"
[[ "$1" == "--yaml" ]] && FORMAT="yaml"
[[ "$1" == "--dry-run" ]] && DRY_RUN=1 || DRY_RUN=0

{
echo "============================================================"
echo "🧠 EXECUTE FIRST INSTRUCTION FILE"
echo "============================================================"
echo "🕒 Started at: $(date)"
echo

## STEP 1: Environment Check
echo "## STEP 1: Environment Check"
echo "-----------------------------------------------"
REQUIRED_FILES=("lib/llm_client.py" "$INSTRUCTIONS_DIR" "$OUT_DIR")
MISSING=0

for file in "${REQUIRED_FILES[@]}"; do
  if [[ -e "$file" ]]; then
    echo "✅ $file exists"
  else
    echo "❌ $file missing"
    MISSING=1
  fi
done

if ! command -v python3 >/dev/null; then
  echo "❌ python3 not found in PATH"
  MISSING=1
fi

if [[ $MISSING -eq 1 ]]; then
  echo "# AI:Section=Validation"
  echo "# AI:NeedsReview=true"
  echo "🚫 Missing environment components."
  echo "🛠️ Creating diagnostic script..."
  DIAG_SCRIPT="$LOG_DIR/diagnostic_envfail_$TIMESTAMP.sh"
  cat > "$DIAG_SCRIPT" <<DIAG
#!/bin/bash
echo "📂 Expected files:"
for f in "${REQUIRED_FILES[@]}"; do [[ -e "\$f" ]] && echo "✅ \$f" || echo "❌ \$f"; done
python3 --version || echo "❌ python3 missing"
DIAG
  chmod +x "$DIAG_SCRIPT"
  echo "💡 Run: bash $DIAG_SCRIPT"
  echo "📂 Log saved to: $LOG_FILE"
  exit 1
fi

## STEP 2: Dry-Run Mode
echo
echo "## STEP 2: Dry-Run Mode"
echo "-----------------------------------------------"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "🚧 Dry-run mode active — no execution"
  echo "📂 Log saved to: $LOG_FILE"
  exit 0
fi

## STEP 3: Load First Instruction
echo
echo "## STEP 3: Load First .instruction.txt"
echo "-----------------------------------------------"
INSTRUCTION_FILE=$(find "$INSTRUCTIONS_DIR" -maxdepth 1 -name "*.instruction.txt" | sort | head -n 1)

if [[ -z "$INSTRUCTION_FILE" ]]; then
  echo "❌ No .instruction.txt file found in $INSTRUCTIONS_DIR"
  echo "# AI:Section=Validation"
  echo "# AI:NeedsReview=true"
  exit 1
fi

echo "📄 Using: $INSTRUCTION_FILE"
INSTRUCTION=$(<"$INSTRUCTION_FILE")
echo "📤 Prompt:"
echo "$INSTRUCTION"
echo

## STEP 4: Send to LLM Client
echo
echo "## STEP 4: LLM Execution"
echo "-----------------------------------------------"
RESPONSE=$(python3 lib/llm_client.py "$INSTRUCTION")
if [[ -z "$RESPONSE" ]]; then
  echo "❌ LLM gave no response"
  echo "# AI:Section=Validation"
  echo "# AI:NeedsReview=true"
  echo "🛠️ Creating diagnostic script..."
  DIAG_SCRIPT="$LOG_DIR/diagnostic_llmfail_${TIMESTAMP}.sh"
  cat > "$DIAG_SCRIPT" <<DIAG
#!/bin/bash
echo "📁 Checking llm_debug.log:"
tail -n 20 logs/llm_debug.log
echo "🌐 Checking Ollama:"
curl -s http://localhost:11434/api/tags || echo "❌ Ollama offline"
DIAG
  chmod +x "$DIAG_SCRIPT"
  echo "💡 Run: bash $DIAG_SCRIPT"
  echo "📂 Log saved to: $LOG_FILE"
  exit 1
fi
echo "✅ LLM responded"

## STEP 5: Save Response
echo
echo "## STEP 5: Save LLM Output"
echo "-----------------------------------------------"
OUT_FILE="$OUT_DIR/llm_response_${TIMESTAMP}.txt"
echo "$RESPONSE" > "$OUT_FILE"
echo "✅ Saved to: $OUT_FILE"

## STEP 6: Output Format
echo
echo "## STEP 6: Output Format"
echo "-----------------------------------------------"
if [[ "$FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"status\": \"success\","
  echo "  \"instruction_file\": \"$INSTRUCTION_FILE\","
  echo "  \"response_file\": \"$OUT_FILE\","
  echo "  \"timestamp\": \"$TIMESTAMP\""
  echo "}"
elif [[ "$FORMAT" == "yaml" ]]; then
  echo "status: success"
  echo "instruction_file: \"$INSTRUCTION_FILE\""
  echo "response_file: \"$OUT_FILE\""
  echo "timestamp: \"$TIMESTAMP\""
else
  echo "ℹ️ Use --json or --yaml for structured output."
fi

echo
echo "============================================================"
echo "🏁 Script complete"
echo "📂 Log saved to: $LOG_FILE"
echo "============================================================"

} 2>&1 | tee "$LOG_FILE"
