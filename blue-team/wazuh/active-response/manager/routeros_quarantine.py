#!/usr/bin/env python3

import json
import sys
import subprocess
import ipaddress
from pathlib import Path
from datetime import datetime

CONFIG_FILE = "/etc/wazuh-routeros/routeros.conf"
LOG_FILE = "/var/ossec/logs/active-responses.log"


def log(message):
    timestamp = datetime.utcnow().isoformat() + "Z"
    with open(LOG_FILE, "a") as f:
        f.write(f"{timestamp} routeros_quarantine: {message}\n")


def load_config(path):
    config = {}

    for line in Path(path).read_text().splitlines():
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        if "=" not in line:
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        config[key] = value

    required = [
        "ROUTEROS_USER",
        "ROUTEROS_HOST",
        "ROUTEROS_SSH_KEY",
        "QUARANTINE_LIST",
    ]

    for key in required:
        if key not in config or not config[key]:
            raise ValueError(f"Missing config value: {key}")

    return config


def get_nested(data, path):
    current = data

    for part in path.split("."):
        if isinstance(current, dict) and part in current:
            current = current[part]
        else:
            return None

    return current


def extract_victim_ip(alert):
    """
    IP da mettere in quarantena.

    Nel tuo caso stai usando data.src_ip, quindi l'IP quarantinato
    sarà quello presente nel campo src_ip dell'alert Wazuh.
    """

    candidate_paths = [
        "parameters.alert.data.src_ip",
    ]

    for path in candidate_paths:
        value = get_nested(alert, path)

        if value and value != "unknown":
            try:
                ipaddress.ip_address(value)
                return value
            except ValueError:
                continue

    return None


def sanitize_comment(value):
    allowed = []

    for char in value:
        if char.isalnum() or char in " ._:-":
            allowed.append(char)

    return "".join(allowed)[:100]


def build_routeros_command(ip, quarantine_list, reason):
    reason_safe = sanitize_comment(reason)

    # RouterOS mostra spesso le connessioni come IP:PORTA.
    # Esempio: src-address=10.3.20.2:4444
    # Per questo uso una regex che cerca l'IP seguito da ":".
    add_to_quarantine = (
        f':if ([:len [/ip firewall address-list find '
        f'list={quarantine_list} address={ip}]] = 0) do={{'
        f'/ip firewall address-list add '
        f'list={quarantine_list} address={ip} comment="{reason_safe}"'
        f'}}'
    )

    remove_src_connections = (
        f'/ip firewall connection remove '
        f'[find where src-address~"^{ip}"]'
    )

    remove_dst_connections = (
        f'/ip firewall connection remove '
        f'[find where dst-address~"^{ip}"]'
    )

    return (
        f'{add_to_quarantine}; '
        f'{remove_src_connections}; '
        f'{remove_dst_connections}'
    )


def run_routeros_command(config, command):
    ssh_cmd = [
        "ssh",
        "-i",
        config["ROUTEROS_SSH_KEY"],
        "-o",
        "BatchMode=yes",
        "-o",
        "StrictHostKeyChecking=yes",
        f'{config["ROUTEROS_USER"]}@{config["ROUTEROS_HOST"]}',
        command,
    ]

    result = subprocess.run(
        ssh_cmd,
        capture_output=True,
        text=True,
        timeout=20,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"SSH command failed. stdout={result.stdout.strip()} stderr={result.stderr.strip()}"
        )

    return result


def main():
    try:
        raw_input = sys.stdin.readline()

        if not raw_input:
            log("No input received from Wazuh")
            sys.exit(1)

        wazuh_message = json.loads(raw_input)

        command = wazuh_message.get("command")
        if command != "add":
            log(f"Ignoring unsupported command={command}")
            sys.exit(0)

        alert = wazuh_message.get("parameters", {}).get("alert", {})
        rule = alert.get("rule", {})
        agent = alert.get("agent", {})

        rule_id = str(rule.get("id", "unknown"))
        description = rule.get("description", "No description")
        agent_name = agent.get("name", "unknown")

        victim_ip = extract_victim_ip(wazuh_message)

        if not victim_ip:
            log(f"Could not extract victim IP from alert rule_id={rule_id}")
            sys.exit(1)

        config = load_config(CONFIG_FILE)

        reason = f"Wazuh rule {rule_id} - {description} - agent {agent_name}"

        routeros_cmd = build_routeros_command(
            victim_ip,
            config["QUARANTINE_LIST"],
            reason,
        )

        run_routeros_command(config, routeros_cmd)

        log(
            f"Quarantined ip={victim_ip} rule_id={rule_id} "
            f"agent={agent_name} and removed active connections"
        )

    except Exception as e:
        log(f"ERROR: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()