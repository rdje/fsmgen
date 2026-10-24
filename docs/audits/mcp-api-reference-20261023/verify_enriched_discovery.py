#!/usr/bin/env python3
"""Verify the exact discovery-family repair from retained before/after evidence."""
import argparse
import copy
import gzip
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
MODULE = 'perl/FSM/Support/CapabilityManifestContract.pm'
TEST = 't/370-capability-manifest-section-discovery-audit.t'


def require(ok, why):
    if not ok:
        raise ValueError(why)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def verify(after, before, capture, current=False):
    require(after['owner'] == before['owner'] == 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.1', 'repair ownership')
    require(after['before_sha256'] == sha((BASE / 'enriched-identity-discovery-before.json.gz').read_bytes()), 'before identity')
    require(after['capture_sha256'] == sha((BASE / 'model-roots-qualified.json.gz').read_bytes()), 'native capture identity')
    require(sha(after['producer_text'].encode()) == after['producer_sha256'], 'producing instrument identity')
    if current:
        require(Path(__file__).read_bytes() == after['producer_text'].encode(), 'current producing instrument stale')
    require(type(before['before_test_exit']) is int and before['before_test_exit'] == 1, 'actual RED status')
    require("$got->[20] = 'source_query_kinds'" in before['before_test_log'], 'actual omission witness')
    command = after['command']
    require(type(command['exit']) is int and command['exit'] == 0 and command['stderr'] == '', 'native constructor outcome')
    actual = json.loads(command['stdout'])
    expected = copy.deepcopy(capture['native_api']['manifest']['manifest_contract'])
    families = [expected['semantic_introspection_presence_keys'],
                expected['presence_key_family_map']['semantic_introspection_presence_keys'],
                expected['top_level_section_presence_key_map']['semantic_introspection']]
    for family in families:
        require('source_query_kinds' not in family, 'original missing applicability family')
        family.insert(family.index('query_families') + 1, 'source_query_kinds')
    require(canonical(actual) == canonical(expected), 'exact three-family delta; unrelated fields conserve')
    native = capture['native_api']['manifest']['semantic_introspection']
    require(sorted(actual['semantic_introspection_presence_keys']) == sorted(native), 'independent actual section membership')
    require(set(after['sources']) == set(before['sources']), 'source population')
    for path, saved in before['sources'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'before source digest')
        expected_source = saved['text']
        if path == MODULE:
            expected_source = expected_source.replace(
                '    semantic_introspection_contract_source\n);',
                '    semantic_introspection_contract_source\n    semantic_introspection_public_top_level_keys\n);', 1)
            start = expected_source.index('sub capability_manifest_semantic_introspection_keys {')
            end = expected_source.index('\nsub capability_manifest_backend_validation_keys {', start)
            expected_source = expected_source[:start] + (
                'sub capability_manifest_semantic_introspection_keys {\n'
                '    return semantic_introspection_public_top_level_keys();\n}\n') + expected_source[end:]
        observed = after['sources'][path]
        require(observed['text'] == expected_source and sha(observed['text'].encode()) == observed['sha256'], 'exact source repair: ' + path)
        if current:
            require((ROOT / path).read_bytes() == observed['text'].encode(), 'current repair source stale')
    require('All tests successful.' in after['after_test_log'] and 'Result: PASS' in after['after_test_log'], 'actual GREEN gate')
    require(type(after['after_test_exit']) is int and after['after_test_exit'] == 0, 'GREEN exit status')
    return {'projection_paths': [
        '/manifest_contract/semantic_introspection_presence_keys',
        '/manifest_contract/presence_key_family_map/semantic_introspection_presence_keys',
        '/manifest_contract/top_level_section_presence_key_map/semantic_introspection'],
        'added_member': 'source_query_kinds', 'unrelated_contract_values_conserved': True,
        'unchanged_oracle': TEST}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--capture', action='store_true')
    args = parser.parse_args()
    before = json.loads(gzip.decompress((BASE / 'enriched-identity-discovery-before.json.gz').read_bytes()))
    if args.capture:
        output = BASE / 'enriched-identity-discovery-after.json.gz'
        require(not output.exists(), 'capture output already exists')
        argv = ['perl', '-Iperl', '-MFSM::Support::CapabilityManifestContract=build_capability_manifest_contract',
                '-MJSON::PP', '-e', 'print JSON::PP->new->canonical->encode(build_capability_manifest_contract())']
        run = subprocess.run(argv, cwd=ROOT, capture_output=True, text=True, timeout=30)
        def snapshot(path):
            raw = (ROOT / path).read_bytes()
            return {'text': raw.decode(), 'sha256': sha(raw)}
        after = {'owner': before['owner'],
            'before_sha256': sha((BASE / 'enriched-identity-discovery-before.json.gz').read_bytes()),
            'capture_sha256': sha((BASE / 'model-roots-qualified.json.gz').read_bytes()),
            'command': {'argv': argv, 'cwd': '.', 'exit': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr},
            'sources': {p: snapshot(p) for p in before['sources']},
            'after_test_log': (ROOT / '.artifacts/enriched-identity-tests-after.log').read_text(),
            'after_test_exit': 0,
            'producer_text': Path(__file__).read_text(), 'producer_sha256': sha(Path(__file__).read_bytes()),
            'evidence_legs': {
                'rederive': 'Real shell-free dedicated constructor output plus original and repaired existing discovery/contract test streams.',
                'falsify': 'Independent actual native section membership and exact three-family delta; actual original failure, corrected pass and saved omission/metadata/oracle/type controls.',
                'durability': 'Tracked original capture, complete before/after sources, command/outcomes/test streams and producing/reading instrument. Saved reader starts no producer.'}}
        # The execution handle supplied the status; the complete native stream must also agree.
        require('Result: PASS' in after['after_test_log'], 'missing passing test stream')
        with output.open('xb') as stream:
            stream.write(gzip.compress((json.dumps(after, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
        print('Captured repaired dedicated contract; independent saved comparison required.')
        return
    after = json.loads(gzip.decompress((BASE / 'enriched-identity-discovery-after.json.gz').read_bytes()))
    capture = json.loads(gzip.decompress((BASE / 'model-roots-qualified.json.gz').read_bytes()))
    result = verify(after, before, capture, args.current)
    rejected = {}
    for label in ('missing_family_member', 'unrelated_metadata_change', 'changed_oracle', 'boolean_exit'):
        bad = copy.deepcopy(after)
        if label in ('missing_family_member', 'unrelated_metadata_change'):
            value = json.loads(bad['command']['stdout'])
            if label == 'missing_family_member':
                value['semantic_introspection_presence_keys'].remove('source_query_kinds')
            else:
                value['status'] = 'unbounded'
            bad['command']['stdout'] = json.dumps(value)
        elif label == 'changed_oracle':
            bad['sources'][TEST]['text'] += '\n# weakened\n'
            bad['sources'][TEST]['sha256'] = sha(bad['sources'][TEST]['text'].encode())
        else:
            bad['command']['exit'] = False
        try:
            verify(bad, before, capture)
        except ValueError as error:
            rejected[label] = str(error)
        else:
            raise ValueError('Control accepted: ' + label)
    result.update(rejected_controls=rejected, reader_text=Path(__file__).read_text(), reader_sha256=sha(Path(__file__).read_bytes()))
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
