#!/usr/bin/env python3
"""Replay the independently diagnosed backend ownership control, not a repair."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true', required=True)
    parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    packet = root / 'docs/audits/direct-width-target-plans-20261027.json.gz'
    data = json.loads(gzip.decompress(packet.read_bytes()))
    probe = data['ownership_probe']['source']
    code = probe['text']
    if hashlib.sha256(code.encode()).hexdigest() != probe['sha256']:
        raise SystemExit('ownership probe source hash mismatch')
    result = subprocess.run(['scripts/run_with_ram_guard.sh', '--', 'perl', '-Iperl', '-e', code],
                            cwd=root, capture_output=True, text=True, check=True)
    expected = [
        {'mode': 'parsed_only', 'module_alive': 0, 'backend_alive': 0, 'planner_alive': 0},
        {'mode': 'numeric_backend', 'module_alive': 1, 'backend_alive': 1, 'planner_alive': 0},
        {'mode': 'single_module_planner', 'module_alive': 1, 'backend_alive': 1, 'planner_alive': 1},
        {'mode': 'single_planner_weak_control', 'module_alive': 0, 'backend_alive': 0, 'planner_alive': 0},
    ]
    actual = json.loads(result.stdout)
    if actual != expected or data['ownership_probe']['product'] != expected:
        raise SystemExit('backend ownership controls differ; investigate the current retaining/release graph')
    print('Backend owner-cycle controls reproduce the diagnosed defect and isolated weak-edge release; repair remains .25.')


if __name__ == '__main__':
    main()
