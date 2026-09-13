"""Recover exact first/corrected evidence without replaying any producer."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess

import audit
import audit_corrected
from common import BASE, ROOT, LOG, authenticate, document, pin, write

STAGES = ('prepare', 'bridge', 'qualify', 'audit', 'corrected-audit', 'saved',
          'book', 'book-inspect', 'knowledge-generate', 'knowledge-check')


def verify():
    plan = document(BASE / 'plan.json')
    authenticate(plan, document(BASE / 'corrected-pins.json'))
    for row in document(BASE / 'review-pins.json'):
        assert pin(row['path']) == row
    first = document(BASE / 'first-failure.json')
    for row in first['unchanged_first_files']:
        assert pin(row['path']) == row
    original = (BASE / 'audit.py').read_text()
    old = "current.update({hold['source']['identity']['path']: hold['source'] for hold in state['references'].values()})"
    new = "current.update({hold['source']['identity']['path']: hold['source'] for hold in state['references'].values()\n                    if 'source' in hold})"
    assert original.count(old) == 1
    expected = original.replace(old, new).replace("document(BASE / 'preflight-pins.json')", "document(BASE / 'corrected-pins.json')")
    expected = expected.replace("BASE / 'audit.json'", "BASE / 'corrected-audit.json'")
    assert (BASE / 'audit_corrected.py').read_text() == expected
    prepared, qualification, bridge = [document(BASE / name) for name in ('prepared.json', 'qualification.json', 'bridge.json')]
    assert set(prepared) == {'schema', 'seeds', 'schedules', 'controls'}
    assert prepared['schema'] == 'fsmgen.inactive_lifetime_model_inputs.v1'
    assert set(qualification) == {'schema', 'traces', 'controls', 'mutants', 'runtime_qualification', 'actual_filesystem_effects'}
    assert qualification['schema'] == 'fsmgen.inactive_lifetime_model_qualification.v1'
    assert set(bridge) == {'schema', 'seeds', 'controls', 'process_attempts', 'fixture_lookup_attempts', 'input_unchanged'}
    assert bridge['schema'] == 'fsmgen.inactive_lifetime_record_bridge.v1'
    control = next(x for x in prepared['controls'] if x['control']['name'] == 'unknown_reference_blocks_maintenance')
    try:
        audit.expected_view(control['seed'], control['state'])
    except KeyError as error:
        assert error.args == ('source',)
    else:
        raise AssertionError('original malformed-reference projection no longer rejects')
    counts = audit_corrected.verify(qualification, prepared, plan, bridge)
    report = document(BASE / 'corrected-audit.json')
    assert report == dict(schema='fsmgen.inactive_lifetime_model_audit.v1', **counts,
                          falsifiers=audit_corrected.falsify(qualification, prepared, plan, bridge))
    captures = document(BASE / 'verification-outputs.json')
    expected_paths = [str((LOG / (stage + '.' + extension)).relative_to(ROOT))
                      for stage in STAGES for extension in ('stdout', 'stderr', 'exit')]
    assert [row['path'] for row in captures] == expected_paths
    raw = {}
    for row in captures:
        body = bytes.fromhex(row['raw_hex'])
        assert body.hex() == row['raw_hex'] and len(body) == row['size_bytes']
        assert hashlib.sha256(body).hexdigest() == row['sha256']
        raw[row['path'].rsplit('/', 1)[-1]] = body
    for stage in STAGES:
        assert raw[stage + '.exit'] == (b'1\n' if stage == 'audit' else b'0\n')
    for row in first['outputs']:
        assert bytes.fromhex(row['raw_hex']) == raw[row['path'].rsplit('/', 1)[-1]]
    assert b"KeyError: 'source'" in raw['audit.stderr']
    assert json.loads(raw['corrected-audit.stdout']) == json.loads(raw['saved.stdout']) == report
    tap = raw['bridge.stdout'].decode().splitlines()
    assert tap[-1] == '1..42' and len(tap) == 43
    assert all(line.startswith('ok ' + str(index) + ' - ') for index, line in enumerate(tap[:-1], 1))
    assert b'knowledge-map: OK' in raw['knowledge-check.stdout'] + raw['knowledge-check.stderr']
    book = document(BASE / 'book-review.json')
    roots = sorted({value['case'] for seed in prepared['seeds'].values() for value in seed['observers'].values()}
                   | {runtime['directory']['path'] for seed in prepared['seeds'].values() for runtime in seed['runtimes'].values()}
                   | {value['request']['evidence_directory_identity']['path'] for seed in prepared['seeds'].values()
                      for value in seed['observers'].values()})
    assert len(roots) == 4
    for path in roots + [book['output']]:
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink(), path
    assert book['exit_code'] == 0 and book['exact_output_absent']
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    original_card = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + card], cwd=ROOT).decode()
    questions = lambda text: [line for line in text.splitlines() if line.startswith('  - "')]
    assert questions(original_card) == questions((ROOT / card).read_text())
    return dict(schema='fsmgen.inactive_lifetime_model_review.v1', owner=plan['owner'], source_revision=plan['source_revision'],
                source_inputs=len(plan['inputs']), source_bytes=sum(row['size_bytes'] for row in plan['inputs']),
                prepare_pins=len(document(BASE / 'prepare-pins.json')), preflight_pins=len(document(BASE / 'preflight-pins.json')),
                corrected_pins=len(document(BASE / 'corrected-pins.json')), raw_captures=len(captures), original_record_tap=42,
                **counts, falsifiers=report['falsifiers'], exact_inert_roots_absent=roots,
                first_failure=first['cause'], correction=first['correction'],
                claim_legs=plan['claim_legs'], limits=plan['scope'],
                next_action='Admit separately owned bounded actual-file lifetimes under .12.4.1.3.6.3 before any allocation or execution.')


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--retain', action='store_true'); args = parser.parse_args()
    if args.retain:
        rows = []
        for stage in STAGES:
            for extension in ('stdout', 'stderr', 'exit'):
                path = LOG / (stage + '.' + extension)
                rows.append(dict(pin(str(path.relative_to(ROOT))), raw_hex=path.read_bytes().hex()))
        write(BASE / 'verification-outputs.json', rows)
    result = verify()
    if args.retain:
        write(BASE / 'review.json', result)
    else:
        assert document(BASE / 'review.json') == result
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
