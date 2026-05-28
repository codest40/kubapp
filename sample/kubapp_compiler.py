#!/usr/bin/env python3

import yaml
import sys
from collections import defaultdict

# ----------------------------
# Load init schema (source of truth)
# ----------------------------
def load_init(path):
    with open(path, "r") as f:
        return yaml.safe_load(f)

# ----------------------------
# Parse kubapp.values DSL
# ----------------------------
def parse_kubapp_values(path):
    data = {
        "env": {},
        "maps": {},
        "lists": defaultdict(list),
        "scalars": {}
    }

    current_map = None
    current_list = None

    with open(path, "r") as f:
        for line in f:
            line = line.strip()

            # skip comments / empty
            if not line or line.startswith("#"):
                continue

            # key=value
            if "=" in line and not line.startswith(("map:", "list:")):
                key, value = line.split("=", 1)

                if key.startswith("env_"):
                    data["env"][key.replace("env_", "")] = value
                else:
                    data["scalars"][key] = value

            # map start
            elif line.startswith("map:"):
                current_map = line.replace("map:", "")
                data["maps"][current_map] = {}

            # list start
            elif line.startswith("list:"):
                current_list = line.replace("list:", "")
                data["lists"][current_list] = []

            # map value
            elif current_map and "=" in line:
                k, v = line.split("=", 1)
                data["maps"][current_map][k] = v

            # list value
            elif current_list:
                data["lists"][current_list].append(line)

    return data

# ----------------------------
# Merge with init.yaml
# ----------------------------
def merge(init, parsed):
    result = init.copy()

    # image overrides
    if "image_repo" in parsed["scalars"]:
        result["image"]["repository"] = parsed["scalars"]["image_repo"]

    if "image_tag" in parsed["scalars"]:
        result["image"]["tag"] = parsed["scalars"]["image_tag"]

    # port override
    if "app_port" in parsed["scalars"]:
        result["service"]["targetPort"] = int(parsed["scalars"]["app_port"])

    # replicas (optional)
    if "replicas" in parsed["scalars"]:
        result["replicaCount"] = int(parsed["scalars"]["replicas"])

    # env
    result["env"].update(parsed["env"])

    # maps → env nested objects
    for k, v in parsed["maps"].items():
        result["env"][k] = v

    # lists → env arrays
    for k, v in parsed["lists"].items():
        result[k.upper()] = v

    return result

# ----------------------------
# Simple schema validator
# ----------------------------
def validate(parsed):
    required = ["image_repo", "image_tag", "app_port"]

    missing = []
    for r in required:
        if r not in parsed["scalars"]:
            missing.append(r)

    if missing:
        raise Exception(f"Missing required fields: {missing}")

# ----------------------------
# Main
# ----------------------------
def main():
    if len(sys.argv) != 4:
        print("Usage: kubapp_compiler.py kubapp.values init.yaml output.yaml")
        sys.exit(1)

    values_file = sys.argv[1]
    init_file = sys.argv[2]
    output_file = sys.argv[3]

    init = load_init(init_file)
    parsed = parse_kubapp_values(values_file)

    validate(parsed)

    merged = merge(init, parsed)

    with open(output_file, "w") as f:
        yaml.dump(merged, f, sort_keys=False)

    print(f"✅ Generated: {output_file}")

if __name__ == "__main__":
    main()

