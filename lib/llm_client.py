# lib/llm_client.py

import requests
import json

OLLAMA_URL = "http://localhost:11434/api/generate"
DEFAULT_MODEL = "llama3"

def query_llm(prompt, model=DEFAULT_MODEL, stream=False):
    """
    Send a prompt to the local LLM and return the response.
    """
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": stream
    }

    try:
        response = requests.post(OLLAMA_URL, json=payload)
        response.raise_for_status()
        data = response.json()
        return data.get("response", "").strip()

    except requests.RequestException as e:
        print(f"[LLM ERROR] {e}")
        return None
