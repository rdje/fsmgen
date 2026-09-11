"""Conservative source-epoch reconciliation for the inert acquisition receipts."""
from __future__ import annotations

from functools import lru_cache
import hashlib
import re
import subprocess

from inventory import ROOT, direct_bytes


def fingerprint(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


@lru_cache(maxsize=512)
def historical(revision, path):
    assert re.fullmatch(r'[0-9a-f]{40}', revision)
    assert path and not path.startswith('/') and '..' not in path.split('/')
    return subprocess.run(['git', 'show', revision+':'+path], cwd=ROOT,
                          check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE).stdout


def function_parts(raw, name):
    """Recognize the deliberately narrow, column-zero prototype layout.

    This is not a general Perl parser. Require one named declaration and its
    column-zero closing brace immediately before the next named declaration.
    Keep the inter-function whitespace in the unchanged suffix.
    """
    starts = list(re.finditer(rb'^sub '+name.encode()+rb' \{\n', raw, re.M))
    assert len(starts) == 1, ('unrecognized function declaration', name)
    start = starts[0].start()
    following = re.search(rb'^sub [A-Za-z_][A-Za-z0-9_]* \{', raw[starts[0].end():], re.M)
    assert following is not None, ('missing following declaration', name)
    stop = starts[0].end()+following.start()
    segment = raw[start:stop]
    ends = list(re.finditer(rb'^\}\n', segment, re.M))
    assert len(ends) == 1 and not segment[ends[0].end():].strip()
    end = start+ends[0].end()
    return raw[:start], raw[start:end], raw[end:]


def reconcile(old, current, allowed=None, witness=None):
    if old == current:
        return 'exact'
    assert allowed is not None and witness is not None, 'unexplained source change'
    before = function_parts(old, allowed)
    after = function_parts(current, allowed)
    qualified = function_parts(witness, allowed)
    assert before[0] == after[0] and before[2] == after[2], 'changed outside admitted function'
    assert after[1] == qualified[1], 'replacement differs from its qualification witness'
    return 'qualified_function_replacement'


def verify(plan, inventory):
    components = {row['name']:row for row in plan['components']}
    assert len(components) == len(plan['components'])
    assert {row['name'] for row in inventory['components']} == set(components)
    allowed = {row['path']:row for row in plan['admitted_function_changes']}
    assert len(allowed) == len(plan['admitted_function_changes'])
    records = []
    for component in inventory['components']:
        selected = components[component['name']]
        assert component['source_epoch'] == selected['source_epoch']
        paths = sorted(set(component['local_oracle_producer_inputs']) |
                       set(inventory['declared_perl_sources']))
        for path in paths:
            old = historical(selected['source_epoch'], path)
            current = direct_bytes(path)
            exception = allowed.get(path)
            witness = components[exception['witness']] if exception else None
            qualified = historical(witness['source_epoch'], path) if witness else None
            status = reconcile(old, current,
                               exception['function'] if exception else None, qualified)
            record = dict(component=component['name'], path=path,
                          receipt_epoch=selected['source_epoch'], status=status,
                          historical=fingerprint(old), current=fingerprint(current))
            if status != 'exact':
                record.update(function=exception['function'], witness=exception['witness'],
                              witness_epoch=witness['source_epoch'],
                              unchanged_outside_function=True,
                              replacement_equals_witness=True)
            records.append(record)
    return records


def falsify(plan):
    components = {row['name']:row for row in plan['components']}
    rejected = []

    def rejects(name, check):
        try:
            check()
        except AssertionError:
            rejected.append(name)
        else:
            raise AssertionError('source applicability accepted falsifier: '+name)

    for exception in plan['admitted_function_changes']:
        path, name = exception['path'], exception['function']
        old = historical(components['handoff']['source_epoch'], path)
        current = direct_bytes(path)
        witness = historical(components[exception['witness']]['source_epoch'], path)
        assert reconcile(old, current, name, witness) == 'qualified_function_replacement'
        rejects(name+': outside-function mutation',
                lambda:reconcile(old, b'# altered\n'+current, name, witness))
        before, body, after = function_parts(current, name)
        changed = before+body.replace(b'\n', b'\n    # altered\n', 1)+after
        rejects(name+': unqualified replacement',
                lambda:reconcile(old, changed, name, witness))
        rejects(name+': no admitted replacement', lambda:reconcile(old, current))
    path = components['snapshot']['source']+'/audit.py'
    raw = direct_bytes(path)
    rejects('changed Python oracle', lambda:reconcile(raw, raw+b'\n# altered\n'))
    return rejected
