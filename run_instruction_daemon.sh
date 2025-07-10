#!/bin/bash

# ============================================================
# 🔁 PHASE 4: Instruction Daemon (Safe Test Loop)
# ============================================================

clear
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="logs"
INSTRUCTIONS_DIR="instructions"
SCRIPT="full_instruction_exec.sh"
CYCLE_LIMIT=5
SLEEP_INTERVAL=5

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/daemon_run_$TIMESTAMP.log"

FORMAT="plain"
[[ "$1" == "--json" ]] && FORMAT="json"
[[ "$1" == "--yaml" ]] && FORMAT="yaml"
[[ "$1" == "--dry-run" ]] && DRY_RUN=1 || DRY_RUN=0

{
echo "============================================================"
echo "🤖 PHASE 4: INSTRUCTION DAEMON (Safe Test Mode)"
echo "============================================================"
echo "🕒 Started at: $(date)"
echo

## STEP 1: Environment Check
echo "## STEP 1: Environment Check"
echo "-----------------------------------------------"
MISSING=0
[[ -x "$SCRIPT" ]] && echo "✅ $SCRIPT found" || { echo "❌ $SCRIPT missing or not executable"; MISSING=1; }
[[ -d "$INSTRUCTIONS_DIR" ]] && echo "✅ $INSTRUCTIONS_DIR exists" || { echo "❌ $INSTRUCTIONS_DIR missing"; MISSING=1; }

command -v bash >/dev/null || { echo "❌ bash not found"; MISSING=1; }

if [[ "$MISSING" -eq 1 ]]; then
  echo "# AI:Section=Validation"
  echo "# AI:NeedsReview=true"
  echo "🚫 Aborting due to missing requirements"
  exit 1
fi

## STEP 2: Begin Loop
echo
echo "## STEP 2: Start Instruction Loop"
echo "-----------------------------------------------"
echo "🔁 Max cycles: $CYCLE_LIMIT"
echo "⏲️  Sleep interval: $SLEEP_INTERVAL sec"
[[ $DRY_RUN -eq 1 ]] && echo "🚧 DRY-RUN mode active: instructions will not be executed"
echo

cycles=0
executed=0

while [[ "$cycles" -lt "$CYCLE_LIMIT" ]]; do
  echo "🔄 Cycle $((cycles + 1)) / $CYCLE_LIMIT"

  file=$(find "$INSTRUCTIONS_DIR" -maxdepth 1 -name "*.instruction.txt" | sort | head -n 1)

  if [[ -n "$file" ]]; then
    echo "📄 Found: $file"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "🚧 Would run: $SCRIPT $file"
    else
      bash "$SCRIPT"
      rc=$?
      if [[ "$rc" -ne 0 ]]; then
        echo "❌ Instruction failed: $file"
        echo "# AI:Section=Validation"
        echo "# AI:NeedsReview=true"
        echo "🛠️ Creating diagnostic script..."

        DIAG_SCRIPT="$LOG_DIR/diagnostic_failed_exec_${TIMESTAMP}.sh"
        cat > "$DIAG_SCRIPT" <<DIAG
#!/bin/bash
echo "📁 Log tail from last execution:"
tail -n 20 "$LOG_FILE"
echo "📁 Instruction that failed:"
cat "$file"
DIAG
        chmod +x "$DIAG_SCRIPT"
        echo "💡 Run: bash $DIAG_SCRIPT"
      else
        ((executed++))
      fi
    fi
  else
    echo "🟡 No new instruction found"
  fi

  ((cycles++))
  echo
  sleep "$SLEEP_INTERVAL"
done

## STEP 3: Summary
echo "## STEP 3: Final Report"
echo "-----------------------------------------------"
echo "✅ Total cycles: $CYCLE_LIMIT"
echo "📦 Instructions executed: $executed"

if [[ "$FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"status\": \"complete\","
  echo "  \"cycles\": $CYCLE_LIMIT,"
  echo "  \"executed\": $executed,"
  echo "  \"log\": \"$LOG_FILE\""
  echo "}"
elif [[ "$FORMAT" == "yaml" ]]; then
  echo "status: complete"
  echo "cycles: $CYCLE_LIMIT"
  echo "executed: $executed"
  echo "log: $LOG_FILE"
else
  echo "✅ Use --json or --yaml for structured output"
fi

echo
echo "============================================================"
echo "🏁 Done — Log saved to: $LOG_FILE"
echo "============================================================"

} 2>&1 | tee "$LOG_FILE"
