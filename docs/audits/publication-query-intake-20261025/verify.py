#!/usr/bin/env python3
"""Verify finite intake closure, exact fixture origin and retained causal gaps."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def origin(contract, fixture):
    assert set(contract['cases']) == {'knowledge', 'binding'}, 'complete finite intake domain'
    declared = contract['cases']['binding']['fixture_origin']
    source = subprocess.check_output(['git', 'show', declared['baseline_revision'] + ':' + declared['source_path']], cwd=ROOT)
    assert digest(source) == declared['source_sha256'], 'exact original test source'
    matches = list(re.finditer(declared['selector'], source.decode(), re.S))
    assert len(matches) == 1 and fixture == (matches[0][1] + '\n').encode(), 'actual existing conditional-do fixture'
    assert digest(fixture) == declared['fixture_sha256'], 'fixture identity'


def main():
    contract = json.loads((BASE / 'contract.json').read_text())
    fixture = (BASE / 'conditional-do.isf').read_bytes()
    origin(contract, fixture)
    controls = []
    for label in ('omitted-case', 'extra-case', 'covaried-fixture'):
        changed = copy.deepcopy(contract)
        raw = fixture
        if label == 'omitted-case':
            del changed['cases']['knowledge']
        elif label == 'extra-case':
            changed['cases']['borrowed'] = changed['cases']['binding']
        else:
            raw = fixture.replace(b'when_bound_do', b'borrowed_actor')
            changed['cases']['binding']['fixture_origin']['fixture_sha256'] = digest(raw)
        try:
            origin(changed, raw)
        except AssertionError:
            controls.append(label)
        else:
            raise AssertionError('altered fixture/closure accepted: ' + label)
    observer = runpy.run_path(str(BASE / 'observe.py'))
    observer['verify'](contract['cases'])
    authority = json.loads((BASE / 'authority-disposition.json').read_text())
    for path, expected in authority['historical_pins'].items():
        raw = (ROOT / path).read_bytes()
        assert digest(raw) == expected, 'retained historical identity'
        assert raw == subprocess.check_output(['git', 'show', authority['baseline_revision'] + ':' + path], cwd=ROOT)
    after = json.loads(gzip.decompress((ROOT / 'docs/audits/library-source-retention-after-20261022.json.gz').read_bytes()))
    assert authority['source_query_original_error'] == after['error']
    assert 'timed out after 60 seconds' in after['error']
    assert set(after['cases']['defaults']['queries']) == {'check', 'semantic'}, 'original missing schedule stays missing'
    assert authority['disclosure_check']['unqualified_machine_root_or_user_temporary_prefix_present'] is False
    assert 'not original timeout causality' in authority['current_disposition']
    print('Exact Git fixture origin, complete normal intake closure and original gaps verify; controls refuse: ' + ', '.join(controls))


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Saved acceptance assertions must be enabled')
    main()
