"""Admit reviewed coordinate facts and authenticate their complete dated proof.

The current reader consumes the original successful independent qualification
and reauthenticates all its inputs. It does not recapture an original execution
or pretend that a certificate check is a fresh semantic reconstruction.
"""
import hashlib
import json
import runpy
from pathlib import Path

import book_source_references as plane

REVISION = 'ca3dfac9d35b76d0a08fd97161fb0bef6570cd10'
PREPARATION = 'docs/audits/coordinate-current-preparation-20261010'
PROPOSAL = PREPARATION + '/proposal.json'
PROPOSAL_SHA256 = 'afd4ca5605d5698aed4bd921a21fabc3792ce89780a2fb8e8e4ca2086226ead1'
PARSER = 'docs/knowledge/isf-record-output-source-contexts.md'
READER = 'docs/audits/coordinate-original-hostile-checks-20261009/verify_hostile.py'
READER_SHA256 = 'd8896635f86ff82b50504b67844a219d96eb19a81872a2b445c554beaf1c5ed5'
PRODUCT = 'docs/audits/coordinate-original-hostile-20261009'
CHECKS = 'docs/audits/coordinate-original-hostile-independent-checks-20261009/checks.json'
CHECKS_SHA256 = '277eb742f2522e88fdd3231bde81ff55cdb464be34b70128cc3c7100bfb87552'
CUSTODY_IDENTITY = {'bytes': 1494222, 'sha256': 'ef91e337648c3e04be3b0faccfa8dfbcaf131457097820471147833ec6f1c941'}
QUESTION = 'what qualifies original own caller and source coordinates?'

GUIDE = '''Original own caller and source coordinates now have a separate complete
qualification. Source recipes bind every original error origin, own caller and
inherited inner coordinate without normalizing raw bytes or equivalent labels.
Nested forwarding preserves its inner and outer phases. Genuine line, filename
and source-association controls preserve the complete prior class, frame and
visible-argument meanings before both coordinate procedures reject the changed
association. Independent reconstruction qualifies the whole result and original
custody, including genuine omission and borrowed-result controls. Earlier
construction failures and RAM stops remain non-success evidence.

The maintained reader authenticates that complete admitted qualification and
every original input. It does not recapture original executions or claim a new
semantic reconstruction merely from certificate authentication. Core, helper,
parser and tooling facts retain every prior question, probe and locality rule;
their reviewed working set does not grow. Original private formatting, toolchain
and identity, external framework coordinates and address lifetimes retain their
separate owners. Whole current publication is independently qualified after a fresh complete
semantic replay. Exact source history, all questions, native guidance and
unchanged capacities conserve; broader private and downstream owners stay open.

'''

PARSER_GUIDE = '''The parser source and frame publication below is a retained checkpoint.
It qualifies the original source inventory, source-expression roles, visible
function and argument footprints, complete own operation/helper/subtest phases
and completed nested allocations. False denotes a source predicate, while
reference kinds and prefixes do not establish referents or hidden suffixes.
Its earlier `--current` role checks its dated card, question and book epoch:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-path-publication-20261006/verify.py --current
```

For current parser facts and original own coordinates, use the complete
maintained current reader above. Its native variant checks every current copied
source and the rendered guidance. Default parser replay preserves its original
sources and saved publication snapshot; historical success supplies no current
currency:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-path-publication-20261006/verify.py
```

Framework/provider, formatter, scalar encoding, hidden identity, external
coordinates and addresses remain unmeasured or separately owned. Visual QA
remains pending.

'''

REFERENCE = '''Current coordinate meanings are now admitted together in the core, helper,
parser and tooling facts. Their exact original sources remain retrievable, and
the reviewed correspondence preserves every original question, probe and locality
obligation. Knowledge Map collection authority is unchanged; the complete
working set does not grow. The original private, framework, formatter, toolchain,
identity and address limits remain explicit.

The maintained reader checks all affected current sources and the complete
global direct and cached question allocation. It authenticates the admitted
whole original qualification and every fixed input, while retaining distinct
historical, current, borrowed and unrelated source roles. A successful dated
snapshot cannot establish current currency. The parser checkpoint keeps its
sealed earlier epoch-current programme and default historical snapshot; its
current fact now uses the maintained reader.

Build first, then check the complete native publication from the repository root:

```sh
mdbook build docs/book
scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py --build docs/book/book
```

This checks all current copied canonical sources and the rendered guidance.
The unchanged dated semantic reconstruction command above remains available.
The complete preparation also remains replayable in its explicit snapshot role:

```sh
python3 -B docs/audits/coordinate-current-preparation-20261010/verify.py --snapshot
```

Whole current-coordinate publication is independently qualified after a fresh
complete original semantic replay. Exact prior/proposed/current sources, every
question and probe, whole book/native guidance and unchanged capacities join.
Only completed coordinate nodes close. Original private, framework, formatter,
toolchain, identity, address and alias meanings, visual QA, HIAL repair and full
CI/push retain their owners. Raw address roles are the next owned scope.

The dated whole-publication proof remains replayable independently of later
current source progress:

```sh
python3 -B docs/audits/coordinate-current-closure-20261010/verify.py
```

'''


def require(ok, cause):
    if not ok:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def local(path, maximum):
    return plane.local_read(plane.ROOT / plane.relative(path), maximum)


def proposal():
    raw = local(PROPOSAL, plane.SOURCE_BYTES)
    require(hashlib.sha256(raw).hexdigest() == PROPOSAL_SHA256, 'complete admitted coordinate proposal')
    return json.loads(raw)


def cards(previous):
    admitted = proposal()
    require(set(previous) == set(admitted['cards']) - {PARSER}, 'complete predecessor current card population')
    for path, text in previous.items():
        expected = admitted['cards'][path]['original']
        require(pin(text.encode()) == {k: expected[k] for k in ('bytes', 'sha256')},
                'complete retained predecessor current meanings')
    result = {}
    for path, row in admitted['cards'].items():
        original = local(row['locator'], plane.SOURCE_BYTES)
        require(pin(original) == {k: row['original'][k] for k in ('bytes', 'sha256')},
                'complete original coordinate card history')
        require(pin(row['text'].encode()) == {k: row['proposal'][k] for k in ('bytes', 'sha256')},
                'complete admitted coordinate card bytes')
        result[path] = row['text']
    return result


def guide(previous):
    old = 'The current route checks all three complete canonical cards, actual direct and'
    end = 'opaque inner-frame bytes passes those local meanings but breaks whole forwarding.\n\n'
    gaps = 'hidden arguments, identity, coordinates and address/lifetime meanings remain\n'
    require(previous.count(old) == previous.count(end) == previous.count(gaps) == 1,
            'complete retained class/frame guide seams')
    return previous.replace(old, old.replace('three', 'four'), 1).replace(end, end + GUIDE, 1).replace(
        gaps, gaps.replace('identity, coordinates', 'identity, external coordinates'), 1)


def check_actual(actual, qualified):
    require(type(actual['status']) is int and actual['status'] == 0,
            'actual independent coordinate integer success')
    require(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', READER],
            'complete actual independent coordinate command')
    require(type(actual['stdout']) is str and type(actual['stderr']) is str
            and 'host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s' in actual['stderr'],
            'complete independent coordinate streams and guard')
    result = json.loads(actual['stdout'])
    require(set(result) == {'result', 'whole_qualification', 'actual_matching_reader', 'coverage', 'controls'}
            and result['result'] == 'PASS complete independent original-coordinate hostile qualification and predecessor preservation',
            'complete independent coordinate result scope')
    require(same(result['whole_qualification'], pin(json.dumps(qualified, sort_keys=True).encode()))
            and same(result['actual_matching_reader'], qualified['actual_matching_reader']),
            'whole independent coordinate product and prerequisite result')
    records = {(mode['mode'], domain, row['index']) for mode in qualified['original']['inventories']
               for domain, values in mode['domains'].items() for row in values['nonempty']}
    coverage = dict(points=len(qualified['points']), source_recipe_modes=len(qualified['representatives']),
                    semantic_controls=len(qualified['controls']), forwarding_pairs=len(qualified['forwarding']),
                    intervened_records=len(records))
    require(same(result['coverage'], coverage), 'complete typed independent coordinate coverage')
    fields = {'lost-point': 'points', 'lost-source-recipe': 'representatives', 'borrowed-intervention': 'controls',
              'false-green-prior': 'controls', 'lost-forwarded-pair': 'forwarding', 'lost-empty': 'original',
              'Boolean-reader-status': 'actual_matching_reader', 'borrowed-reader-command': 'actual_matching_reader',
              'borrowed-reader-stdout': 'actual_matching_reader'}
    require(result['controls'] == {name: 'complete independent hostile field: ' + field for name, field in fields.items()},
            'complete independent coordinate whole-result controls')


def authenticate():
    """Reauthenticate the exact admitted original proof and all current input bytes."""
    receipt_bytes = local(CHECKS, plane.SOURCE_BYTES)
    require(hashlib.sha256(receipt_bytes).hexdigest() == CHECKS_SHA256,
            'complete committed independent coordinate receipts')
    reader_bytes = local(READER, plane.SOURCE_BYTES)
    require(hashlib.sha256(reader_bytes).hexdigest() == READER_SHA256,
            'unchanged published original coordinate reader')
    reader = runpy.run_path(str(plane.ROOT / READER))
    reader['authenticate'](Path(PRODUCT))
    seal = json.loads(local(PRODUCT + '/seal.json', plane.SOURCE_BYTES))
    qualified = json.loads(local(PRODUCT + '/qualification.json', seal['qualification.json']['bytes']))
    for path, expected in qualified['inputs'].items():
        require(pin(local(path, expected['bytes'])) == expected, 'whole original coordinate source/matching inputs')
    custody_path = 'docs/audits/coordinate-original-intake-20261009/admission.json'
    custody_bytes = local(custody_path, CUSTODY_IDENTITY['bytes'])
    require(pin(custody_bytes) == CUSTODY_IDENTITY, 'complete fixed original custody source')
    custody = json.loads(custody_bytes)['custody']
    require(pin(json.dumps(custody, sort_keys=True).encode()) == qualified['original_custody'],
            'complete original coordinate custody allocation')
    for path, member in custody['members'].items():
        require(pin(local(path, member['identity']['bytes'])) == member['identity'],
                'every unchanged original coordinate custody member')
    actual = json.loads(receipt_bytes)['published-independent']
    check_actual(actual, qualified)
    for path, expected in actual['instruments'].items():
        require(pin(local(path, expected['bytes'])) == expected, 'whole original independent coordinate instruments')
    reader['authenticate'](Path(PRODUCT))
    return dict(whole_qualification=json.loads(actual['stdout'])['whole_qualification'],
                custody=qualified['original_custody'], actual_receipts=pin(receipt_bytes))
