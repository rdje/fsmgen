"""Verify the activity-derived retained replay census without running old code."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

BASE = '0cee23da75c4013f42eabfa2c4dc64bf76a84584'
PRIMARY = 'docs/audits/reduction-replay-identity-20261022.json.gz'
CORE = 'docs/audits/reduction-replay-identity-verify-20261022.py'
EXTRA = {
    'cli-quiet-intent-first-red-20261022.json.gz': 'before_edit_quiet_progress_probe',
    'cli-quiet-intent-settled-red-20261022.json.gz': 'before_edit_trace_and_json_probe',
    'reduction-operand-scope-qa-verify-20261022.py': 'read_only_task_snapshot_verifier',
    'unary-caller-capture-draft-20261022.json.gz': 'safe_identity_gate_refusal_before_source_query',
    'unary-corpus-accounting-first-20261022.json.gz': 'current_catalog_stale_expectation_failure',
    'unary-corpus-capture-draft-20261022.json.gz': 'capture_serialization_failure_before_queries',
    'unary-corpus-discovery-draft-20261022.json.gz': 'current_discovery_oracle_draft',
    'unary-corpus-failure-contract-draft-20261022.json.gz': 'current_refusal_oracle_draft',
    'unary-corpus-gate-refusal-20261022.json.gz': 'reference_declaration_gate_refusal',
    'unary-corpus-guide-first-20261022.json.gz': 'current_guide_snapshot',
    'unary-corpus-metadata-red-20261022.json.gz': 'current_phase_metadata_red',
    'unary-corpus-preservation-20261022.json.gz': 'current_source_preservation_and_census_repair',
    'unary-corpus-public-products-20261022.json.gz': 'current_public_and_caller_qualification',
}
PROOF = {PRIMARY, CORE, 'docs/audits/reduction-replay-identity-core-closure-20261022.json.gz'}


def need(condition, message):
    if not condition:
        raise ValueError(message)


def raw(path):
    return subprocess.check_output(['git', 'show', BASE + ':' + path])


def decode(path, data):
    if path.endswith('.gz'):
        return json.loads(gzip.decompress(data))
    if path.endswith('.json'):
        return json.loads(data)
    return data.decode()


def lookup(value, pointer):
    for token in pointer.split('/')[1:]:
        token = token.replace('~1', '/').replace('~0', '~')
        value = value[int(token)] if isinstance(value, list) else value[token]
    return value


def strings(value, pointer=''):
    if isinstance(value, str):
        yield pointer, value
    elif isinstance(value, list):
        for n, item in enumerate(value):
            yield from strings(item, pointer + '/' + str(n))
    elif isinstance(value, dict):
        for key, item in value.items():
            yield from strings(item, pointer + '/' + key.replace('~', '~0').replace('/', '~1'))


def verify(data):
    need(data['base_revision'] == BASE and data['owner'] == 'ISF-REDUCTION-DELIVERY.10.2', 'wrong activity owner/base')
    # Independent Git interface: one name-only history stream, with no filename
    # family or directory-depth filter, rather than the producer's diff-tree loop.
    owned = {}; revisions = []
    for line in subprocess.check_output(['git', 'log', BASE, '--format=ENTRY %H %s', '--name-only', '--', 'docs/audits'], text=True).splitlines():
        if line.startswith('ENTRY '):
            _, revision, subject = line.split(' ', 2)
            active = subject.startswith('ISF-REDUCTION-DELIVERY')
            if active:
                revisions.append((revision, subject))
        elif active and line.startswith('docs/audits/'):
            owned.setdefault(line, []).append(revision)
    primary = decode(PRIMARY, raw(PRIMARY))
    core_inventory = json.loads(primary['files']['.artifacts/tmp/reduction-replay-audit-f7e4b5968-20261022/inventory-v2.json']['text'])
    originals = {row['path'] for row in core_inventory['capsules']}
    intake = set(subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', BASE,
                                        'docs/audits/specforge-reduction-intake-20261021'], text=True).splitlines())
    expected = set(owned) | originals | intake
    rows = data['artifacts']
    need([row['path'] for row in rows] == sorted(expected), 'incomplete activity/artifact/intake join')
    need([(row['revision'], row['subject']) for row in data['commits']] == revisions, 'owning commit allocation/order differs')
    for commit in data['commits']:
        need(commit['artifacts'] == sorted(path for path, owners in owned.items() if commit['revision'] in owners),
             'commit-to-artifact allocation differs')
    additional = expected - originals - PROOF - intake
    need(additional == {'docs/audits/' + name for name in EXTRA}, 'unclassified additional artifact')
    for row in rows:
        path = row['path']; source = raw(path)
        need(source == Path(path).read_bytes(), 'retained original changed')
        need((len(source), hashlib.sha256(source).hexdigest()) == (row['bytes'], row['sha256']), 'artifact identity differs')
        need(row['owning_commits'] == owned.get(path, []), 'artifact work-unit attribution differs')
        need(row['git_blob'] == subprocess.check_output(['git', 'rev-parse', BASE + ':' + path], text=True).strip(), 'artifact Git object differs')
        cohort = 'core_originals' if path in originals else 'qualified_core_proof' if path in PROOF else 'canonical_intake' if path in intake else 'additional_owned'
        need(row['cohort'] == cohort, 'artifact cohort differs')
        if cohort in ('additional_owned', 'canonical_intake'):
            value = decode(path, source)
            reported = set()
            for hit in row['loader_candidates']:
                text = lookup(value, hit['pointer'])
                need(hashlib.sha256(text.encode()).hexdigest() == hit['text_sha256'], 'candidate source identity differs')
                lines = text.splitlines()
                for match in hit['matches']:
                    need(lines[match['line'] - 1] == match['text'], 'candidate line differs')
                    reported.add((hit['pointer'], match['line']))
            # Broader, separately written oracle: include ordinary roots and all
            # flags at token boundaries; producer false-positive hints may remain.
            for pointer, text in strings(value):
                for n, line in enumerate(text.splitlines(), 1):
                    if any(word in line for word in ('@INC', 'PERL5LIB', 'PERL5OPT')) or re.search(r'\buse\s+lib\b|(?:^|[\s\x22\x27\[])-I', line):
                        need((pointer, n) in reported, 'loader hint omitted by producer')
        expected_class = 'qualified_core_evidence_or_original_epoch' if cohort in ('core_originals', 'qualified_core_proof') else 'canonical_input_or_initial_source_observation' if cohort == 'canonical_intake' else EXTRA[Path(path).name]
        need(row['classification'] == expected_class, 'artifact evidence class differs')
    return {'owning_commits': len(revisions), 'owned_artifacts': len(owned), 'joined_artifacts': len(rows),
            'additional_owned': len(additional), 'canonical_intake': len(intake)}


def main():
    path = Path(sys.argv[1] if len(sys.argv) == 2 else 'docs/audits/reduction-replay-activity-20261022.json.gz')
    need(len(sys.argv) <= 2 and not path.is_absolute() and '..' not in path.parts, 'use a relative receipt path')
    data = json.loads(gzip.decompress(path.read_bytes()))
    need(data['verifier_sha256'] == hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), 'verifier source differs')
    need(data['producer_sha256'] == hashlib.sha256(data['producer_source'].encode()).hexdigest(), 'producer source differs')
    result = verify(data)
    for mutate in (lambda v: v['artifacts'].pop(), lambda v: v['commits'].pop(),
                   lambda v: v['artifacts'][0].__setitem__('classification', 'claimed_old_module_execution')):
        wrong = copy.deepcopy(data); mutate(wrong)
        try:
            verify(wrong)
        except (ValueError, KeyError, IndexError):
            continue
        raise ValueError('hostile allocation/classification mutation passed')
    subprocess.run([sys.executable, '-B', CORE], check=True)
    print('replay-activity: independent complete Git work-unit/intake join, loader hints and hostile controls verified')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
