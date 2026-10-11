"""Authenticate admitted finite primary/raw causes without recapturing originals."""
import json
from pathlib import Path

import book_source_references as plane
import record_value_observer_fact as finite
import record_value_observer_namespace_fact as namespace
import record_value_raw_fact as raw_fact

PREPARATION = Path('docs/audits/primary-raw-cause-canonical-preparation-20261011')
CARD = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
REVISION = '08036b4d4207ea879a007a6654fb1e6fd0a0e8aa'
CHANGES = (
    ('Raw bodies/lossless grammar/source joins qualify.', 'Whole cause/raw/empty/nested source joins/lossless grammar qualify.'),
    ('Finite contexts qualify helper/consumer/parser locations', 'Finite contexts bind helper/consumer/parser locations'),
    ('texts/operation spans separately from cause/operand truth;', 'texts/operation spans apart from cause/operand truth;'),
    ('detached private copy preserves outer caller.', 'detached private copy keeps outer caller.'),
    ('Complete source-chain/separate probe replay required.', 'Full source-chain/separate probe replay needed.'),
)
GUIDE = '''Canonical cause publication admits this reviewed non-growing proposal. The
current reader authenticates its full preparation and fixed source roles;
original assumptions/failures/native/private limits retain. Cause-parent
acceptance remains open:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/primary-raw-cause-canonical-publication-20261011/verify.py
```

'''


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def admission():
    # Fixed code authority applies before candidate-supplied fields are read.
    raw = finite.local(PREPARATION / 'candidate.json', CANDIDATE)
    require(finite.identity(raw) == CANDIDATE, 'whole fixed cause candidate before first admission')
    return json.loads(raw)


def published(candidate):
    require(type(candidate) is dict and set(candidate) == {
        'after', 'after_identity', 'authority', 'before', 'before_identity',
        'canonical_members', 'correspondence', 'owner', 'previous', 'proposed',
        'queries', 'review', 'revision', 'schema_version', 'scope', 'target'},
        'closed complete admitted cause candidate')
    original = admission()
    require(type(candidate['schema_version']) is int and candidate['schema_version'] == 1
            and candidate['revision'] == REVISION and candidate['owner'] == original['owner']
            and candidate['target'] == CARD, 'exact admitted cause source role')
    before = candidate['before']
    require(type(before) is str and before == original['before']
            and finite.identity(before.encode()) == candidate['before_identity'],
            'whole admitted cause predecessor meanings and routes')
    after = before
    for old, new in CHANGES:
        require(after.count(old) == 1, 'unique admitted cause meaning allocation')
        after = after.replace(old, new, 1)
    require(candidate['after'] == after and candidate['after_identity'] == finite.identity(after.encode())
            and before.split('---\n', 2)[:2] == after.split('---\n', 2)[:2],
            'whole admitted cause meanings questions metadata and probes')
    require(set(candidate['previous']) == set(original['previous']) == set(candidate['proposed'])
            and all(type(candidate[role][key]) is int for role in ('previous', 'proposed')
                    for key in original['previous'])
            and candidate['previous'] == original['previous']
            and candidate['proposed'] == original['proposed']
            and all(value <= candidate['previous'][key] for key, value in candidate['proposed'].items())
            and len(after.encode()) <= len(before.encode()), 'non-growing admitted cause capacity')
    require(raw_fact.encoded(candidate['scope']) == raw_fact.encoded(original['scope']),
            'whole admitted cause source native private boundary')
    require(all(raw_fact.encoded(candidate[key]) == raw_fact.encoded(original[key]) for key in (
        'authority', 'canonical_members', 'correspondence', 'queries', 'review')),
        'whole admitted cause authority source review and query custody')
    return after


def cards(previous):
    candidate = admission()
    require(CARD in previous and previous[CARD] == candidate['before'],
            'whole predecessor cause meanings and routes')
    return dict(previous, **{CARD: published(candidate)})


def preparation():
    manifest = json.loads(finite.local(PREPARATION / 'manifest.json', EXTRAS['manifest.json']))
    declared, modes = {}, {}
    for name, entry in manifest.items():
        require(Path(name).name == name and type(entry) is dict
                and set(entry) == {'bytes', 'sha256', 'executable'} and type(entry['executable']) is bool,
                'closed complete cause preparation member')
        declared[name] = {key: entry[key] for key in ('bytes', 'sha256')}
        modes[name] = entry['executable']
    require(not set(declared).intersection(EXTRAS), 'distinct cause seal and external receipt roles')
    declared.update(EXTRAS)
    namespace.check_tree(plane.ROOT / PREPARATION, declared)
    require(all(bool((plane.ROOT / PREPARATION / name).stat().st_mode & 0o111) == modes.get(name, False)
                for name in declared), 'complete cause preparation executable modes')
    return declared


def check_actual(actual, role):
    expected = ACTUALS[role]
    require(type(actual) is dict and set(actual) == {
        'command', 'condition', 'expected_status', 'programmes', 'programmes_after',
        'status', 'stderr', 'stderr_path', 'stdout', 'stdout_path'}, 'closed complete cause actual result')
    require(type(actual['status']) is int and actual['status'] == 0
            and type(actual['expected_status']) is int and actual['expected_status'] == 0,
            'actual admitted cause integer success')
    require(actual['command'] == expected['command'], 'exact admitted cause actual source command')
    require(actual['stdout'] == expected['stdout'] and actual['stderr'] == expected['stderr'],
            'whole admitted cause actual terminal')
    require(finite.identity(raw_fact.encoded(actual)) == expected['identity'],
            'whole admitted cause actual programme and source custody')


def authenticate():
    declared = preparation()
    candidate = admission()
    published(candidate)
    roles = json.loads(finite.local(PREPARATION / 'source-roles.json', declared['source-roles.json']))
    require(roles['publication']['revision'] == REVISION, 'exact fixed cause preparation source revision')
    source = raw_fact.source_census(roles['publication'])
    before = json.loads(finite.local(PREPARATION / 'source-before.json', declared['source-before.json']))
    after = json.loads(finite.local(PREPARATION / 'source-after.json', declared['source-after.json']))
    require(before == after and before['source'] == source, 'whole conserved admitted cause source epoch')
    proof = json.loads(finite.local(PREPARATION / 'proof.json', EXTRAS['proof.json']))
    qualification = json.loads(finite.local(PREPARATION / 'qualification.json', declared['qualification.json']))
    require(proof['source'] == finite.identity(raw_fact.encoded(roles)) and proof['qualification'] == qualification
            and qualification['candidate'] == CANDIDATE and qualification['scope'] == candidate['scope'],
            'whole admitted cause qualification source and proposal association')
    actuals = {}
    for role in ACTUALS:
        actual = json.loads(finite.local(PREPARATION / (role + '-actual.json'), declared[role + '-actual.json']))
        check_actual(actual, role)
        actuals[role] = finite.identity(raw_fact.encoded(actual))
    return dict(preparation=declared, candidate=CANDIDATE, source=source,
                source_roles=finite.identity(raw_fact.encoded(roles)), actuals=actuals,
                scope='Complete admitted finite cause preparation and fixed original source/native evidence authentication. No fresh original semantic recapture, later historical-programme currency, native/private identity or cause-parent closure.')


CANDIDATE = {'bytes': 2890658, 'sha256': '12b424c9bbf92e703517550d978915e96c7713c85f6daf281324d71524ff96bf'}


EXTRAS = {'default-actual.json': {'bytes': 261531,
                         'sha256': '8563d90e0fe3957b8000ffa058e8a91d0b578533139bf129aff442b31931c228'},
 'default-started.json': {'bytes': 130880,
                          'sha256': '04a4701a1f996177145ab63b6d57018b62ae334dfca36445a0dc486270e48759'},
 'manifest.json': {'bytes': 9375, 'sha256': '2e411cbd24816bdf3a69caf9030eb33d57fafd2b41038c228b6cbf948d9fff70'},
 'proof.json': {'bytes': 65797, 'sha256': '47f450cb6484240aebbf8b50c2c386b9759e889575251f77f0e222d998ce77db'},
 'seal-actual.json': {'bytes': 261534,
                      'sha256': 'b75e55e60f97434e08c211d2279993e7e1ca2d7f3baef8a5c2a2830b82699074'},
 'seal-started.json': {'bytes': 130883,
                       'sha256': 'f78eeb2cf376ba00e5feeaa0274e9cf14d04324bb393c4d3702251eb56ddd043'},
 'staged-doctrines-actual.json': {'bytes': 336290,
                                  'sha256': '4a3b263506912e4f9f72480c75a205d78fdc50f6faba2258b343dcddb1f9a931'},
 'staged-doctrines-started.json': {'bytes': 135315,
                                   'sha256': '25808fa7c9e177ef9cedd77c1a42b0ad72184fb6a2e2f026a63991a270194d52'}}


ACTUALS = {'association': {'command': ['scripts/run_with_ram_guard.sh',
                             '--',
                             'python3',
                             '-B',
                             'docs/audits/primary-raw-cause-association-20261011/verify.py'],
                 'identity': {'bytes': 287022,
                              'sha256': '7febce6af6607f2a801df897a2d7e12a41bf3fd7ed546aa31142b5bd2018b8f8'},
                 'stderr': 'ram-guard: PID 74531; host 74.3%; host cutoff 88%; descendant RSS cutoff 4096 MiB; '
                           'poll 2s\n',
                 'stdout': 'PASS complete finite independent primary/raw cause association; canonical and '
                           'cause-parent acceptance remain open.\n'},
 'independent': {'command': ['scripts/run_with_ram_guard.sh',
                             '--',
                             'python3',
                             '-B',
                             'docs/audits/primary-raw-cause-canonical-preparation-20261011/reader.py'],
                 'identity': {'bytes': 261545,
                              'sha256': '4223b996828067a042ee62d9ec3e70a86e718047b9f4fcbdfbbb33c5c547b5fa'},
                 'stderr': 'ram-guard: PID 76107; host 76.2%; host cutoff 88%; descendant RSS cutoff 4096 MiB; '
                           'poll 2s\n',
                 'stdout': 'PASS independent complete non-growing source-bound cause canonical preparation; '
                           'production and cause-parent acceptance remain open.\n'}}
