"""Authenticate admitted finite primary/raw consumers without recapturing originals."""
import json
from pathlib import Path

import book_source_references as plane
import record_value_observer_fact as finite
import record_value_observer_namespace_fact as namespace
import record_value_raw_fact as raw_fact

PREPARATION = Path('docs/audits/consumer-canonical-preparation-20261012')
CARD = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
REVISION = 'f6d6ab4bf08982dc250b231054385f0f371180ac'
CHANGES = (('Full source-chain/separate probe replay needed.',
  'Full source-chain/separate probe replay needed. Independent source models qualify typed consumer '
  'operands/truth, never\n'
  'passed flags; Storable kinds/synthetic trace opacity retain.'),
 ('consumer/alias/semantic/cold/candidate-parent/hot/host-native stay open.',
  'consumer-parent/alias/semantic/cold/candidate-parent/hot/host-native stay open.'),
 ('Fresh same-volume replay pins sources/all native records/both streams; addresses have per-capture '
  'lifetimes, sealed producers run\n'
  'elsewhere.',
  'Same-volume replay pins all sources/native records/streams; addresses live per capture, sealed producers '
  'run elsewhere.'),
 ('Every\n'
  'copied width binds raw type, carrier/default/metadata, ancestor context/compatible sources. Captured '
  'input/private joins qualify\n'
  'whole graph/field/source/context/raw-kind/detachment.',
  'Copied widths bind raw type/carrier/default/metadata, ancestor context/compatible sources. Input/private '
  'joins qualify\n'
  'whole graph/field/source/context/raw-kind/detachment.'),
 ('Finite contexts bind helper/consumer/parser locations and whole parser\n'
  'texts/operation spans apart from cause/operand truth;',
  'Finite contexts bind helper/consumer/parser locations/whole texts/operation spans apart from '
  'cause/operand truth;'),
 ('Native refusals retain whole causes, class, HASH shape and within-capture identity for both observed '
  'empty blessed classes.',
  'Native refusals retain whole causes/class/HASH shape/within-capture identity for both observed empty '
  'blessed classes.'),
 ('Native-class copy/structured-clone cycles stay unqualified; graph/cause/identity/whole-programme '
  'mutations reject.',
  'Native-class copy/structured-clone cycles unqualified; graph/cause/identity/whole-programme mutations '
  'reject.'),
 ('Original Storable/alias trials keep unchanged inputs/full\ndownstream alias mutation/abort.',
  'Original Storable/alias trials retain unchanged inputs/full downstream alias mutation/abort.'),
 ('Plain-profile models qualify whole typed graph bijections, reachable reference counts, input/result '
  'sharing, readonly, kinds, cycles\n'
  'and detachment.',
  'Plain models qualify whole typed graph bijections/reachable reference counts/input-result '
  'sharing/readonly/kinds/cycles/detachment.'),
 ('Source/publisher contracts infer unblessed scalar errors; original classes\n'
  'were unmeasured. POD4.05 is stale; runtime version is JSON::PP4.06.',
  'Source/publisher contracts infer unblessed scalar errors; original classes unmeasured. POD4.05 is stale; '
  'runtime JSON::PP4.06.'),
 ('Independent typed models qualify original graphs/trials/readonly/detachment and whole API/parser\n'
  'source-model results; private-source allocations conserve.',
  'Independent typed models qualify original graphs/trials/readonly/detachment/whole API-parser source-model '
  'results; private allocations conserve.'),
 ('Nested\n'
  'Scope/capture/private-root inputs bind whole source-built interface kinds/sharing/cycles. Whole inner '
  'scalar forwards with new outer\n'
  'prefix.',
  'Nested Scope/capture/private-root inputs bind whole source-built interface kinds/sharing/cycles. Whole '
  'inner scalar forwards with new outer prefix.'),
 ('Public die controls separate explicit rethrow/propagation/hook replacement; original hook state/provider '
  'bytes stay\n'
  'unmeasured.',
  'Public die controls separate rethrow/propagation/hook replacement; original hook state/provider bytes '
  'unmeasured.'),
 ('Original own source/recipe/raw coordinates independently qualify whole result/custody; genuine controls '
  'preserve prior frame\n'
  'meanings before refusal.',
  'Own source/recipe/raw coordinates independently qualify whole result/custody; genuine controls preserve '
  'prior frame meanings before refusal.'),
 ('Own original reference numbers agree for explicit aliases and differ for qualified distinctions per '
  'simultaneous source/holder\n'
  'domain',
  'Own reference numbers agree for explicit aliases/differ for qualified distinctions per simultaneous '
  'source/holder domain'),
 ('Private range sibling width changes string2 to number2; detached private copy keeps outer caller.',
  'Private range sibling width changes string2 to number2; detached copy keeps outer caller.'))
GUIDE = 'Canonical consumer publication admits only reviewed source-derived typed operands\nand independent truth. Storable/synthetic/native/private limits retain; complete\ncanonical/original consumer acceptance remains separate:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/consumer-canonical-publication-20261012/verify.py\n```\n\n'

def require(condition, consumer):
    if not condition:
        raise ValueError(consumer)


def admission():
    # Fixed code authority applies before candidate-supplied fields are read.
    raw = finite.local(PREPARATION / 'candidate.json', CANDIDATE)
    require(finite.identity(raw) == CANDIDATE, 'whole fixed consumer candidate before first admission')
    return json.loads(raw)


def published(candidate):
    require(type(candidate) is dict and set(candidate) == {
        'after', 'after_identity', 'authority', 'before', 'before_identity',
        'canonical_members', 'correspondence', 'owner', 'previous', 'proposed',
        'queries', 'review', 'revision', 'schema_version', 'scope', 'target'},
        'closed complete admitted consumer candidate')
    original = admission()
    require(type(candidate['schema_version']) is int and candidate['schema_version'] == 1
            and candidate['revision'] == REVISION and candidate['owner'] == original['owner']
            and candidate['target'] == CARD, 'exact admitted consumer source role')
    before = candidate['before']
    require(type(before) is str and before == original['before']
            and finite.identity(before.encode()) == candidate['before_identity'],
            'whole admitted consumer predecessor meanings and routes')
    after = before
    for old, new in CHANGES:
        require(after.count(old) == 1, 'unique admitted consumer meaning allocation')
        after = after.replace(old, new, 1)
    require(candidate['after'] == after and candidate['after_identity'] == finite.identity(after.encode())
            and before.split('---\n', 2)[:2] == after.split('---\n', 2)[:2],
            'whole admitted consumer meanings questions metadata and probes')
    require(set(candidate['previous']) == set(original['previous']) == set(candidate['proposed'])
            and all(type(candidate[role][key]) is int for role in ('previous', 'proposed')
                    for key in original['previous'])
            and candidate['previous'] == original['previous']
            and candidate['proposed'] == original['proposed']
            and all(value <= candidate['previous'][key] for key, value in candidate['proposed'].items())
            and len(after.encode()) <= len(before.encode()), 'non-growing admitted consumer capacity')
    require(raw_fact.encoded(candidate['scope']) == raw_fact.encoded(original['scope']),
            'whole admitted consumer source native private boundary')
    require(all(raw_fact.encoded(candidate[key]) == raw_fact.encoded(original[key]) for key in (
        'authority', 'canonical_members', 'correspondence', 'queries', 'review')),
        'whole admitted consumer authority source review and query custody')
    return after


def cards(previous):
    candidate = admission()
    require(CARD in previous and previous[CARD] == candidate['before'],
            'whole predecessor consumer meanings and routes')
    return dict(previous, **{CARD: published(candidate)})


def preparation():
    manifest = json.loads(finite.local(PREPARATION / 'manifest.json', EXTRAS['manifest.json']))
    declared, modes = {}, {}
    for name, entry in manifest.items():
        require(Path(name).name == name and type(entry) is dict
                and set(entry) == {'bytes', 'sha256', 'executable'} and type(entry['executable']) is bool,
                'closed complete consumer preparation member')
        declared[name] = {key: entry[key] for key in ('bytes', 'sha256')}
        modes[name] = entry['executable']
    require(not set(declared).intersection(EXTRAS), 'distinct consumer seal and external receipt roles')
    declared.update(EXTRAS)
    namespace.check_tree(plane.ROOT / PREPARATION, declared)
    require(all(bool((plane.ROOT / PREPARATION / name).stat().st_mode & 0o111) == modes.get(name, False)
                for name in declared), 'complete consumer preparation executable modes')
    return declared


def check_actual(actual, role):
    expected = ACTUALS[role]
    require(type(actual) is dict and set(actual) == {
        'command', 'condition', 'expected_status', 'programmes', 'programmes_after',
        'status', 'stderr', 'stderr_path', 'stdout', 'stdout_path'}, 'closed complete consumer actual result')
    require(type(actual['status']) is int and actual['status'] == 0
            and type(actual['expected_status']) is int and actual['expected_status'] == 0,
            'actual admitted consumer integer success')
    require(actual['command'] == expected['command'], 'exact admitted consumer actual source command')
    require(actual['stdout'] == expected['stdout'] and actual['stderr'] == expected['stderr'],
            'whole admitted consumer actual terminal')
    require(finite.identity(raw_fact.encoded(actual)) == expected['identity'],
            'whole admitted consumer actual programme and source custody')



def check_failed_size(actual):
    require(type(actual) is dict and set(actual) == {
        'command', 'condition', 'expected_status', 'programmes', 'programmes_after',
        'status', 'stderr', 'stderr_path', 'stdout', 'stdout_path'}, 'closed original consumer size failure')
    require(type(actual['status']) is int and actual['status'] == 1
            and type(actual['expected_status']) is int and actual['expected_status'] == 0,
            'typed original unexpected consumer size refusal')
    require(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'scripts/check_live_document_size.sh'],
            'exact original consumer size failure command')
    require(finite.identity(raw_fact.encoded(actual)) == FIRST_FAILURE,
            'whole original consumer size failure programme and terminal custody')

def authenticate():
    declared = preparation()
    candidate = admission()
    published(candidate)
    roles = json.loads(finite.local(PREPARATION / 'source-roles.json', declared['source-roles.json']))
    require(roles['publication']['revision'] == REVISION, 'exact fixed consumer preparation source revision')
    source = raw_fact.source_census(roles['publication'])
    before = json.loads(finite.local(PREPARATION / 'source-before.json', declared['source-before.json']))
    after = json.loads(finite.local(PREPARATION / 'source-after.json', declared['source-after.json']))
    require(before == after and before['source'] == source, 'whole conserved admitted consumer source epoch')
    proof = json.loads(finite.local(PREPARATION / 'proof.json', EXTRAS['proof.json']))
    qualification = json.loads(finite.local(PREPARATION / 'qualification.json', declared['qualification.json']))
    require(proof['source'] == finite.identity(raw_fact.encoded(roles)) and proof['qualification'] == qualification
            and qualification['candidate'] == CANDIDATE and qualification['scope'] == candidate['scope'],
            'whole admitted consumer qualification source and proposal association')
    failure = json.loads(finite.local(PREPARATION / 'size-actual.json', declared['size-actual.json']))
    check_failed_size(failure)
    repaired = json.loads(finite.local(PREPARATION / 'size-repaired-actual.json', declared['size-repaired-actual.json']))
    require(type(repaired['status']) is int and repaired['status'] == 0
            and type(repaired['expected_status']) is int and repaired['expected_status'] == 0
            and repaired['command'] == ['scripts/run_with_ram_guard.sh', '--', 'scripts/check_live_document_size.sh']
            and finite.identity(raw_fact.encoded(repaired)) == REPAIRED_SIZE,
            'whole typed repaired consumer pointer size qualification')
    recovery = json.loads(finite.local(PREPARATION / 'recovery.json', declared['recovery.json']))
    recovered_source = json.loads(finite.local(PREPARATION / 'recovery-source.json', declared['recovery-source.json']))
    require(proof['recovery']['first_failure'] == FIRST_FAILURE
            and proof['recovery']['gates']['size-repaired'] == REPAIRED_SIZE
            and proof['recovery']['publication'] == recovery
            and proof['recovery']['source'] == recovered_source
            and recovered_source['source'] == source
            and recovered_source['overlays'] == recovery['snapshots'],
            'whole source-bound consumer first-failure and repaired metadata roles')
    actuals = {}
    for role in ACTUALS:
        actual = json.loads(finite.local(PREPARATION / (role + '-actual.json'), declared[role + '-actual.json']))
        check_actual(actual, role)
        actuals[role] = finite.identity(raw_fact.encoded(actual))
    return dict(preparation=declared, candidate=CANDIDATE, source=source,
                source_roles=finite.identity(raw_fact.encoded(roles)), actuals=actuals,
                scope='Complete admitted finite consumer preparation and fixed original source/native evidence authentication, including the retained first size failure and qualified pointer recovery. No fresh original semantic recapture, later historical-programme currency, native/private identity or canonical/original consumer-parent closure.')



CANDIDATE = {'bytes': 2882473, 'sha256': '4d4027067b154d2407548f13920f0a93645f4a9f87adfa2e1ae58a147ba39cc0'}

EXTRAS = {'default-actual.json': {'bytes': 386200,
                         'sha256': 'a07e1eb749ceaaa3c3c471969dfbf93bc7b656ed32c76d74b4c0f2f92d6a640e'},
 'default-started.json': {'bytes': 193194,
                          'sha256': 'ed25737cd156f306bab54c12f8e592e98f30da50b24a19948033c9105bd823d1'},
 'manifest.json': {'bytes': 17930,
                   'sha256': 'e29d22ed408364cbed73875b8ebaaf8a367c865cee5ef4b0eafae6404399709c'},
 'proof.json': {'bytes': 1813589,
                'sha256': '855b4374ef1513db00adde9b6051a2ae7b09a1d4a9bac5855e10da6c4e250b85'},
 'seal-actual.json': {'bytes': 386215,
                      'sha256': '48ca0a09efbc4860484d3901f0723053d13d0e6cc4ba5575df7985c3e083ac0e'},
 'seal-started.json': {'bytes': 193209,
                       'sha256': 'db17d8d10eaf7a67f1e050a561050e34ba6b808b68a6ad00cb8151e04c869782'},
 'staged-doctrines-actual.json': {'bytes': 460936,
                                  'sha256': 'cf1dc3e99394dd942d602d89e33c08a0834383795edb4a93e67db863515f0ebb'},
 'staged-doctrines-started.json': {'bytes': 197638,
                                   'sha256': 'ceaa1c695eb8583da4098b00d106b70a48ae3a4810be8fa0db1f785be2e7aa3a'}}

ACTUALS = {'independent': {'command': ['scripts/run_with_ram_guard.sh',
                             '--',
                             'python3',
                             '-B',
                             'docs/audits/consumer-canonical-preparation-20261012/reader.py'],
                 'identity': {'bytes': 324578,
                              'sha256': '4ba2cf4e091d1517b26c97feb4e549f4559518ea6f5baccdc8a3639d94e7c1a5'},
                 'stderr': 'ram-guard: PID 17576; host 79.8%; host cutoff 88%; descendant RSS cutoff 4096 '
                           'MiB; poll 2s\n',
                 'stdout': 'PASS independent complete non-growing source-bound consumer canonical '
                           'preparation; production and original consumer acceptance remain open.\n'},
 'meaning': {'command': ['scripts/run_with_ram_guard.sh',
                         '--',
                         'python3',
                         '-B',
                         'docs/audits/consumer-meaning-parent-acceptance-20261012/verify.py'],
             'identity': {'bytes': 359762,
                          'sha256': '425703610718954e310a0dd1f7b8587c770c8062ed3499bc464d8228f2f9057e'},
             'stderr': 'ram-guard: PID 33775; host 76.3%; host cutoff 88%; descendant RSS cutoff 4096 MiB; '
                       'poll 2s\n',
             'stdout': 'PASS complete unchanged independent consumer-meaning parent acceptance; '
                       'canonical/original parent and higher owners retain.\n'},
 'recovery-source': {'command': ['scripts/run_with_ram_guard.sh',
                                 '--',
                                 'python3',
                                 '-B',
                                 'docs/audits/consumer-canonical-preparation-20261012/recover.py',
                                 '--source'],
                     'identity': {'bytes': 386161,
                                  'sha256': 'd6a9f873b008b88e52f11a9cd5df360cb98aba21a530d8a480e9a018126cefe9'},
                     'stderr': 'ram-guard: PID 25252; host 83.5%; host cutoff 88%; descendant RSS cutoff '
                               '4096 MiB; poll 2s\n',
                     'stdout': 'PASS complete current repaired source census and exact pointer metadata.\n'}}

FIRST_FAILURE = {'bytes': 356280, 'sha256': 'a1d6a00b53a2ce10cb0e5f812b37ec3f6677ea30fb3ffc9d76ec07f968f2a4f8'}
REPAIRED_SIZE = {'bytes': 417930, 'sha256': 'd3bd90d4344fa4466f2cf8bf9d029e3da7ec9ae922f50ff7ee4186799f29a56b'}
