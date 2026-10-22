"""Verify the dated not-due observation without walking or deleting artifacts."""
from copy import deepcopy
from datetime import datetime, timedelta
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
RECORD = Path(__file__).with_name('admission.json.gz')


def validate(value):
    assert value['schema'] == 'fsmgen.artifact_census_due_admission.v1'
    assert value['owner'] == 'ARTIFACT-CLEANUP-20261022.1'
    revision = value['revision']
    assert re.fullmatch(r'[0-9a-f]{40}', revision)
    prior = subprocess.check_output(
        ['git', '--no-replace-objects', 'show', revision + ':docs/ARTIFACT_CLEANUP.md'], cwd=ROOT)
    assert value['prior_record'].encode() == prior
    assert value['prior_sha256'] == hashlib.sha256(prior).hexdigest()
    previous = datetime.fromisoformat(re.search(rb'^([0-9T:.+\-]+) ', prior, re.M)[1].decode())
    captured = datetime.fromisoformat(value['utc'])
    assert captured.tzinfo is not None and previous <= captured < previous + timedelta(days=1)
    assert value['threshold_utc'] == (previous + timedelta(days=1)).isoformat()
    assert value['due'] is False and value['calendar_day_is_not_elapsed_day'] is True
    source = value['source']
    expected = subprocess.check_output(['git', '--no-replace-objects', 'show',
        revision + ':docs/audits/artifact-census-20261021/census.py'], cwd=ROOT).decode()
    expected, count = re.subn(r"^BASE = '[0-9a-f]{40}'$", "BASE = '" + revision + "'", expected, flags=re.M)
    assert count == 1
    expected = expected.replace("contract.OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.89'",
                                "contract.OWNER = 'ARTIFACT-CLEANUP-20261022.1'")
    assert source['text'] == expected
    assert type(source['bytes']) is int and source['bytes'] == len(expected.encode())
    assert source['sha256'] == hashlib.sha256(expected.encode()).hexdigest()
    command = ['python3', '-B', 'docs/audits/artifact-census-20261022/census.py', '--write']
    assert source['path'] == command[2]
    for label in ('original_attempt', 'controlled_refusal'):
        result = value[label]
        assert result['command'] == command
        assert type(result['exit_status']) is int and result['exit_status'] == 1
    replay = value['controlled_refusal']
    assert replay['stdout'] == ''
    assert 'total_seconds() > 86400' in replay['stderr']
    assert replay['stderr'].endswith('AssertionError\n')
    assert 'not separately captured' in value['original_attempt']['retention_limit']
    assert value['history']['exit_status'] == 0 and value['history']['stdout']


def main():
    value = json.loads(gzip.decompress(RECORD.read_bytes()))
    validate(value)
    controls = (
        ('due', lambda row: row.update(due=True)),
        ('status_kind', lambda row: row['controlled_refusal'].update(exit_status=True)),
        ('prior', lambda row: row.update(prior_record='changed')),
        ('source', lambda row: row['source'].update(text='changed')),
        ('diagnostic', lambda row: row['controlled_refusal'].update(stderr='different refusal\n')),
    )
    for label, change in controls:
        wrong = deepcopy(value)
        change(wrong)
        try:
            validate(wrong)
        except AssertionError:
            continue
        raise AssertionError('invalid admission evidence accepted: ' + label)
    print('PASS dated elapsed-time admission and genuine evidence controls; no sweep or deletion repeats.')


if __name__ == '__main__':
    main()
