#!/usr/bin/env python3
import os
import shutil
import logging
import time
import yaml

INSTRUCTIONS_DIR = "instructions"
AGENTS_DIR = "agents"
LOG_FILE = "logs/system_agent.log"

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

def is_valid_instruction(path):
    return os.path.isfile(os.path.join(path, "run.sh")) and os.path.isfile(os.path.join(path, "agent.yaml"))

def process_instruction_folder(name, full_path):
    agent_path = os.path.join(AGENTS_DIR, name)
    if os.path.exists(agent_path):
        logging.warning(f"Agent '{name}' already exists. Skipping.")
        return

    if not is_valid_instruction(full_path):
        logging.warning(f"Incomplete instruction: {name}. Skipping.")
        return

    # Move to agents/
    shutil.move(full_path, agent_path)
    logging.info(f"Moved instruction '{name}' to agents/.")

    # Touch flag file
    flag_file = os.path.join(AGENTS_DIR, f"run_{name}.flag")
    with open(flag_file, 'w') as f:
        f.write('')
    logging.info(f"Touched trigger file: {flag_file}")

def main():
    logging.info("System agent instruction parser started.")
    while True:
        for item in os.listdir(INSTRUCTIONS_DIR):
            full_path = os.path.join(INSTRUCTIONS_DIR, item)
            if os.path.isdir(full_path):
                process_instruction_folder(item, full_path)
        time.sleep(5)

if __name__ == "__main__":
    main()
