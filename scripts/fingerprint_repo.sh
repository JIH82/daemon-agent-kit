#!/bin/bash
# scripts/fingerprint_repo.sh

echo "📌 Collecting Daemon-Agent Repo Fingerprint"
echo "==========================================="
echo ""

echo "📁 Current Directory: $(pwd)"
echo "👤 User: $(whoami)"
echo "🖥️  Hostname: $(hostname)"
echo "🕒 Timestamp: $(date)"
echo ""

echo "## 🧱 Git Info"
git status --short 2>/dev/null || echo "(not a git repo)"
git rev-parse HEAD 2>/dev/null || echo "(no HEAD commit)"
echo ""

echo "## 📂 Directory Tree (depth 2)"
find . -maxdepth 2 -type f | sort
echo ""

echo "## 🐚 Agent Folders"
ls -1 agents | sort
echo ""

echo "## 🧪 Key Scripts"
for f in scripts/*.py scripts/*.sh; do
  [[ -f "$f" ]] && echo "▶ $f" && head -n 10 "$f" && echo "---"
done

