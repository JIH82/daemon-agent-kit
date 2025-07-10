# lib/llm_client.py

import sys
import requests
import json
from datetime import datetime

OLLAMA_URL = "http://localhost:11434/api/generate"
DEFAULT_MODEL = "llama3"

# Log the incoming request
with open("logs/llm_debug.log", "a") as f:
    f.write(f"[{datetime.now()}] llm_client.py called with: {sys.argv}\n")

print("✅ llm_client.py was called")
print("📝 Prompt received:", sys.argv[1] if len(sys.argv) > 1 else "(none)")


def query_llm(prompt, model=DEFAULT_MODEL, stream=False):
    """
    Send a prompt to the local LLM and return the response (stream or full).
    """
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": stream
    }

    try:
        response = requests.post(OLLAMA_URL, json=payload, stream=stream)
        response.raise_for_status()

        if stream:
            full_response = ""
            for line in response.iter_lines():
                if line:
                    data = json.loads(line.decode("utf-8"))
                    token = data.get("response", "")
                    print(token, end="", flush=True)
                    full_response += token
            print()  # Final newline
            return full_response.strip()
        else:
            data = response.json()
            return data.get("response", "").strip()

    except requests.RequestException as e:
        print(f"[LLM ERROR] {e}")
        return None


if __name__ == "__main__":
    prompt = sys.argv[1] if len(sys.argv) > 1 else "Say something"
    stream = "--stream" in sys.argv
    result = query_llm(prompt, stream=stream)
    if result:
        print("\n🤖 LLM Response:")
        print(result)
    else:
        print("❌ No response from LLM.")

