#!/usr/bin/env python3
"""Authenticate closed history, live contracts and real read-only gate controls."""
import sys
sys.dont_write_bytecode = True
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
HISTORY = 'docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl'
TREE = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER'
RETENTION = 'doctrine/live_document_size/version_retention_contracts.jsonl'
BOUNDARY = 'Completed Acceptance History'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(*args, data=None):
    return subprocess.check_output(['git', *args], cwd=ROOT, input=data)


def exact(blob, path, digest):
    run = subprocess.run(['git', 'cat-file', 'blob', blob], cwd=ROOT, capture_output=True)
    data = run.stdout if run.returncode == 0 else (ROOT / path).read_bytes()
    assert sha(data) == digest
    assert git('hash-object', '--stdin', data=data).decode().strip() == blob
    return data


def dimensions(raw, record):
    marker = ('## ' + record['start_heading'] + '\n').encode()
    assert raw.count(marker) == 1 and raw.endswith(b'\n')
    history = raw[raw.index(marker):]
    expected = {'source_sha256': sha(raw), 'source_lines': len(raw.splitlines()),
        'source_bytes': len(raw), 'history_sha256': sha(history),
        'history_lines': len(history.splitlines()), 'history_bytes': len(history),
        'history_sections': len(re.findall(rb'^## ', history, re.M))}
    assert all(record[k] == v and type(record[k]) is type(v) for k, v in expected.items())
    return history


def preserved_nodes(old, new):
    assert set(old) == set(new)
    for name in old:
        if name not in (TREE + '.64', TREE + '.64.2'):
            assert old[name] == new[name], name


def fixture(name, task, history, successful):
    root = ROOT / '.artifacts/semantic-history-rollover-controls' / name
    for parent in (root, *root.parents):
        if parent == ROOT:
            break
        assert not parent.is_symlink() and not (parent / '.git').exists()
        if parent.exists():
            assert parent.stat().st_dev == ROOT.stat().st_dev
    for path, data in ((TASK, task.encode()), (HISTORY, history),
                       (RETENTION, (ROOT / RETENTION).read_bytes())):
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    (root / 'docs/TASK_TREE.md').write_text('# Controlled index\n\n'
        '| Tree | Status | Lane | Frontier | File |\n| --- | --- | --- | --- | --- |\n'
        f'| `{TREE}` | `active` | `fixture` | `.64.2` | [{TASK}]({TASK}) |\n')
    # With no nested .git, exact-source Git reads resolve to this project only.
    assert git('-C', str(root), 'rev-parse', '--show-toplevel').decode().strip() == str(ROOT)
    run = subprocess.run(['perl', 'scripts/check_task_tree_integrity.pl', '--root', str(root)],
        cwd=ROOT, capture_output=True, text=True)
    assert (run.returncode == 0) == successful, run.stdout + run.stderr
    return {'case': name, 'exit_code': run.returncode, 'expected_status_verified': True}


def main():
    proof = json.loads((HERE / 'manifest.json').read_bytes())
    assert proof['schema'] == 'fsmgen.semantic_history_rollover_proof.v1'
    assert sha(Path(__file__).read_bytes()) == proof['verifier_sha256']
    source = git('show', proof['source_revision'] + ':' + TASK)
    live = exact(proof['qualified_task_blob'], TASK, proof['qualified_task_sha256'])
    manifest_raw = exact(proof['qualified_history_blob'], HISTORY, proof['qualified_history_sha256'])
    registry, record = [json.loads(line) for line in manifest_raw.splitlines()]
    assert record['source_revision'] == proof['source_revision'] and record['start_heading'] == BOUNDARY
    history = dimensions(source, record)
    independent = subprocess.check_output(['perl', '-MJSON::PP', '-MDigest::SHA=sha256_hex', '-e',
        r'''local $/; binmode STDIN; my $s=<STDIN>; my $needle="## $ARGV[0]\n";
        my $h=substr($s,index($s,$needle)); my $sl=()=$s=~/\n/g;
        my $hl=()=$h=~/\n/g; my $hs=()=$h=~/^## /mg;
        print encode_json({source_sha256=>sha256_hex($s),source_lines=>$sl,source_bytes=>length($s),
        history_sha256=>sha256_hex($h),history_lines=>$hl,history_bytes=>length($h),history_sections=>$hs});''',
        BOUNDARY], cwd=ROOT, input=source)
    assert all(record[k] == v for k, v in json.loads(independent).items())
    old_manifest = git('show', proof['source_revision'] + ':' + HISTORY)
    assert sha(old_manifest) == proof['prior_manifest_sha256']
    old_registry, old_record = [json.loads(line) for line in old_manifest.splitlines()]
    assert registry == old_registry
    dimensions(git('show', old_record['source_revision'] + ':' + TASK), old_record)

    # Consume the separately qualified immutable line-based node oracle.
    prior = ROOT / 'docs/audits/semantic-node-registration-20261001'
    prior_manifest = json.loads((prior / 'manifest.json').read_bytes())
    assert sha((prior / 'verify.py').read_bytes()) == prior_manifest['verifier_sha256']
    spec = importlib.util.spec_from_file_location('registration_records', prior / 'verify.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    old, new = module.records(module.section(source.decode())), module.records(module.section(live.decode()))
    preserved_nodes(old, new)
    assert set(module.records(live.decode())) == set(new)
    assert b'\n## ' + BOUNDARY.encode() + b'\n' not in live
    for text in ('The T1921 pre-exec setpgid EPERM remains an unresolved native occurrence',
                 'Preserve spent compiler/startup evidence', 'Source admission alone does not qualify their runtime.'):
        assert text.encode() in source and text.encode() in live
    assert b'Binary-valued execution cannot establish\nfour-state X/Z behavior' in live

    results = [fixture('complete_qualified_rollover', live.decode(), manifest_raw, True)]
    for name, change in (
        ('source_digest', lambda r: r.update(source_sha256='0' * 64)),
        ('suffix_digest', lambda r: r.update(history_sha256='0' * 64)),
        ('string_dimension', lambda r: r.update(source_lines=str(r['source_lines']))),
        ('missing_source_heading', lambda r: r.update(start_heading='Absent History Boundary')),
    ):
        bad = copy.deepcopy(record)
        change(bad)
        rows = b'\n'.join(json.dumps(x, sort_keys=True).encode() for x in (registry, bad)) + b'\n'
        results.append(fixture(name, live.decode(), rows, False))
    displaced = live.decode().replace('## Version-Retrievable Historical Views', '## Displaced Historical Views', 1)
    results.append(fixture('displaced_live_pointer', displaced, manifest_raw, False))
    changed = copy.deepcopy(new)
    changed[TREE + '.65'] += 'corrupted field\n'
    try:
        preserved_nodes(old, changed)
    except AssertionError:
        results.append({'case': 'changed_live_contract', 'expected_status_verified': True})
    else:
        raise AssertionError('changed live contract accepted')
    print(json.dumps({'complete_source_and_suffix_authenticated': True,
        'prior_manifest_and_exact_source_chain_authenticated': True,
        'independent_perl_digest_and_dimension_census_agrees': True,
        'all_original_node_contracts_preserved_except_owned_rollover': True,
        'active_native_and_feature_limits_remain_live': True,
        'unchanged_registry_bounds': True, 'source_suffix_products_overlap': True,
        'no_other_git_repository_created_or_modified': True, 'controls': results}, sort_keys=True))


if __name__ == '__main__':
    main()
