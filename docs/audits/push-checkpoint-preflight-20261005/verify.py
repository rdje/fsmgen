"""Verify the dated checkpoint, never execute CI, push or a policy override."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/push-checkpoint-preflight-20261005')
REVISION = 'dedee81cc1c359404411fa79d607e550a8618823'
GATE_PATH = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'
GATE_OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2'


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def check(record):
    require(record['revision'] == REVISION and record['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.1',
            'exact dated checkpoint authority')
    upstream = record['upstream_revision']
    require(type(upstream) is str and re.fullmatch('[0-9a-f]{40}', upstream), 'exact dated upstream revision kind')
    domain = upstream + '..' + REVISION
    count = int(subprocess.check_output(['git', 'rev-list', '--count', domain], text=True))
    members = subprocess.check_output(['git', 'log', '--format=%H', domain], text=True).splitlines()
    require(type(record['observed_count']) is int and count == record['observed_count'] == len(members)
            and members == record['independent_members'] and len(set(record['independent_members'])) == count,
            'complete independent Git member/count identity disagrees')
    require(count >= 500, 'dated cadence threshold is not reached')
    policy = record['policy']
    require(policy['path'] == 'COMMIT.md', 'exact policy path')
    raw = subprocess.check_output(['git', 'show', REVISION + ':COMMIT.md'])
    require(policy['whole_body'].encode() == raw and identity(raw) == policy['identity'], 'whole committed cadence policy')
    require('500 accumulated local' in policy['whole_body'], 'actual standing cadence requirement')
    gate = record['gate']
    require(gate['path'] == GATE_PATH and gate['owner'] == GATE_OWNER, 'exact active HIAL gate allocation')
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + GATE_PATH])
    require(identity(raw) == gate['whole_source_identity'], 'whole committed HIAL source identity')
    source = raw.decode(); start = source.index('- ID: `' + GATE_OWNER + '`'); end = source.index('\n- ID:', start + 1)
    require(source[start:end] == gate['whole_owner_body'], 'whole committed active HIAL gate body')
    require('\n  Status: `active`\n' in gate['whole_owner_body'] and 'full CI and push remain gated.' in gate['whole_owner_body'],
            'actual active full-CI/push gate requirement')


def main():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    require({path.name for path in BASE.iterdir()} == set(manifest) | {'manifest.json'}, 'complete checkpoint seal membership')
    for name, expected in manifest.items():
        require(identity((BASE / name).read_bytes()) == expected, 'whole checkpoint sealed member: ' + name)
    record = json.loads((BASE / 'preflight.json').read_text())
    check(record)
    controls = []
    mutations = [
        ('wrong-count', lambda row: row.update(observed_count=row['observed_count'] - 1), 'complete independent Git member/count identity disagrees'),
        ('omitted-member', lambda row: row['independent_members'].pop(), 'complete independent Git member/count identity disagrees'),
        ('duplicate-member', lambda row: row['independent_members'].__setitem__(-1, row['independent_members'][0]), 'complete independent Git member/count identity disagrees'),
        ('waived-gate', lambda row: row['gate'].update(whole_owner_body=row['gate']['whole_owner_body'].replace('full CI and push remain gated.', 'full CI and push may proceed.')), 'whole committed active HIAL gate body'),
    ]
    for name, mutate, cause in mutations:
        bad = copy.deepcopy(record); mutate(bad)
        try:
            check(bad)
        except ValueError as error:
            require(str(error) == cause, 'wrong intended checkpoint control cause: ' + name)
            controls.append(dict(control=name, status=1, error=str(error)))
        else:
            raise ValueError('false-green checkpoint control: ' + name)
    require(controls[:3] == record['controls'], 'complete saved checkpoint count controls')
    print(json.dumps(dict(status=0, revision=REVISION, controls=controls,
                          scope='Dated documentary checkpoint only; current count derives afresh. No full CI/push or override executed.'), sort_keys=True))


if __name__ == '__main__':
    main()
