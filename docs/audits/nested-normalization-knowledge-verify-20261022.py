#!/usr/bin/env python3
"""Verify retained card identities and exact old/new question conservation.

Semantic preservation of the existing source-origin prose remains review,
supported by the retained complete original and its named regression tests.
"""
import copy
import gzip
import json
from pathlib import Path
import re
import subprocess

BASE = Path('docs/audits')
record = json.loads(gzip.decompress((BASE / 'nested-normalization-knowledge-20261022.json.gz').read_bytes()))
epoch = json.loads(gzip.decompress((BASE / 'nested-normalization-before-20261022.json.gz').read_bytes()))
original = subprocess.check_output(['git', 'show', epoch['baseline_revision'] + ':' + record['original_path']]).decode()


def questions(text):
    return set(re.findall(r'^  - .*$', text, re.M))


def validate(value):
    if value['original'] != original:
        raise ValueError('original card differs from baseline Git')
    expected = {
        '  - "why did an ISF nested aggregate first row retain an extra list?"',
        '  - "what qualifies nested library override list normalization?"',
    }
    if questions(value['standalone']) != expected:
        raise ValueError('new question identity changed')
    if questions(value['result']) != questions(original) | expected:
        raise ValueError('old/new question union changed')
    marker = 'id: isf-same-source-library-conditional-origins\n'
    if marker not in value['result']:
        raise ValueError('stable card identity changed')


validate(record)
if Path(record['original_path']).read_text() != record['result']:
    raise ValueError('current card differs from retained result')
if Path(record['standalone_path']).exists():
    raise ValueError('standalone draft still adds a collection member')
for mutation in ('original', 'old-question', 'new-question', 'identity'):
    bad = copy.deepcopy(record)
    if mutation == 'original':
        bad['original'] += '\n'
    elif mutation == 'old-question':
        bad['result'] = bad['result'].replace(next(iter(questions(original))) + '\n', '')
    elif mutation == 'new-question':
        bad['standalone'] = ''
    else:
        bad['result'] = bad['result'].replace('id: isf-same-source-library-conditional-origins', 'id: wrong')
    try:
        validate(bad)
    except ValueError:
        continue
    raise ValueError('hostile saved control accepted: ' + mutation)
print('knowledge merge: PASS; exact original/current card and complete question union; corrupted controls rejected')
