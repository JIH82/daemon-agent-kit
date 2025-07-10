import os
import time
import logging
import subprocess
import json

INSTRUCTIONS_DIR = "instructions"
AGENTS_DIR = "agents"
LOG_FILE = "logs/system_agent.log"
META_AGENT = "meta_decider"
OUTPUT_FILE = "output/meta_response.txt"

logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

def load_agent_names():
    return [name for name in os.listdir(AGENTS_DIR) if os.path.isdir(os.path.join(AGENTS_DIR, name))]

def process_instruction(file_path):
    filename = os.path.basename(file_path)
    agent_name = filename
    agent_path = os.path.join(AGENTS_DIR, agent_name, "run.sh")

    if os.path.exists(agent_path):
        logging.info(f"🟢 Found matching agent: {agent_name}, executing...")
        subprocess.run(["bash", agent_path], check=False)
    else:
        logging.info(f"🟡 No direct agent found for '{filename}'. Passing to meta_decider.")
        meta_path = os.path.join(AGENTS_DIR, META_AGENT, "run.sh")
        subprocess.run(["bash", meta_path, file_path], check=False)

def watch_instructions():
    logging.info("System agent instruction parser started.")
    seen_files = set()

    while True:
        try:
            files = set(os.listdir(INSTRUCTIONS_DIR))
            new_files = files - seen_files

            for f in new_files:
                file_path = os.path.join(INSTRUCTIONS_DIR, f)
                if os.path.isfile(file_path):
                    logging.info(f"📥 New instruction: {f}")
                    process_instruction(file_path)
                    seen_files.add(f)

            time.sleep(2)
        except Exception as e:
            logging.error(f"Error in instruction watcher: {e}")
            time.sleep(5)

if __name__ == "__main__":
    watch_instructions()

