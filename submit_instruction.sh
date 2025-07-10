#!/bin/bash

clear
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$BASE_DIR/logs"
INSTRUCTIONS_DIR="$BASE_DIR/instructions"
SCRIPT="$BASE_DIR/full_instruction_exec.sh"
OUTDIR="$BASE_DIR/output"

mkdir -p "$LOG_DIR" "$INSTRUCTIONS_DIR" "$OUTDIR"
LOG_FILE="$LOG_DIR/oneshot_submit_$TIMESTAMP.log"
FORMAT="plain"
DRY_RUN=0
PROMPT=""

# --- Parse Flags ---
while [[ "$1" =~ ^-- ]]; do
  case "$1" in
    --json) FORMAT="json" ;;
    --yaml) FORMAT="yaml" ;;
    --dry-run) DRY_RUN=1 ;;
    *) echo "❌ Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

# --- Join remaining args as prompt ---
PROMPT="$*"

{
echo "============================================================"
echo "🧠 SUBMIT INSTRUCTION (One-Shot)"
echo "============================================================"
echo "🕒 Started at: $(date)"
echo

## STEP 1: Environment Check
echo "## STEP 1: Environment Check"
echo "-----------------------------------------------"
MISSING=0
[[ -x "$SCRIPT" ]] && echo "✅ $SCRIPT found" || { echo "❌ $SCRIPT missing or not executable"; MISSING=1; }
[[ -d "$INSTRUCTIONS_DIR" ]] && echo "✅ instructions/ exists" || { echo "❌ instructions/ folder missing"; MISSING=1; }
[[ -d "$OUTDIR" ]] && echo "✅ output/ exists" || { echo "❌ output/ folder missing"; MISSING=1; }

command -v bash >/dev/null || { echo "❌ bash not found"; MISSING=1; }

if [[ "$MISSING" -eq 1 ]]; then
  echo "# AI:Section=Validation"
  echo "# AI:NeedsReview=true"
  echo "🚫 Aborting due to missing environment requirements"
  exit 1
fi

if [[ -z "$PROMPT" ]]; then
  echo "❌ No prompt text supplied"
  echo "Usage: ./submit_instruction.sh \"Write a bash script that prints hello\""
  exit 1
fi

## STEP 2: Create Instruction File
echo
echo "## STEP 2: Create Instruction"
echo "-----------------------------------------------"
INSTRUCTION_FILE="$INSTRUCTIONS_DIR/oneshot_$TIMESTAMP.instruction.txt"
echo "$PROMPT" > "$INSTRUCTION_FILE"
echo "✅ Saved instruction to: $INSTRUCTION_FILE"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "🚧 DRY-RUN: Skipping execution of instruction"
else
  echo
  echo "## STEP 3: Execute Instruction"
  echo "-----------------------------------------------"
  bash "$SCRIPT"
  RC=$?

  if [[ "$RC" -ne 0 ]]; then
    echo "❌ Execution failed — creating diagnostic..."
    DIAG_SCRIPT="$LOG_DIR/diagnostic_oneshot_fail_$TIMESTAMP.sh"
    cat > "$DIAG_SCRIPT" <<DIAG
#!/bin/bash
echo "📁 Instruction:"
cat "$INSTRUCTION_FILE"
echo
echo "📁 Recent logs:"
tail -n 30 "$LOG_FILE"
DIAG
    chmod +x "$DIAG_SCRIPT"
    echo "# AI:Section=Validation"
    echo "# AI:NeedsReview=true"
    echo "🛠️ Diagnostic script: $DIAG_SCRIPT"
  fi
fi

## STEP 4: Final Output Format
echo
echo "## STEP 4: Final Output Format"
echo "-----------------------------------------------"

if [[ "$FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"status\": \"done\","
  echo "  \"instruction\": \"$INSTRUCTION_FILE\","
  echo "  \"log\": \"$LOG_FILE\""
  echo "}"
elif [[ "$FORMAT" == "yaml" ]]; then
  echo "status: done"
  echo "instruction: $INSTRUCTION_FILE"
  echo "log: $LOG_FILE"
else
  echo "✅ Instruction submitted and processed"
fi

echo
echo "============================================================"
echo "🏁 COMPLETE — LOG: $LOG_FILE"
echo "============================================================"

} 2>&1 | tee "$LOG_FILE"
