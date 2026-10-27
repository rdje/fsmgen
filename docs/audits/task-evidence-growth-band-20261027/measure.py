#!/usr/bin/env python3
"""Reproduce a revision-bound task-evidence growth calibration, without writes by default."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CAPTURE = Path(__file__).with_name('measurement.json')
REVISION = '8ff72285cf0035d292f8583040125683678a1a0c'
WINDOW = 32
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args])


def surface(raw):
    return next(row for row in map(json.loads, raw.splitlines())
                if row.get('surface_id') == 'task_evidence')


def object_measurement(revision, path):
    present = git('ls-tree', revision, '--', path).split()
    if not present:
        return {'lines': 0, 'bytes': 0, 'sha256': None, 'blob': None}
    blob = present[2].decode()
    raw = git('cat-file', 'blob', blob)
    assert len(raw) == int(git('cat-file', '-s', blob)), 'independent object size disagrees'
    return {'lines': raw.count(b'\n'), 'bytes': len(raw),
            'sha256': hashlib.sha256(raw).hexdigest(), 'blob': blob}


def band(maximum):
    # Four largest observed net additions, rounded up to a binary band. This
    # is a reviewed planning reserve, not a guarantee about future slice size.
    return 1 << (max(1, maximum * 4) - 1).bit_length()


def measure():
    prior = surface(git('show', REVISION + ':' + REGISTRY))
    patterns = [re.compile('^' + re.escape(p).replace(r'\*', '[^/]*') + '$')
                for p in prior['targets']]
    commits = git('rev-list', '--first-parent', '--max-count=' + str(WINDOW), REVISION).decode().splitlines()
    assert len(commits) == WINDOW
    observations = []
    for commit in commits:
        parent = git('rev-parse', commit + '^').decode().strip()
        changed = git('diff', '--no-renames', '--name-only', '-z', parent, commit).decode().split('\0')
        paths = sorted(p for p in changed if any(pattern.fullmatch(p) for pattern in patterns))
        files = []
        totals = {'lines': 0, 'bytes': 0}
        for path in paths:
            before, after = object_measurement(parent, path), object_measurement(commit, path)
            numstat = git('diff', '--no-renames', '--numstat', parent, commit, '--', path).decode().split('\t')
            line_delta = after['lines'] - before['lines']
            assert line_delta == int(numstat[0]) - int(numstat[1]), 'independent numstat disagrees'
            byte_delta = after['bytes'] - before['bytes']
            files.append({'path': path, 'before': before, 'after': after,
                          'numstat': [int(numstat[0]), int(numstat[1])]})
            totals['lines'] += line_delta
            totals['bytes'] += byte_delta
        observations.append({'commit': commit, 'parent': parent, 'files': files, 'net_growth': totals})
    maxima = {key: max(0, *(row['net_growth'][key] for row in observations)) for key in ('lines', 'bytes')}
    return {'schema': 1, 'revision': REVISION, 'window': WINDOW, 'scope': prior['targets'],
            'observation_unit': 'signed aggregate net task-document growth per first-parent commit; no merges expanded',
            'population': 'last 32 first-parent transitions ending at revision, including zero-growth commits',
            'maxima': maxima, 'selected_bands': {key + '_total': band(value) for key, value in maxima.items()},
            'prior_surface': prior, 'observations': observations}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', help='record the exact historical derivation')
    parser.add_argument('--current', action='store_true', help='also check current task-evidence safety fields and selected bands')
    args = parser.parse_args()
    result = measure()
    encoded = json.dumps(result, sort_keys=True, indent=2) + '\n'
    if args.write:
        CAPTURE.write_text(encoded)
    else:
        assert CAPTURE.read_text() == encoded, 'historical measurement drift'
    if args.current:
        current = surface((ROOT / REGISTRY).read_bytes())
        for key in ('baseline', 'health_targets', 'enforcement_ceilings', 'milestones'):
            assert current[key] == result['prior_surface'][key], key + ' changed'
        for key, value in result['selected_bands'].items():
            assert current['transition']['ratchet_step'][key] == value, 'selected growth band drift'
        for key in ('files', 'lines_each', 'bytes_each', 'line_bytes_each'):
            for field in ('ratchet_step', 'max_growth'):
                assert current['transition'][field][key] == result['prior_surface']['transition'][field][key], 'per-file/file-count control changed'
        assert current['state'] == 'warning_debt', 'current pressure classification changed; review calibration applicability'
    print(json.dumps({'revision': REVISION, 'observed_maxima': result['maxima'], 'selected_bands': result['selected_bands']}, sort_keys=True))


if __name__ == '__main__':
    main()
