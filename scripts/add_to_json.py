import json
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(
    description="Append a key/value to a JSON file preserving order"
)
parser.add_argument("path", help="Path to JSON file")
parser.add_argument("key", help="Key to add")
parser.add_argument("value", help="Value to add (JSON encoded string)")

args = parser.parse_args()

path = Path(args.path)

if not path.exists():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("{}", encoding="utf-8")

try:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
except json.JSONDecodeError:
    data = {}

data[args.key] = json.loads(args.value)

with path.open("w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
