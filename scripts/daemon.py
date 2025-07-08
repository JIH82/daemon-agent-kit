#!/usr/bin/env python3
import os
import time
import logging
import subprocess
import platform

WATCH_DIR = "agents"
LOG_FILE = "logs/daemon.log"
POLL_INTERVAL = 10

logging.basicConfig(filename=LOG_FILE, level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s")


def get_hostname():
    return platform.node()


def run_agent(agent_name):
    agent_dir = os.path.join(WATCH_DIR, agent_name)
    run_script = os.path.join(agent_dir, "run.sh")
    if not os.path.isfile(run_script):
        logging.warning(f"No run.sh found for agent: {agent_name}")
        return

    try:
        result = subprocess.run([run_script], check=True, capture_output=True, text=True)
        logging.info(f"{agent_name} output: {result.stdout.strip()}")
    except subprocess.CalledProcessError as e:
        logging.error(f"{agent_name} failed: {e.stderr.strip()}")
    except Exception as e:
        logging.error(f"Error running {agent_name}: {str(e)}")


def main():
    logging.info("Daemon started.")
    logging.info(f"Daemon heartbeat from {get_hostname()}")

    while True:
        for fname in os.listdir(WATCH_DIR):
            if fname.startswith("run_") and fname.endswith(".flag"):
                agent_name = fname.replace("run_", "").replace(".flag", "")
                logging.info(f"Trigger file detected. Running {agent_name}...")
                run_agent(agent_name)
                try:
                    os.remove(os.path.join(WATCH_DIR, fname))
                    logging.info("Trigger file removed.")
                except Exception as e:
                    logging.warning(f"Failed to remove trigger file: {str(e)}")

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()

