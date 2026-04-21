import json
from collections import defaultdict

STATE_FILE = "terraform.tfstate"


def load_state():
    with open(STATE_FILE) as f:
        return json.load(f)


def get_resources(state):
    resources = []

    for res in state.get("resources", []):
        module = res.get("module", "root")
        r_type = res.get("type")
        name = res.get("name")

        for i, instance in enumerate(res.get("instances", [])):
            address = f"{module}.{r_type}.{name}[{i}]"
            deps = instance.get("dependencies", [])

            resources.append({
                "address": address,
                "type": r_type,
                "module": module,
                "dependencies": deps
            })

    return resources


def get_outputs(state):
    return state.get("outputs", {})


def summarize(resources, outputs):
    print("\n📦 RESOURCES")
    print("=" * 40)

    for r in resources:
        print(f"{r['address']}")
        if r["dependencies"]:
            print(f"  └─ depends on:")
            for d in r["dependencies"]:
                print(f"     - {d}")
        else:
            print("  └─ no dependencies")

    print("\n📤 OUTPUTS")
    print("=" * 40)

    for name, val in outputs.items():
        print(f"{name}: {val.get('value')}")


def build_dependency_graph(resources):
    graph = defaultdict(list)

    for r in resources:
        for dep in r["dependencies"]:
            graph[dep].append(r["address"])

    return graph


def print_graph(graph):
    print("\n🔗 DEPENDENCY GRAPH")
    print("=" * 40)

    for parent, children in graph.items():
        print(parent)
        for child in children:
            print(f"  └─ {child}")


import os
import re

def get_tf_defined_resources():
    resources = set()

    for root, _, files in os.walk("."):
        for file in files:
            if file.endswith(".tf"):
                with open(os.path.join(root, file)) as f:
                    content = f.read()

                    matches = re.findall(r'resource\s+"(\w+)"\s+"(\w+)"', content)
                    for r_type, name in matches:
                        resources.add(f"{r_type}.{name}")

    return resources


def find_orphans(state_resources, tf_resources):
    print("\n🚨 ORPHANED RESOURCES")
    print("=" * 40)

    for r in state_resources:
        key = f"{r['type']}.{r['address'].split('.')[-1].split('[')[0]}"

        if key not in tf_resources:
            print(f"Orphaned: {r['address']}")

if __name__ == "__main__":
    state = load_state()

    resources = get_resources(state)
    outputs = get_outputs(state)

    summarize(resources, outputs)

    graph = build_dependency_graph(resources)
    print_graph(graph)
