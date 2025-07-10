# 🤖 Daemon-Agent Kit

An autonomous AI assistant that takes natural language instructions, generates executable Bash scripts, and handles retries, validation, and diagnostics automatically.

## ✅ Features
- One-shot instruction execution via `submit.sh`
- Automatic retry and error diagnosis
- Logs all activity in timestamped logs
- Syntax-safe code generation pipeline

## 🔄 Usage
```bash
./submit.sh "Write a bash script that pings 8.8.8.8 and prints the result"
