#!/bin/bash
echo "📄 Creating full_instruction_exec.sh ..."
cat > full_instruction_exec.sh <<'EOF'
#!/bin/bash

# ============================================================
# 🧠 PHASE 3: INSTRUCTION EXECUTION (WRAPPED INTO SCRIPT)
# ============================================================

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="logs"
OUT_DIR="output"
INSTRUCTIONS_DIR="instructions"
COMPLETED_DIR="completed"
EXEC_DIR="generated_exec"

mkdir -p "$LOG_DIR" "$OUT_DIR" "$INSTRUCTIONS_DIR" "$COMPLETED_DIR" "$EXEC_DIR"
LOG_FILE="$LOG_DIR/full_exec_${TIMESTAMP}.log"

FORMAT="plain"
[[ "$1" == "--json" ]] && FORMAT="json"
[[ "$1" == "--yaml" ]] && FORMAT="yaml"
[[ "$1" == "--dry-run" ]] && DRY_RUN=1 || DRY_RUN=0

{
echo "============================================================"
echo "🧠 PHASE 3: INSTRUCTION EXECUTION"
echo "============================================================"
echo "🕒 Started at: $(date)"
echo

## STEP 1: Environment Check
echo "## STEP 1: Environment Check"
echo "-----------------------------------------------"
REQUIRED_FILES=("lib/llm_client.py" "$INSTRUCTIONS_DIR" "$OUT_DIR")
MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
  [[ -e "$file" ]] && echo "✅ $file exists" || { echo "❌ $file missing"; MISSING=1; }
done
command -v python3 >/dev/null || { echo "❌ python3 missing"; MISSING=1; }

if [[ $MISSING -eq 1 ]]; then
  echo "# AI:Section=Validation"
  echo "# AI:NeedsReview=true"
  echo "🚫 Missing requirements — aborting."
  exit 1
fi

## STEP 2: Load First Instruction
echo
echo "## STEP 2: Load First Instruction"
echo "-----------------------------------------------"
INSTRUCTION_FILE=\$(find "\$INSTRUCTIONS_DIR" -maxdepth 1 -name "*.instruction.txt" | sort | head -n 1)
[[ -z "\$INSTRUCTION_FILE" ]] && { echo "❌ No instruction file found."; exit 1; }
echo "📄 Found: \$INSTRUCTION_FILE"
PROMPT=\$(<"\$INSTRUCTION_FILE")
echo "📤 Prompt:"
echo "\$PROMPT"

[[ \$DRY_RUN -eq 1 ]] && { echo "🚧 Dry-run: Skipping LLM call."; exit 0; }

## STEP 3: LLM Client Call
echo
echo "## STEP 3: Query LLM"
echo "-----------------------------------------------"
RESPONSE=\$(python3 lib/llm_client.py "\$PROMPT")
[[ -z "\$RESPONSE" ]] && {
  echo "❌ No response from LLM"
  echo "# AI:Section=Validation"
  echo "# AI:NeedsReview=true"
  exit 1
}
echo "✅ LLM responded"

## STEP 4: Save LLM Response
echo
echo "## STEP 4: Save Response"
echo "-----------------------------------------------"
RESP_FILE="\$OUT_DIR/llm_response_\${TIMESTAMP}.txt"
echo "\$RESPONSE" > "\$RESP_FILE"
echo "✅ Saved: \$RESP_FILE"

## STEP 5: Attempt to Execute Script
echo
echo "## STEP 5: Auto-Save & Execute"
echo "-----------------------------------------------"
if echo "\$RESPONSE" | grep -q "#\!/bin/bash"; then
  GEN_SCRIPT="\$EXEC_DIR/autogen_exec_\${TIMESTAMP}.sh"
  echo "\$RESPONSE" > "\$GEN_SCRIPT"
  chmod +x "\$GEN_SCRIPT"
  echo "📦 Saved to: \$GEN_SCRIPT"

  echo
  echo "🔧 Checking syntax..."
  bash -n "\$GEN_SCRIPT" && echo "✅ Syntax OK" || {
    echo "❌ Syntax error in generated script"
    echo "# AI:Section=Validation"
    echo "# AI:NeedsReview=true"
    exit 1
  }

  echo
  echo "🚀 Executing generated script..."
  bash "\$GEN_SCRIPT" > "\$GEN_SCRIPT.log" 2>&1 && echo "✅ Script executed successfully" || {
    echo "❌ Script failed during execution"
    echo "📂 See: \$GEN_SCRIPT.log"
    echo "# AI:Section=Validation"
    echo "# AI:NeedsReview=true"
    exit 1
  }
else
  echo "⚠️ LLM response not recognized as a bash script"
  echo "📝 Skipping execution"
fi

## STEP 6: Archive Instruction
echo
echo "## STEP 6: Archive Instruction"
echo "-----------------------------------------------"
ARCHIVE_NAME="\$COMPLETED_DIR/\$(basename "\$INSTRUCTION_FILE" .txt)_\${TIMESTAMP}.txt"
mv "\$INSTRUCTION_FILE" "\$ARCHIVE_NAME"
echo "📦 Moved to: \$ARCHIVE_NAME"

## STEP 7: Final Output Format
echo
echo "## STEP 7: Final Output Format"
echo "-----------------------------------------------"
if [[ "\$FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"status\": \"success\","
  echo "  \"instruction\": \"\$ARCHIVE_NAME\","
  echo "  \"response\": \"\$RESP_FILE\""
  echo "}"
elif [[ "\$FORMAT" == "yaml" ]]; then
  echo "status: success"
  echo "instruction: \$ARCHIVE_NAME"
  echo "response: \$RESP_FILE"
else
  echo "✅ Execution complete. Use --json or --yaml for structured output."
fi

echo
echo "============================================================"
echo "🏁 Done — Log saved to: \$LOG_FILE"
echo "============================================================"

} 2>&1 | tee "\$LOG_FILE"
EOF

chmod +x full_instruction_exec.sh
echo "✅ Created and made executable: full_instruction_exec.sh"
