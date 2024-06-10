#!/usr/bin/env python3
# create a full .yml manifest of all servers in this network
# their IP+port, rcon password, and hostname
# for use with relay bot and serverhop

# Honestly trying to figure out some way to do this as an Ansible module would
# have been a nightmare. Thankfully Ansible is Linux-only so I only really
# need to worry about platform compatibility with Linux
# should afford me some liberties with os.system and crypt

import logging
import os
import sys
import time

import yaml


def decrypt_ansible_secrets() -> None:
    logging.info("Decrypting secrets...")
    os.system("ansible-vault decrypt host_vars/*.secret.yml")
    os.system("ansible-vault decrypt inventory.yml")


def load_ansible_inventory() -> dict:
    logging.info("Loading Ansible inventory...")
    with open("inventory.yml") as inventory_yml:
        inventory = yaml.safe_load(inventory_yml)

    retval = inventory["all"]["children"]["tf2"]["children"]["prod"]["hosts"]
    logging.debug(retval)
    return retval


def load_ansible_globals() -> dict:
    logging.info("Loading Ansible globals...")
    with open("group_vars/tf2.yml") as globals_yml:
        globals = yaml.safe_load(globals_yml)

    retval = {
        "stv_enabled": globals["stv_enabled"],
    }
    logging.debug(retval)
    return retval


def load_ansible_variables() -> dict:
    logging.info("Loading Ansible host variables...")
    host_vars = {}
    for file in os.listdir("host_vars"):
        if file.endswith(".sample"):
            continue

        is_secret = False
        if file.endswith(".secret.yml"):
            is_secret = True
            host_strip = 11  # len(".secret.yml")
        else:
            host_strip = 4  # len(".yml")
        host = file[:-host_strip]

        with open(f"host_vars/{file}") as host_yml:
            vars = yaml.safe_load(host_yml)

            if host not in host_vars:
                host_vars[host] = {}

            if is_secret:
                instances_secrets = {
                    instance["name"]: instance for instance in vars["instances_secrets"]
                }
                host_vars[host]["secret"] = instances_secrets
            else:
                instances = {
                    instance["name"]: instance for instance in vars["instances"]
                }
                del vars["instances"]
                host_vars[host]["host"] = vars
                host_vars[host]["vars"] = instances

    logging.debug(host_vars)
    return host_vars


def encrypt_ansible_secrets() -> None:
    logging.info("Encrypting secrets...")
    os.system("ansible-vault encrypt host_vars/*.secret.yml")
    os.system("ansible-vault encrypt inventory.yml")


def create_manifest(inventory: dict, globals: dict, vars: dict) -> dict:
    logging.info("Formatting the resulting dict...")
    manifest = {}
    for host in inventory:
        ip = inventory[host]["ansible_host"]
        base_port = vars[host]["host"]["srcds_base_port"]

        for i, instance in enumerate(vars[host]["vars"]):
            if instance in manifest:
                ValueError(
                    f"duplicate instance {instance} -- internal names should be unique"
                )
            manifest[instance] = {}

            manifest[instance]["ip"] = ip
            manifest[instance]["port"] = base_port + (vars[host]["host"]["srcds_reserve_ports"] * i)
            manifest[instance]["hostname"] = vars[host]["vars"][instance]["hostname"]
            manifest[instance]["rcon_pass"] = vars[host]["secret"][instance][
                "rcon_pass"
            ]

            if stv_enabled := vars[host]["vars"][instance].get("stv_enabled", None):
                manifest[instance]["stv_enabled"] = stv_enabled
            else:
                manifest[instance]["stv_enabled"] = globals["stv_enabled"]

            manifest[instance]["relay_channel"] = vars[host]["vars"][instance].get("relay_channel", None)

    logging.debug(manifest)
    return manifest


def main() -> None:
    decrypt_ansible_secrets()
    ansible_inv = load_ansible_inventory()
    ansible_globals = load_ansible_globals()
    ansible_vars = load_ansible_variables()
    encrypt_ansible_secrets()
    manifest = create_manifest(ansible_inv, ansible_globals, ansible_vars)
    logging.info("Writing manifest to manifest.yml...")
    with open("manifest.yml", "w") as manifest_yml:
        manifest_yml.write(yaml.safe_dump(manifest))
    logging.info("Done")


if __name__ == "__main__":
    log_handlers = []
    formatter = logging.Formatter(
        "%(asctime)s | %(module)s [%(levelname)s] %(message)s",
    )

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.INFO)
    stdout_handler.setFormatter(formatter)
    log_handlers.append(stdout_handler)

    if not os.path.exists("manifest_logs"):
        os.mkdir("manifest_logs")
    file_handler = logging.FileHandler(
        f"manifest_logs/{time.asctime().replace(':','-').replace(' ','_')}.log"
    )
    file_handler.setFormatter(formatter)
    file_handler.setLevel(logging.DEBUG)
    log_handlers.append(file_handler)

    logging.basicConfig(handlers=log_handlers, level=logging.DEBUG)

    main()
