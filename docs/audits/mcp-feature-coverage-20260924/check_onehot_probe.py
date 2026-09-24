"""Check the bounded standalone probe output; this does not certify a simulator."""
import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    raise SystemExit("usage: check_onehot_probe.py LOG")
try:
    text = Path(sys.argv[1]).read_text()
except (OSError, UnicodeError) as error:
    raise SystemExit("onehot probe: cannot read log: " + str(error))
pattern = r"a=([01]) b=([01]) concat=([01xz]) vector=([01xz]) literal=([01xz])"
if any(line.startswith("a=") and not re.fullmatch(pattern, line) for line in text.splitlines()):
    raise SystemExit("onehot probe: malformed observation")
if re.search(r"ERROR:|FATAL:|%Error|Assertion failed", text):
    raise SystemExit("onehot probe: simulator diagnostic prevents qualification")
rows = re.findall(r"^a=([01]) b=([01]) concat=([01xz]) vector=([01xz]) literal=([01xz])$", text, re.MULTILINE)
expected = {"00": "1", "01": "1", "10": "1", "11": "0"}
seen = set()
for a, b, concat, vector, literal in rows:
    value = a + b
    if value in seen:
        raise SystemExit("onehot probe: duplicate input " + value)
    seen.add(value)
    if (concat, vector, literal) != (expected[value],) * 3:
        raise SystemExit("onehot probe: input " + value + " returned "
                         + "/".join((concat, vector, literal))
                         + "; expected " + expected[value])
if seen != set(expected):
    raise SystemExit("onehot probe: incomplete input matrix")
print("onehot output-context qualification PASS (bounded probe only)")
