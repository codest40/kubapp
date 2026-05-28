#!/usr/bin/env python3

import sys
import yaml
from collections import defaultdict

def set_nested(d, keys, value):
    for k in keys[:-1]:
        if k not in d:
            d[k] = {}
        d = d[k]
    d[keys[-1]] = value

def parse_file(filepath):
    result = {
        "app": {},
        "image": {},
        "runtime": {},
        "env": {},
        "features": {},
        "scale": {},
        "services": {},
        "allowed_hosts": []
    }

    with open(filepath, "r") as f:
        for line in f:
            line = line.strip()

            # skip empty/comments
            if not line or line.startswith("#"):
                continue

            # scalar key=value
            if "=" in line and not line.startswith(("map:", "list:", "block:", "flag:")):
                key, value = line.split("=", 1)

                if key == "app_name":
                    result["app"]["name"] = value

                elif key == "image_repo":
                    result["image"]["repository"] = value

                elif key == "image_tag":
                    result["image"]["tag"] = value

                elif key == "app_port":
                    result["runtime"]["port"] = int(value)

                elif key == "env":
                    result["runtime"]["env"] = value

                elif key == "min_replicas":
                    result["scale"]["minReplicas"] = int(value)

                elif key == "max_replicas":
                    result["scale"]["maxReplicas"] = int(value)

                else:
                    result[key] = value

            # map:env_KEY=value
            elif line.startswith("map:"):
                _, rest = line.split("map:", 1)
                key, value = rest.split("=", 1)
                result["env"][key.replace("env_", "")] = value

            # list:key=a,b,c
            elif line.startswith("list:"):
                _, rest = line.split("list:", 1)
                key, value = rest.split("=", 1)
                result[key] = value.split(",")

            # flag:key=value
            elif line.startswith("flag:"):
                _, rest = line.split("flag:", 1)
                key, value = rest.split("=", 1)
                result["features"][key] = value.lower() == "true"

            # block:a.b.c=value
            elif line.startswith("block:"):
                _, rest = line.split("block:", 1)
                path, value = rest.split("=", 1)
                keys = path.split(".")
                set_nested(result, ["services"] + keys, value)

    return result

def main():
    if len(sys.argv) != 2:
        print("Usage: parse_kubapp_values.py <file>")
        sys.exit(1)

    data = parse_file(sys.argv[1])

    print(yaml.dump(data, sort_keys=False))

if __name__ == "__main__":
    main()

