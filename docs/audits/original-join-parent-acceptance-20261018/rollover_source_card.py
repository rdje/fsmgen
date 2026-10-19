"""Preserve dated reader-recovery facts and their live query routes exactly."""
import argparse
import base64
import copy
import gzip
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/original-join-parent-acceptance-20261018')
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'


def strict_equal(value, expected):
    """Compare JSON values without Boolean/integer/float coercion."""
    assert type(value) is type(expected), 'JSON value kind'
    if isinstance(expected, dict):
        assert value.keys() == expected.keys(), 'complete object membership'
        for key in expected:
            strict_equal(value[key], expected[key])
    elif isinstance(expected, list):
        assert len(value) == len(expected), 'complete array membership'
        for left, right in zip(value, expected):
            strict_equal(left, right)
    else:
        assert value == expected, 'exact scalar'
    return True


def safe(path):
    """Keep this small currency check inside the primary repository/volume."""
    relative = Path(path)
    assert not relative.is_absolute() and '..' not in relative.parts
    target = ROOT / relative
    device = ROOT.stat().st_dev
    for member in (*reversed(target.parents), target):
        if member == ROOT or not member.is_relative_to(ROOT):
            continue
        assert not member.is_symlink(), 'ordinary same-project archive/input path'
        if member.exists():
            assert member.stat().st_dev == device
            if member.is_dir():
                assert not (member / '.git').exists(), 'no other repository boundary'
                assert not ((member / 'HEAD').exists() and (member / 'objects').exists())
    return target


def read_file(path):
    target = safe(path)
    assert target.is_file()
    return target.read_bytes()


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def unblob(value):
    body = base64.b64decode(value['body_base64'], validate=True)
    strict_equal({key: value[key] for key in ('bytes', 'sha256')},
                 dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest()))
    return body


def save_record(path, value):
    body = (json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False) + '\n').encode()
    with safe(path).open('xb') as stream:
        stream.write(gzip.compress(body, mtime=0))


def command_output(argv):
    result = subprocess.run(argv, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True, timeout=60)
    assert result.returncode == 0 and not result.stderr, (argv, result.returncode, result.stderr)
    return result.stdout


def native_source_reference(revision, path):
    assert path == SOURCE and revision == REVISION
    entry = command_output(['git', '--no-replace-objects', 'ls-tree', '-l', '-z', revision, '--', path])
    rows = entry.rstrip(b'\0').split(b'\0')
    assert len(rows) == 1
    header_, name = rows[0].split(b'\t', 1)
    mode, kind, oid, size = header_.decode().split()
    assert name.decode() == path and mode == '100644' and kind == 'blob' and size.isdecimal()
    return dict(revision=revision, path=path, mode=mode, oid=oid, bytes=int(size),
                retention_contract='fsmgen_required_history')


def native_source_bytes(reference):
    body = command_output(['git', '--no-replace-objects', 'show', reference['revision'] + ':' + reference['path']])
    assert len(body) == reference['bytes']
    assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == reference['oid']
    assert body == command_output(['git', '--no-replace-objects', 'cat-file', 'blob', reference['oid']])
    return body

REVISION = 'e896ee16fa44db13b873f30822a3b26866823574'
SOURCE = 'docs/knowledge/claim-verification-record-enforcement.md'
SOURCE_ID = 'claim-verification-record-enforcement'
SOURCE_SHA = '7748b2db479ffdf559f49ede08335b7418ebecfe979a9a9da973d9e582e2594a'
ARCHIVE = AUDIT / ('source-recovery-card-' + SOURCE_SHA + '.txt')
PATH = AUDIT / 'source-recovery-card-rollover-qualified.json.gz'
REGISTRY = 'doctrine/live_document_size/archive_descriptors.jsonl'
DESCRIPTOR_ID = 'knowledge-original-reader-recovery-20261019'
OWNER = ('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2.3.1')
WRAPPER = 'scripts/check_source_recovery_card.sh'
REPLAY = str(AUDIT / 'verify_claim_readers.sh')
MARKERS = ('CLAIM_VERIFICATION.md', str(ARCHIVE), 'MEMORY.md', TASK, REPLAY + ' --list')
SCOPE = ('Complete original-card byte retention and stable question/query-route preservation only. '
         'Live policy and frontier derive from their canonical owners; dated original-recovery '
         'facts remain in the complete exact source archive. This does not re-adjudicate '
         'their semantic truth, execute original readers or remove historical/native/private '
         'gaps. Source/archive and live front-matter overlap deliberately; no disjoint '
         'partition arithmetic is claimed. Overall Knowledge Map rollover debt remains '
         'open and no allowance or enforcement ceiling grows.')


def dimensions(body):
    return dict(bytes=len(body), lines=body.count(b'\n'), sha256=hashlib.sha256(body).hexdigest(),
                line_bytes=max(map(len, body.split(b'\n')), default=0))


def header(body):
    assert body.startswith(b'---\n')
    end = body.index(b'\n---\n', 4) + len(b'\n---\n')
    return body[:end].decode('utf-8')


def questions(body):
    text = header(body)
    block = re.search(r'^answers:\n((?:  - .*\n)+)', text, re.M)
    assert block, 'complete question front matter'
    result = []
    for line in block[1].splitlines():
        value = line[len('  - '):]
        if value.startswith('"'):
            question = json.loads(value)
        elif value.startswith("'"):
            assert value.endswith("'")
            question = value[1:-1].replace("''", "'")
        else:
            question = value
        assert type(question) is str and question
        result.append(question)
    assert len(result) == len(set(result)), 'unique retained question population'
    return result


def descriptor(original):
    identity = dimensions(original)
    return dict(schema_version=1, record_type='descriptor',
        descriptor_id=DESCRIPTOR_ID, surface_id='exact_history', former_path=SOURCE,
        range_id='complete-source-before-reader-recovery-rollover', revision=REVISION,
        lines=identity['lines'], bytes=identity['bytes'], sha256=SOURCE_SHA,
        retrieval_kind='file', retrieval_locator=str(ARCHIVE), current_pointer=SOURCE,
        sealed_on='2026-10-19', verifier='builtin:file')


def bounded_live_view(original):
    text = header(original)
    text = text.replace('title: Claim evidence legs\n',
                        'title: Claim evidence and original reader recovery\n')
    anchor = '  - "why is the retained preparation correction a no-op?"\n'
    assert text.count(anchor) == 1
    text = text.replace(anchor, anchor + '  - "where are dated reader-recovery facts retained?"\n')
    anchor = '  docs/tasks/CLAIM-VERIFICATION-TEMPLATE-REVIEW.md\n'
    assert text.count(anchor) == 1
    text = text.replace(anchor, anchor.rstrip('\n') + ';\n  ' + str(ARCHIVE) + '; ' + WRAPPER + '\n')
    body = '''
`CLAIM_VERIFICATION.md` owns live policy and registry contracts: distinct
re-derivation, falsification and durability legs, or owned gaps. Structural
checks do not prove semantic truth or oracle independence.

Dated original reader-recovery facts retain in the complete pre-rollover card:
'''
    body += '\n```bash\ncat ' + str(ARCHIVE) + '\n```\n'
    body += '''
The archive preserves every factory/source/intake/cache/compiler fact and its
original scope. Current frontier: read `MEMORY.md`, then its owning leaf in
`docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md`.

List current source-model replay commands with:
'''
    body += '\n```bash\nbash ' + REPLAY + ' --list\n```\n'
    body += '\nThose readers retain their pinned epochs, first failures and native/private gaps.\n'
    return (text + body).encode()


def limits():
    rows = map(json.loads, read_file('doctrine/live_document_size/surfaces.jsonl').splitlines())
    row = next(row for row in rows if row.get('surface_id') == 'knowledge_cards')
    return {key: row['enforcement_ceilings'][key] for key in ('bytes_each', 'lines_each', 'line_bytes_each')}


def selected_descriptor():
    rows = [json.loads(line) for line in read_file(REGISTRY).splitlines()]
    found = [row for row in rows if row.get('descriptor_id') == DESCRIPTOR_ID]
    assert len(found) == 1, 'unique registered source archive'
    return found[0]


def validate(original, archive, current, row, caps):
    assert dimensions(original)['sha256'] == SOURCE_SHA, 'whole original source identity'
    assert archive == original, 'complete source retained byte-for-byte; no fact residue'
    strict_equal(row, descriptor(original))
    original_questions, current_questions = questions(original), questions(current)
    assert set(original_questions) <= set(current_questions), 'every original question remains live'
    assert 'id: ' + SOURCE_ID + '\n' in header(current), 'stable fact identity and query target'
    assert all(marker in current.decode() for marker in MARKERS), 'canonical current/history/replay routes'
    measured = dimensions(current)
    assert all(type(caps[key]) is int and caps[key] > 0 for key in caps)
    assert measured['bytes'] <= caps['bytes_each'], 'live card byte ceiling'
    assert measured['lines'] <= caps['lines_each'], 'live card line ceiling'
    assert measured['line_bytes'] <= caps['line_bytes_each'], 'live card content-line ceiling'
    return dict(source=dimensions(original), archive=dimensions(archive), live=measured,
        original_questions=original_questions, live_questions=current_questions,
        complete_source_identity=True, question_closure=True, unretained_source_bytes=0,
        products_overlap=True, historical_meanings_requalified=False,
        original_execution_permission=False, overall_collection_debt_resolved=False)


def controls(original, archive, current, row, caps):
    result = []
    for label in ('changed_fact', 'truncated_archive', 'lost_question', 'wrong_identity',
                  'lost_new_question', 'lost_history_route', 'wrong_archive_descriptor', 'boolean_dimension', 'unbounded_live_growth'):
        candidate = dict(original=original, archive=archive, current=current, row=copy.deepcopy(row))
        if label == 'changed_fact': candidate['archive'] = archive.replace(b'factory drift', b'factory clean', 1)
        elif label == 'truncated_archive': candidate['archive'] = archive[:-1]
        elif label == 'lost_question':
            question = questions(original)[0]
            candidate['current'] = current.replace(('  - ' + json.dumps(question) + '\n').encode(), b'', 1)
        elif label == 'wrong_identity': candidate['current'] = current.replace(SOURCE_ID.encode(), b'other-fact', 1)
        elif label == 'lost_new_question':
            added = sorted(set(questions(current)) - set(questions(original)))
            assert added
            candidate['current'] = current.replace(('  - ' + json.dumps(added[0]) + '\n').encode(), b'', 1)
        elif label == 'lost_history_route': candidate['current'] = current.replace(str(ARCHIVE).encode(), b'other-archive')
        elif label == 'wrong_archive_descriptor': candidate['row']['sha256'] = '0' * 64
        elif label == 'boolean_dimension': candidate['row']['schema_version'] = True
        else: candidate['current'] = current + b'\n' + b'x' * (caps['bytes_each'] + 1) + b'\n'
        try:
            strict_equal(candidate, dict(original=original, archive=archive, current=current, row=row))
        except AssertionError:
            pass
        else:
            raise AssertionError('control did not change a value or primitive type: ' + label)
        try:
            validate(**candidate, caps=caps)
            live_questions_retained(current, candidate['current'])
        except AssertionError as error:
            result.append(dict(label=label, candidate=dict(original=blob(candidate['original']),
                archive=blob(candidate['archive']), current=blob(candidate['current']),
                row=candidate['row']), refusal=str(error)))
        else: raise AssertionError('lost source/question/route/type/bound admitted: ' + label)
    return result


def public_queries(current):
    result = []
    for question in questions(current):
        command = ['knowledge-map/scripts/query_knowledge_map.sh', '--no-cache', question]
        output = command_output(command)
        expected = '\t'.join((question, SOURCE_ID, SOURCE)).encode()
        assert expected in output.splitlines(), 'actual complete public question route: ' + question
        result.append(dict(question=question, command=command, stdout=blob(output)))
    return result


def current_check(proof):
    saved_check(proof)
    original = unblob(proof['inputs']['original'])
    current = read_file(SOURCE)
    value = validate(original, read_file(ARCHIVE), current, selected_descriptor(), limits())
    live_questions_retained(unblob(proof['inputs']['current']), current)
    public_queries(current)
    return value


def live_questions_retained(initial, current):
    assert set(questions(initial)) <= set(questions(current)), 'all initial live questions, including new archive lookup, remain routed'
    return True


def provenance_check(product):
    original = unblob(product['inputs']['original'])
    expected_reference = dict(revision=REVISION, path=SOURCE, mode='100644',
        oid=hashlib.sha1(b'blob ' + str(len(original)).encode() + b'\0' + original).hexdigest(),
        bytes=len(original), retention_contract='fsmgen_required_history')
    strict_equal(product['native_reference'], expected_reference)
    expected_questions = questions(unblob(product['inputs']['current']))
    assert [row['question'] for row in product['public_queries']] == expected_questions, 'complete captured public query population'
    for row in product['public_queries']:
        assert set(row) == {'question', 'command', 'stdout'}
        strict_equal(row['command'], ['knowledge-map/scripts/query_knowledge_map.sh', '--no-cache', row['question']])
        expected_line = '\t'.join((row['question'], SOURCE_ID, SOURCE)).encode()
        assert expected_line in unblob(row['stdout']).splitlines(), 'captured exact public question target'
    assert product['result']['original_execution_permission'] is False
    assert product['result']['historical_meanings_requalified'] is False
    return True


def receipt_controls(product):
    core = {key: value for key, value in product.items() if key != 'receipt_controls'}
    result = []
    for label in ('wrong_source_revision', 'wrong_source_path', 'wrong_source_object', 'float_source_bytes',
                  'omitted_query_receipt', 'duplicate_query_receipt', 'wrong_query_command',
                  'wrong_query_target', 'borrowed_execution', 'numeric_execution'):
        candidate = copy.deepcopy(core)
        if label == 'wrong_source_revision': candidate['native_reference']['revision'] = '0' * 40
        elif label == 'wrong_source_path': candidate['native_reference']['path'] = 'docs/knowledge/other.md'
        elif label == 'wrong_source_object': candidate['native_reference']['oid'] = '0' * 40
        elif label == 'float_source_bytes': candidate['native_reference']['bytes'] = float(candidate['native_reference']['bytes'])
        elif label == 'omitted_query_receipt': candidate['public_queries'].pop()
        elif label == 'duplicate_query_receipt': candidate['public_queries'].append(copy.deepcopy(candidate['public_queries'][0]))
        elif label == 'wrong_query_command': candidate['public_queries'][0]['command'][1] = '--all'
        elif label == 'wrong_query_target':
            row = candidate['public_queries'][0]
            row['stdout'] = blob(unblob(row['stdout']).replace(SOURCE.encode(), b'docs/knowledge/other.md'))
        elif label == 'borrowed_execution': candidate['result']['original_execution_permission'] = True
        else: candidate['result']['original_execution_permission'] = 0
        try: provenance_check(candidate)
        except AssertionError as error:
            result.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else: raise AssertionError('changed captured source/query provenance admitted: ' + label)
    return result


def saved_check(product):
    assert product['owner'] == OWNER and product['scope'] == SCOPE
    raw = product['inputs']
    original, archive, current = (unblob(raw[key]) for key in ('original', 'archive', 'current'))
    strict_equal(product['result'], validate(original, archive, current, raw['descriptor'], raw['caps']))
    strict_equal(product['controls'], controls(original, archive, current, raw['descriptor'], raw['caps']))
    provenance_check(product)
    strict_equal(product['receipt_controls'], receipt_controls(product))
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--prepare', action='store_true')
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--current', action='store_true')
    args = parser.parse_args()
    if args.prepare:
        reference = native_source_reference(REVISION, SOURCE)
        original = native_source_bytes(reference)
        assert dimensions(original)['sha256'] == SOURCE_SHA and read_file(SOURCE) == original
        assert not safe(ARCHIVE).exists()
        new = bounded_live_view(original)
        assert len(new) < len(original), 'reviewed bounded live survivor must actually shrink'
        with safe(ARCHIVE).open('xb') as stream: stream.write(original)
        safe(SOURCE).write_bytes(new)
        print('Prepared exact full-source archive and bounded current card; register its descriptor/currency route, regenerate the Knowledge Map and capture before claiming delivery.')
    elif args.write:
        reference = native_source_reference(REVISION, SOURCE)
        original = native_source_bytes(reference)
        archive, current, row, caps = read_file(ARCHIVE), read_file(SOURCE), selected_descriptor(), limits()
        assert current == bounded_live_view(original), 'whole reviewed initial current view'
        result = validate(original, archive, current, row, caps)
        product = dict(owner=OWNER, scope=SCOPE, result=result,
            inputs=dict(original=blob(original), archive=blob(archive), current=blob(current), descriptor=row, caps=caps),
            native_reference=reference, controls=controls(original, archive, current, row, caps),
            public_queries=public_queries(current),
            programmes={name: blob(read_file(name)) for name in (str(AUDIT / 'rollover_source_card.py'), WRAPPER)})
        assert provenance_check(product)
        product['receipt_controls'] = receipt_controls(product)
        save_record(PATH, product)
        print('Complete native source/archive identity, all retained public question routes and genuine fact/question/route/type/size controls qualify the bounded live card. Overall debt and original semantic/native gaps retain.')
    else:
        product = json.loads(gzip.decompress(read_file(PATH)))
        if args.current:
            current_check(product)
            print('source-recovery-card: exact retained source, live original questions, current canonical/replay routes and public query results hold')
        else:
            current_check(product)
            print('Saved full-source retention and control replay agree; current original-question routes hold independently of later frontier or question additions.')
