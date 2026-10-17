"""Admit reviewed original joined meanings while preserving dated source custody."""
import gzip
import json
from pathlib import Path

import book_source_references as plane
import record_value_observer_fact as finite
import record_value_observer_namespace_fact as namespace
import record_value_raw_fact as raw_fact

PREPARATION = Path('docs/audits/original-join-canonical-preparation-20261012')
CARD = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
GUIDE = ('The current reader admits the reviewed original join; parent acceptance and\n'
         'original source/native limits retain their separate scopes.\n')


def require(value, cause):
    if not value:
        raise ValueError(cause)


def same(left, right):
    return raw_fact.encoded(left) == raw_fact.encoded(right)


def admission():
    compressed = finite.local(PREPARATION / 'v3-candidate.json.gz', COMPRESSED_CANDIDATE)
    body = gzip.decompress(compressed)
    require(finite.identity(body) == CANDIDATE, 'whole fixed original-join candidate before first admission')
    candidate = json.loads(body)
    require(raw_fact.encoded(candidate) == body, 'canonical complete original-join candidate')
    return candidate


def published(candidate):
    original = admission()
    require(type(candidate) is dict and set(candidate) == set(original), 'closed complete original-join candidate')
    require(type(candidate['schema_version']) is int and candidate['schema_version'] == 1
            and candidate['owner'] == OWNER and candidate['revision'] == SOURCE_REVISION
            and candidate['target'] == CARD, 'exact admitted original-join source role')
    before = candidate['before']
    require(type(before) is str and before == original['before']
            and same(candidate['before_identity'], finite.identity(before.encode())),
            'whole original-join predecessor meanings and routes')
    after = before
    for old, new in CHANGES:
        require(after.count(old) == 1, 'unique original-join meaning allocation')
        after = after.replace(old, new, 1)
    require(candidate['after'] == after and same(candidate['after_identity'], finite.identity(after.encode())),
            'whole reviewed original-join meanings and correspondence')
    require(before.split('---\n', 2)[1].replace('date: 2026-10-11\n', 'date: 2026-10-12\n', 1)
            == after.split('---\n', 2)[1], 'all original-join questions evidence and probes retain')
    dimensions = {'files', 'bytes_total', 'lines_total', 'bytes_each', 'lines_each', 'line_bytes_each'}
    require(all(type(candidate[role]) is dict and set(candidate[role]) == dimensions
                and all(type(value) is int for value in candidate[role].values())
                and same(candidate[role], original[role]) for role in ('previous', 'proposed'))
            and all(value <= candidate['previous'][key] for key, value in candidate['proposed'].items())
            and len(after.encode()) <= len(before.encode()), 'non-growing original-join capacity')
    require(same(candidate['scope'], original['scope']), 'whole original-join assumptions and native private boundaries')
    require(same(candidate['input_identities'], original['input_identities'])
            and same(candidate['contracts'], original['contracts']), 'every original-join source and parent contract')
    require(all(same(candidate[key], original[key]) for key in (
        'authority', 'canonical_members', 'correspondence', 'queries', 'review')),
        'whole original-join authority source review and query custody')
    return after


def cards(previous):
    candidate = admission()
    require(CARD in previous and previous[CARD] == candidate['before'], 'whole predecessor original-join meanings and routes')
    return dict(previous, **{CARD: published(candidate)})


def preparation():
    manifest = json.loads(finite.local(PREPARATION / 'manifest.json', EXTRAS['manifest.json']))
    declared, modes = {}, {}
    for name, entry in manifest.items():
        require(Path(name).name == name and type(entry) is dict
                and set(entry) == {'bytes', 'sha256', 'executable'} and type(entry['executable']) is bool,
                'closed complete original-join preparation member')
        declared[name] = {key: entry[key] for key in ('bytes', 'sha256')}
        modes[name] = entry['executable']
    require(not set(declared).intersection(EXTRAS), 'distinct original-join sealed and external roles')
    declared.update(EXTRAS)
    namespace.check_tree(plane.ROOT / PREPARATION, declared)
    require(all(bool((plane.ROOT / PREPARATION / name).stat().st_mode & 0o111) == modes.get(name, False)
                for name in declared), 'complete original-join preparation modes')
    return declared


def check_actual(actual, role):
    expected = ACTUALS[role]
    require(type(actual) is dict and set(actual) == ACTUAL_KEYS, 'closed whole original-join actual result')
    require(type(actual['status']) is int and actual['status'] == expected['status']
            and type(actual['expected_status']) is int and actual['expected_status'] == expected['expected_status'],
            'exact typed original-join native outcome')
    require(actual['command'] == expected['command'], 'exact original-join native command role')
    require(actual['stdout'] == expected['stdout'] and actual['stderr'] == expected['stderr'],
            'whole original-join native terminal')
    require(finite.identity(raw_fact.encoded(actual)) == expected['identity'],
            'whole original-join native programme and source custody')


def authenticate():
    declared = preparation()
    candidate = admission()
    published(candidate)
    def load(name):
        return json.loads(finite.local(PREPARATION / name, declared[name]))
    roles = load('v3-source-roles.json')
    require(roles['publication']['revision'] == SOURCE_REVISION, 'fixed original-join dated source revision')
    source = raw_fact.source_census(roles['publication'])
    before, after = load('v3-source-before.json'), load('v3-source-after.json')
    require(same(before, after) and before['source'] == source, 'whole conserved original-join dated source epoch')
    proof, qualification = load('proof.json'), load('v3-qualification.json')
    require(proof['source'] == finite.identity(raw_fact.encoded(roles))
            and proof['source_epoch'] == before and same(proof['qualification'], qualification)
            and qualification['candidate'] == CANDIDATE and same(qualification['scope'], candidate['scope']),
            'whole original-join source qualification and proposal association')
    for name, identity in candidate['input_identities'].items():
        finite.fingerprint(name, identity)
    actuals = {}
    for role in ACTUALS:
        actual = load(role + '-actual.json')
        check_actual(actual, role)
        actuals[role] = finite.identity(raw_fact.encoded(actual))
    return dict(preparation=declared, candidate=CANDIDATE, source=source,
                source_roles=finite.identity(raw_fact.encoded(roles)), actuals=actuals,
                scope=candidate['scope'], condition='Authenticate complete fixed preparation, original source roles, native controls, first failures and repairs. No fresh original semantic execution, later historical-programme currency, native/private identity, original parent/full-alias or HIAL/full-CI/push/visual closure.')


COMPRESSED_CANDIDATE = {'bytes': 601228, 'sha256': 'ceb890ac7ca617bbdb518b340577d91d7754cbdd24567e8b3ed833c1457821b1'}

CANDIDATE = {'bytes': 3687252, 'sha256': 'c557723a0691cc5304a9ee5b1238b554dc2029b4efa1e60c054ca4a2f02302bb'}

EXTRAS = {'default-actual.json': {'bytes': 3161362,
                         'sha256': '6ba3128b8e6b55acd39616a0272f3766eb480701d94a60ceb4e406610560292f'},
 'default-resources.json.gz': {'bytes': 5348552,
                               'sha256': '01f1b3c8950fe06c97d36427abaf8fc2935321763b458d098b9283b5daeef0cb'},
 'default-started.json': {'bytes': 1580788,
                          'sha256': 'b8fdffcf4853f2efb011d40b4dc9c79ad754c331c9fa6fffd704b02790361063'},
 'manifest.json': {'bytes': 62184,
                   'sha256': '6ddef7578c30d6333afa0ae6a9685981ef13b7fd8773ea00fb3f1bf831164367'},
 'proof.json': {'bytes': 3145716,
                'sha256': '26009e922d7c5985ea5d89c09d11c798e5eff6fcdb38c0a0480c796079e23f6d'},
 'seal-actual.json': {'bytes': 3161365,
                      'sha256': '82483d195a14c45592391826166ac801496487157bde4d8061bde81d8b9ad88b'},
 'seal-resources.json.gz': {'bytes': 5688794,
                            'sha256': 'dea310a347fe57daf4db288d8f115f068b1ecbe8663bed5647d5097fa8dc98d6'},
 'seal-started.json': {'bytes': 1580791,
                       'sha256': '044f17bedd9a43fb473ae52d23a0003a39ed1f5a8f362bfbc51ceb49c26e0f17'},
 'staged-doctrines-actual.json': {'bytes': 3236120,
                                  'sha256': 'adefb855fc24c65221fee7c579799fe6bf43c190be264e29cacb05359c84ffe5'},
 'staged-doctrines-started.json': {'bytes': 1585227,
                                   'sha256': '815d4509a83ad02ba7c7c6eb90304c56f0adabe06be6ab65d5060571a5c107c9'}}

OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.1'

SOURCE_REVISION = '192c9dae1f788fb13a0b10c1d1eb952875b03dd6'

CHANGES = [['date: 2026-10-11\n', 'date: 2026-10-12\n'],
 ['Full source-chain/separate probe replay needed. Independent source models qualify typed '
  'consumer operands/truth, never\n'
  'passed flags; Storable kinds/synthetic trace opacity retain.',
  'Full source-chain/separate probe replay needed. Independent source models join all original '
  'context/cause/coordinate/typed\n'
  'consumer operands/truth, never passed flags; Storable kinds/synthetic trace opacity retain.'],
 ['consumer-parent/alias/semantic/cold/candidate-parent/hot/host-native stay open.',
  'higher parents/alias/semantic/cold/candidate-parent/hot/host-native stay open.'],
 ['coordinates/finite address roles qualify below.', 'coordinates/finite address roles qualify.'],
 ['Finite joins authenticate completed owners/fresh products.',
  'Finite joins verify completed owners/fresh products.'],
 ['Copy interventions rebuild whole input/private typed graphs, readonly',
  'Copy trials rebuild whole input/private typed graphs, readonly'],
 ['Metadata guards/record recursion/cycles qualify; list recursion is bound, unexercised.',
  'Metadata guards/record recursion/cycles qualify; list recursion bound, unexercised.'],
 ['active `$operation` retains saved CODE handles.',
  'active `$operation` holds saved CODE handles.'],
 ['Native refusals retain whole causes/class/HASH shape/within-capture identity for both observed '
  'empty blessed classes.',
  'Native refusals retain whole causes/class/HASH shape/within-capture identity of both observed '
  'empty blessed classes.'],
 ['Nested Metadata/new outer Value retain distinct class/phase roles and whole',
  'Nested Metadata/new outer Value keep distinct class/phase roles and whole'],
 ['Source associations precede raw intake;', 'Source joins precede raw intake;']]

ACTUALS = {'default': {'command': ['scripts/run_with_ram_guard.sh',
                         '--',
                         'python3',
                         '-B',
                         'docs/audits/original-join-canonical-preparation-20261012/verify.py'],
             'expected_status': 0,
             'identity': {'bytes': 3161362,
                          'sha256': '6ba3128b8e6b55acd39616a0272f3766eb480701d94a60ceb4e406610560292f'},
             'status': 0,
             'stderr': 'ram-guard: PID 16573; host 71.2%; host cutoff 88%; descendant RSS cutoff '
                       '4096 MiB; poll 2s\n',
             'stdout': 'PASS complete non-growing original join canonical preparation; production '
                       'original parents and full alias remain separate.\n'},
 'independent-v3': {'command': ['scripts/run_with_ram_guard.sh',
                                '--',
                                'python3',
                                '-B',
                                'docs/audits/original-join-canonical-preparation-20261012/reader.py',
                                '--candidate',
                                'v3-candidate.json.gz',
                                '--save'],
                    'expected_status': 0,
                    'identity': {'bytes': 3161778,
                                 'sha256': 'cf2f9832dd71d2bd83a461243496156ae6a1fd07ec5749554b83081fad3db922'},
                    'status': 0,
                    'stderr': 'ram-guard: PID 87326; host 68.7%; host cutoff 88%; descendant RSS '
                              'cutoff 4096 MiB; poll 2s\n',
                    'stdout': 'PASS independent complete non-growing original-join canonical '
                              'preparation; production original parents and full alias remain '
                              'separate.\n'},
 'native-first': {'command': ['scripts/run_with_ram_guard.sh',
                              '--',
                              'python3',
                              '-B',
                              'scripts/check_record_value_publication.py',
                              '--build',
                              'docs/book/book'],
                  'expected_status': 0,
                  'identity': {'bytes': 3162426,
                               'sha256': 'eb6bf08b79f62456a344cabb7a8c64d9434bfbd7146771639b58886a23f57f21'},
                  'status': 1,
                  'stderr': 'ram-guard: PID 71798; host 73.7%; host cutoff 88%; descendant RSS '
                            'cutoff 4096 MiB; poll 2s\n'
                            'Traceback (most recent call last):\n'
                            '  File '
                            '"/Volumes/SSD/Documents/github/fsmgen/scripts/check_record_value_publication.py", '
                            'line 290, in <module>\n'
                            '    main()\n'
                            '    ~~~~^^\n'
                            '  File '
                            '"/Volumes/SSD/Documents/github/fsmgen/scripts/check_record_value_publication.py", '
                            'line 264, in main\n'
                            '    plane.check_index(rows)\n'
                            '    ~~~~~~~~~~~~~~~~~^^^^^^\n'
                            '  File '
                            '"/Volumes/SSD/Documents/github/fsmgen/scripts/book_source_references.py", '
                            'line 197, in check_index\n'
                            '    '
                            'check_object(path,mode,local_read(ROOT/path,max(SOURCE_BYTES,MANIFEST_BYTES)))\n'
                            '    '
                            '~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n'
                            '  File '
                            '"/Volumes/SSD/Documents/github/fsmgen/scripts/book_source_references.py", '
                            'line 191, in check_object\n'
                            "    require(indexed[path] == (mode,wanted), 'checked bytes/mode agree "
                            "with Git result: '+path)\n"
                            '    '
                            '~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n'
                            '  File '
                            '"/Volumes/SSD/Documents/github/fsmgen/scripts/book_source_references.py", '
                            'line 32, in require\n'
                            '    if not condition: raise ValueError(message)\n'
                            '                      ^^^^^^^^^^^^^^^^^^^^^^^^^\n'
                            'ValueError: checked bytes/mode agree with Git result: MEMORY.md\n',
                  'stdout': ''},
 'replay-association': {'command': ['scripts/run_with_ram_guard.sh',
                                    '--',
                                    'python3',
                                    '-B',
                                    'docs/audits/original-context-cause-consumer-association-20261012/verify.py'],
                        'expected_status': 0,
                        'identity': {'bytes': 3118240,
                                     'sha256': '51040108f9c488cbd5adfc90daf91c9895ba5627b3e82d8a493454d0cf7087d3'},
                        'status': 137,
                        'stderr': 'ram-guard: PID 90870; host 73.4%; host cutoff 88%; descendant '
                                  'RSS cutoff 4096 MiB; poll 2s\n'
                                  'ram-guard: host memory 88.2% reached cutoff 88%\n'
                                  'ram-guard: terminating PID tree: 90870 \n',
                        'stdout': ''},
 'replay-association-v2': {'command': ['scripts/run_with_ram_guard.sh',
                                       '--',
                                       'python3',
                                       '-B',
                                       'docs/audits/original-context-cause-consumer-association-20261012/verify.py'],
                           'expected_status': 0,
                           'identity': {'bytes': 3141525,
                                        'sha256': '14944b9702696ea5034cac4bd951e608e966d0f99a625b4b01b00b265201bec8'},
                           'status': 0,
                           'stderr': 'ram-guard: PID 5077; host 72.0%; host cutoff 88%; descendant '
                                     'RSS cutoff 4096 MiB; poll 2s\n',
                           'stdout': 'PASS complete independent original '
                                     'context/cause/coordinate/consumer association; '
                                     'canonical/parent acceptance and higher owners remain '
                                     'separate.\n'},
 'seal': {'command': ['scripts/run_with_ram_guard.sh',
                      '--',
                      'python3',
                      '-B',
                      'docs/audits/original-join-canonical-preparation-20261012/verify.py',
                      '--seal'],
          'expected_status': 0,
          'identity': {'bytes': 3161365,
                       'sha256': '82483d195a14c45592391826166ac801496487157bde4d8061bde81d8b9ad88b'},
          'status': 0,
          'stderr': 'ram-guard: PID 63508; host 74.6%; host cutoff 88%; descendant RSS cutoff 4096 '
                    'MiB; poll 2s\n',
          'stdout': 'PASS complete non-growing original join canonical preparation; production '
                    'original parents and full alias remain separate.\n'},
 'seal-first': {'command': ['scripts/run_with_ram_guard.sh',
                            '--',
                            'python3',
                            '-B',
                            'docs/audits/original-join-canonical-preparation-20261012/verify.py',
                            '--seal'],
                'expected_status': 0,
                'identity': {'bytes': 3161333,
                             'sha256': 'd069003b9937b0b94a0df8c44ff1716025d1673f3530d62e3a8144f568cefc20'},
                'status': 137,
                'stderr': 'ram-guard: PID 16463; host 78.0%; host cutoff 88%; descendant RSS '
                          'cutoff 4096 MiB; poll 2s\n'
                          'ram-guard: host memory 88.2% reached cutoff 88%\n'
                          'ram-guard: terminating PID tree: 16463 \n',
                'stdout': ''}}

ACTUAL_KEYS = {'candidate_inputs',
 'candidate_inputs_after',
 'command',
 'condition',
 'expected_status',
 'programmes',
 'programmes_after',
 'status',
 'stderr',
 'stderr_path',
 'stdout',
 'stdout_path'}
