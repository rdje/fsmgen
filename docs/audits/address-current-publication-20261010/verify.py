"""Independently reconstruct whole publication/history/source/native delivery."""
import copy
import hashlib
import json
import re
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path

sys.path.insert(0, str(Path('scripts').resolve()))
import check_record_value_publication as current

BASE = Path('docs/audits/address-current-publication-20261010')
REVISION = '924a2a1b7236ce2312d79953b1c98511016e6d25'
PROPOSAL = 'docs/audits/address-publication-preparation-20261010/proposal.json'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args, data=None):
    result = subprocess.run(['git', '--no-replace-objects', *args], input=data, capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'whole independent publication Git source')
    return result.stdout


def objects(paths, revision=REVISION):
    output = git('cat-file', '--batch', data=''.join(revision + ':' + p + '\n' for p in paths).encode())
    result, offset = {}, 0
    for path in paths:
        end = output.index(b'\n', offset)
        _, kind, length = output[offset:end].split()
        need(kind == b'blob', 'complete original publication blob kind')
        offset, length = end + 1, int(length)
        result[path] = output[offset:offset + length]
        need(output[offset + length:offset + length + 1] == b'\n', 'whole original publication framing')
        offset += length + 1
    need(offset == len(output), 'complete independent original publication consumption')
    return result


def metrics(rows):
    raw = list(rows.values())
    return dict(files=len(raw), bytes_total=sum(map(len,raw)), lines_total=sum(r.count(b'\n') for r in raw),
        bytes_each=max(map(len,raw)), lines_each=max(r.count(b'\n') for r in raw),
        line_bytes_each=max(len(line.rstrip(b'\r')) for r in raw for line in r.split(b'\n')))


def counts(rows):
    return {key: metrics(rows)[key] for key in ('files', 'bytes_total', 'lines_total')}


class Visible(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def native(html, blocks):
    parsed = Visible()
    parsed.feed(html)
    visible = ' '.join(''.join(parsed.parts).split())
    for block in blocks:
        text = block.replace('```bash\n','').replace('```sh\n','').replace('```\n','').replace('`','')
        need(' '.join(text.split()) in visible, 'whole native current scope and remaining gaps')


def allocation(canonical):
    """Parse the whole front-matter answer language independently of the index."""
    questions = {}
    for path, raw in canonical.items():
        match = re.match(r'\A---\n(.*?)\n---(?:\n|\Z)', raw.decode(), re.S)
        if not match:
            continue
        front = match[1]
        values = []
        for answers in re.finditer(r'^answers:[ \t]*(.*)$', front, re.M):
            if answers[1]:
                values.extend(json.loads(answers[1]))
                continue
            rest = front[answers.end():].lstrip('\n')
            for line in rest.splitlines():
                if not line.startswith((' ', '\t')):
                    break
                row = re.fullmatch(r' +\- +(.*)', line)
                need(row is not None, 'independent complete question-list grammar')
                values.append(row[1].strip(' ').removeprefix('"').removesuffix('"'))
        if not values:
            continue
        identifiers = re.findall(r'^id: (.+)$', front, re.M)
        need(len(identifiers) == 1, 'independent unique complete source identity')
        identifier = identifiers[0].strip().strip('"')
        for question in values:
            questions.setdefault(question, []).append((identifier, path))
    return ''.join(question + '\t' + ','.join(i for i, p in sorted(members)) + '\t'
                   + ','.join(p for i, p in sorted(members)) + '\n'
                   for question, members in sorted(questions.items()))


PROGRAMMES = ['scripts/check_record_value_publication.py', 'scripts/record_value_coordinate_fact.py',
              'scripts/record_value_address_fact.py', 't/python/test_record_value_current_publication.py',
              str(BASE / 'capture.py')]
QUALIFICATION_SCOPE = 'Authenticate complete admitted finite source/holder/numerical preparation and actual results; no fresh semantic recapture or native identity.'


def source_check(captured, canonical, proposal, qualification):
    need(type(captured) is dict and set(captured) == {'record', 'qualification', 'programmes', 'role'}
         and captured['role'] == 'actual complete current source/query input; no original recapture',
         'closed whole current address capture and role')
    record = captured['record']
    need(type(record) is dict and set(record) == {'cards', 'chapter', 'tooling_chapter', 'queries',
         'census', 'surface', 'source_members', 'source_budget'}, 'closed complete current address input')
    wanted = {path: row['text'] for path, row in proposal['cards'].items()}
    need(record['cards'] == wanted and all(canonical[path].decode() == text for path, text in wanted.items()),
         'whole four-card approved address source and meaning epoch')
    need(same(record['source_members'], {path: {k: pin(raw)[k] for k in ('bytes', 'sha256')}
                                       for path, raw in canonical.items()}), 'whole independent current canonical population')
    physical = {path: raw for path, raw in canonical.items() if Path(path).parent == Path('docs/knowledge')}
    need(same(record['census'], metrics(physical)), 'whole independently measured current card dimensions')
    need(type(record['queries']) is dict and set(record['queries']) == {'direct', 'cached'},
         'complete current address query roles')
    global_rows = allocation(canonical)
    for role, actual in record['queries'].items():
        need(type(actual) is dict and set(actual) == {'command', 'status', 'stdout', 'stderr'}
             and type(actual['status']) is int and actual['status'] == 0, 'actual distinct typed current query success')
        command = ['knowledge-map/scripts/query_knowledge_map.sh', '--all'] + (['--no-cache'] if role == 'direct' else [])
        need(actual['command'] == command and type(actual['stdout']) is str and actual['stderr'] == '',
             'actual distinct current query command and streams')
        need(actual['stdout'] == global_rows, 'whole independent current global question allocation')
    need(set(captured['programmes']) == set(PROGRAMMES) and same(captured['programmes'],
         {path: {k: pin(Path(path).read_bytes())[k] for k in ('bytes', 'sha256')} for path in PROGRAMMES}),
         'complete actual current programme epoch')
    need(same(captured['qualification'], qualification), 'whole independent admitted address qualification')


def receipt(actual, command, stdout=None, saved_sources=None):
    need(type(actual) is dict and set(actual) == {'command', 'status', 'stdout', 'stderr', 'instruments'}
         and type(actual['status']) is int and actual['status'] == 0, 'actual publication integer success')
    need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', *command], 'whole actual publication command')
    paths = {str(BASE / 'checks.py'), 'scripts/run_with_ram_guard.sh'} | {path for path in command if Path(path).is_file()}
    saved = saved_sources or {}
    need(same(actual['instruments'], {path: {k: pin(saved.get(path, Path(path).read_bytes()))[k]
         for k in ('bytes', 'sha256')} for path in paths}), 'whole actual publication instruments')
    need(type(actual['stdout']) is str and type(actual['stderr']) is str
         and 'host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s' in actual['stderr'],
         'whole actual publication streams and unchanged guard')
    if stdout is not None:
        need(actual['stdout'] == stdout, 'whole actual publication stdout')
    if command[:3] == ['python3', '-B', 'scripts/check_record_value_publication.py']:
        need(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', actual['stderr']),
             'exact complete current-reader guard stream')


def main():
    preparation = current.address_fact.PREPARATION
    admitted_paths = git('ls-tree', '-r', '--name-only', REVISION, '--', preparation).decode().splitlines()
    canonical_paths = sorted(path for path in git('ls-tree', '-r', '--name-only', REVISION, '--',
                             'docs/knowledge', 'docs/decisions').decode().splitlines() if path.endswith('.md'))
    book_paths = sorted(path for path in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                        if path.endswith('.md') and Path(path).parent == Path('docs/book/src'))
    before = objects(sorted(set(canonical_paths + book_paths + admitted_paths + [
        'doctrine/live_document_size/surfaces.jsonl', 'doctrine/live_document_size/archive_descriptors.jsonl',
        'scripts/check_record_value_publication.py'])))
    need(all(Path(path).read_bytes() == before[path] for path in admitted_paths),
         'every whole admitted preparation member remains exact')
    proposal = json.loads(before[PROPOSAL])
    original_inputs = objects(sorted(proposal['fixed_members']), proposal['revision'])
    need(same(proposal['fixed_members'], {path: pin(raw) for path, raw in original_inputs.items()}),
         'complete independently reconstructed dated address input population')
    for path, raw in original_inputs.items():
        retained = proposal['beforeimages'].get(path)
        need(Path(retained['locator'] if retained else path).read_bytes() == raw,
             'every retained beforeimage and original address input conserves')
    qualification = {'proposal': pin(before[PROPOSAL]), 'definitive_proof': pin(before[preparation + '/final-proof.json']),
        'complete_members': {path: pin(before[path]) for path in admitted_paths},
        'dated_inputs': {path: pin(raw) for path, raw in original_inputs.items()}, 'scope': QUALIFICATION_SCOPE}
    need(same(qualification, current.address_fact.authenticate()), 'whole independent current address authentication')
    canonical = {path: Path(path).read_bytes() for path in canonical_paths}
    need(sorted(canonical) == sorted(current.sources()), 'complete independently selected current canonical population')
    need([path for path in canonical_paths if canonical[path] != before[path]] == sorted(proposal['cards']),
         'only exact reviewed address canonical cards change')
    product = json.loads((BASE / 'publication.json').read_bytes())
    need(set(product) == {'revision', 'owner', 'proposal', 'cards', 'descriptors', 'original_descriptor_bytes',
                         'chapters', 'book_replacements', 'book_before', 'book_after', 'authenticated_qualification', 'scope'}
         and product['revision'] == REVISION and product['owner'] == (BASE / 'scope.txt').read_text().strip()
         and product['proposal'] == pin(before[PROPOSAL])
         and product['scope'] == 'Atomic finite address current card/reader/history/source/book publication; complete address-container acceptance and native identity remain separately owned.',
         'closed exact atomic address publication and scope')
    need(same(product['cards'], {path: pin(canonical[path]) for path in proposal['cards']})
         and all(canonical[path] == row['text'].encode() for path, row in proposal['cards'].items()),
         'all complete reviewed address card bytes admitted')
    expected_descriptors = []
    for path, row in proposal['cards'].items():
        raw = before[path]
        need(raw == Path(row['original']['locator']).read_bytes() and pin(raw) == row['original']['identity'],
             'complete dated original address card history')
        expected_descriptors.append({'schema_version': 1, 'record_type': 'descriptor',
            'descriptor_id': 'address-current-' + Path(path).stem + '-20261010',
            'surface_id': 'exact_history', 'former_path': path,
            'range_id': 'complete-card-before-qualified-finite-address-admission', 'revision': proposal['revision'],
            **pin(raw), 'retrieval_kind': 'file', 'retrieval_locator': row['original']['locator'],
            'current_pointer': path, 'sealed_on': '2026-10-10', 'verifier': 'builtin:file'})
    descriptor_path = 'doctrine/live_document_size/archive_descriptors.jsonl'
    need(product['descriptors'] == expected_descriptors and product['original_descriptor_bytes'] == pin(before[descriptor_path])
         and Path(descriptor_path).read_bytes() == before[descriptor_path] + ''.join(
             json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n' for row in expected_descriptors).encode(),
         'whole exact governed address history and prior descriptor prefix')
    book = {path: Path(path).read_bytes() for path in book_paths}
    need(book_paths == sorted(str(path) for path in Path('docs/book/src').glob('*.md')),
         'whole unchanged current book population')
    feature, reference = 'docs/book/src/13k-isf-feature-support-matrix.md', 'docs/book/src/90-reference-map.md'
    prior = current.historical()
    old = {'__name__': 'original_address_current', '__file__': 'scripts/check_record_value_publication.py'}
    exec(compile(before[old['__file__']], old['__file__'], 'exec'), old)
    preparation_block = before[preparation + '/book-addition.md.txt'].decode()
    replacements = {feature: [(old['guide'](prior), current.guide(prior)),
        (preparation_block, 'Retained address preparation checkpoint (before current admission):\n\n' + preparation_block)],
        reference: [(current.coordinate_fact.REFERENCE, 'Retained original-coordinate publication checkpoint:\n\n'
                     + current.coordinate_fact.REFERENCE + current.address_fact.REFERENCE)]}
    need(same(product['book_replacements'], replacements) and set(product['chapters']) == {feature, reference}
         and [path for path in book_paths if book[path] != before[path]] == sorted((feature, reference)),
         'whole explicit reviewed address book transformation scope')
    for path, pairs in replacements.items():
        expected = before[path].decode()
        for a, b in pairs:
            need(expected.count(a) == 1, 'unique complete original address book seam')
            expected = expected.replace(a, b, 1)
        row = product['chapters'][path]
        need(row == {'before': pin(before[path]), 'after': pin(book[path]), 'original': before[path].decode(), 'current': expected}
             and book[path].decode() == expected, 'whole exact original and current address book sources')
    need(same(product['book_before'], counts({path: before[path] for path in book_paths}))
         and same(product['book_after'], counts(book)), 'complete independent typed book measurements')
    captured = json.loads((BASE / 'current-input-final.json').read_bytes())
    source_check(captured, canonical, proposal, qualification)
    current.check(captured['record'], canonical, prior, current.authority(prior))
    need(same(product['authenticated_qualification'], qualification), 'complete atomic admission qualification epoch')
    feature_html = Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()
    reference_html = Path('docs/book/book/90-reference-map.html').read_text()
    native(feature_html, [current.guide(prior), current.coordinate_fact.PARSER_GUIDE])
    native(reference_html, [current.coordinate_fact.REFERENCE, current.address_fact.REFERENCE])
    current.check_native(feature_html, prior); current.check_tooling_native(reference_html, prior)
    current.plane.check(current.plane.expected_rows(), 'docs/book/book')
    old_registry = list(map(json.loads, before['doctrine/live_document_size/surfaces.jsonl'].splitlines()))
    registry = list(map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()))
    need([row.get('surface_id') for row in old_registry] == [row.get('surface_id') for row in registry],
         'whole unchanged address publication capacity population')
    for old_row, row in zip(old_registry, registry):
        expected = copy.deepcopy(old_row)
        if row.get('surface_id') == 'shipped_behavior':
            change = {'authority_id': 'ADDRESS-CURRENT-PUBLICATION-20261010',
                'baseline': product['book_before'],
                'delta': {k: product['book_after'][k] - value for k, value in product['book_before'].items()},
                'owner': (BASE / 'scope.txt').read_text().strip(),
                'rationale': 'Publish exact reviewed finite address cards and current-reader authentication with complete governed beforeimages, preserved questions and unchanged Knowledge Map authority; native identity and final container closure remain separately owned.'}
            need(same(row['reference_contract']['aggregate_change'], change),
                 'exact complete owned address book aggregate authority')
            expected['reference_contract']['aggregate_change'] = change
        if row.get('surface_id') == 'task_evidence':
            task_paths = sorted({path for pattern in row['targets'] for path in Path('.').glob(pattern)})
            measured = metrics({str(path): path.read_bytes() for path in task_paths})
            task = json.loads((BASE / 'task-metrics.json').read_bytes())
            need(same(task['actual'], measured), 'complete exact current task measurements')
            expected['transition']['max_growth'] = {k: max(0, min(value + row['transition']['ratchet_step'][k],
                row['enforcement_ceilings'][k]) - row['baseline'][k]) for k, value in measured.items()}
        need(same(expected, row), 'only exact owned book and task authority changes')
    checks = json.loads((BASE / 'checks.json').read_bytes())
    commands = {
        'publish': ['python3', '-B', str(BASE / 'publish.py'), 'scripts/check_record_value_publication.py', 'scripts/record_value_address_fact.py'],
        'preparation-snapshot': ['python3', '-B', preparation + '/verify.py', '--snapshot'],
        'focused-signoff': ['prove', '-Iperl', 't/2066-record-value-current-publication.t', 't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
        'current': ['python3', '-B', 'scripts/check_record_value_publication.py'],
        'capture-final': ['python3', '-B', str(BASE / 'capture.py')],
        'allocation-repair-commit': ['python3', '-B', str(BASE / 'verify_allocation.py')],
        'source-current': ['python3', '-B', 'scripts/book_source_references.py', '--check'],
        'book-build-commit': ['mdbook', 'build', 'docs/book'],
        'current-native-commit': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
        'task-pressure-final-state': ['python3', '-B', str(BASE / 'task_pressure.py')],
        'claims-final-state': ['perl', 'scripts/check_claim_verification_inventory.pl', '--write']}
    for name, command in commands.items():
        saved = None
        if name in ('publish', 'current'):
            source = 'admission-current-reader.py.txt' if name == 'publish' else 'first-native-current-reader.py.txt'
            saved = {'scripts/check_record_value_publication.py': (BASE / source).read_bytes()}
        receipt(checks[name], command, current.SUCCESS if name in ('current', 'current-native-commit') else None, saved)
    first_native = checks['current-native']
    first_source = (BASE / 'first-native-current-reader.py.txt').read_bytes()
    need(type(first_native['status']) is int and first_native['status'] == 1
         and first_native['stderr'].endswith('ValueError: native complete current retained scope and gaps\n')
         and first_native['instruments']['scripts/check_record_value_publication.py'] ==
             {k: pin(first_source)[k] for k in ('bytes', 'sha256')},
         'complete actual retained first native text-boundary refusal')
    retained_native = (BASE / 'first-native-13k-isf-feature-support-matrix.html.txt').read_text()
    need(retained_native == feature_html and (BASE / 'first-native-90-reference-map.html.txt').read_text() == reference_html,
         'whole rendered native input unchanged through text extraction repair')
    initial = {'__name__': 'first_native_reader', '__file__': 'scripts/check_record_value_publication.py'}
    exec(compile(first_source, initial['__file__'], 'exec'), initial)
    try:
        initial['check_native'](retained_native, prior)
    except ValueError as error:
        need(str(error) == 'native complete current retained scope and gaps', 'exact first native refusal reproduces')
    else:
        raise ValueError('actual first native failure did not reproduce')
    repair = json.loads((BASE / 'allocation-repair-commit.json').read_bytes())
    need(repair['final_programme'] == pin(Path(__file__).read_bytes())
         and repair['first_programme'] == pin((BASE / 'first-verify.py.txt').read_bytes())
         and repair['harness'] == pin((BASE / 'verify_allocation.py').read_bytes())
         and repair['complete_rows'] == pin(allocation(canonical).encode()),
         'whole retained actual repeated-answer source-language repair')
    need('All tests successful.' in checks['focused-signoff']['stdout'] and 'Files=3, Tests=310' in checks['focused-signoff']['stdout'],
         'whole actual focused address publication regression')
    controls = []
    def reject(name, mutate, cause):
        candidate = copy.deepcopy(captured); mutate(candidate)
        need(not same(candidate, captured), 'genuine complete current address challenge: ' + name)
        try:
            source_check(candidate, canonical, proposal, qualification)
        except ValueError as error:
            need(str(error) == cause, 'intended whole address publication refusal: ' + name + ': ' + str(error))
            controls.append({'name': name, 'refusal': cause, 'whole_candidate': pin(json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('false-green whole current address challenge: ' + name)
    core = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
    reject('native-capture-role', lambda p: p.update(role='Original native objects recaptured'), 'closed whole current address capture and role')
    reject('unknown-native-field', lambda p: p['record'].update(native_identity=True), 'closed complete current address input')
    reject('lost-card', lambda p: p['record']['cards'].pop(core), 'whole four-card approved address source and meaning epoch')
    reject('borrowed-core', lambda p: p['record']['cards'].update({core: before[core].decode()}), 'whole four-card approved address source and meaning epoch')
    reject('native-promotion', lambda p: p['record']['cards'].update({core: re.sub(r'cross-call/capture\s+reuse\s+stay\s+opaque', 'cross-call reuse proves native identity', p['record']['cards'][core])}), 'whole four-card approved address source and meaning epoch')
    reject('lost-source', lambda p: p['record']['source_members'].pop(next(iter(canonical))), 'whole independent current canonical population')
    reject('Boolean-source-bytes', lambda p: next(iter(p['record']['source_members'].values())).update(bytes=True), 'whole independent current canonical population')
    reject('Boolean-census', lambda p: p['record']['census'].update(files=True), 'whole independently measured current card dimensions')
    reject('lost-query-role', lambda p: p['record']['queries'].pop('direct'), 'complete current address query roles')
    for role in ('direct', 'cached'):
        reject('Boolean-query-' + role, lambda p: p['record']['queries'][role].update(status=False), 'actual distinct typed current query success')
        reject('lost-global-query-' + role, lambda p: p['record']['queries'][role].update(stdout=p['record']['queries'][role]['stdout'].split('\n', 1)[1]), 'whole independent current global question allocation')
    reject('borrowed-query-command', lambda p: p['record']['queries']['direct'].update(command=p['record']['queries']['cached']['command']), 'actual distinct current query command and streams')
    reject('lost-programme', lambda p: p['programmes'].pop('scripts/record_value_address_fact.py'), 'complete actual current programme epoch')
    reject('borrowed-definitive-proof', lambda p: p['qualification'].update(definitive_proof=pin(before[preparation + '/proof.json'])), 'whole independent admitted address qualification')
    reject('native-authentication-scope', lambda p: p['qualification'].update(scope='Fresh native address lifetime capture'), 'whole independent admitted address qualification')
    for name, html, blocks in (
        ('lost-native-operation-holder', feature_html.replace('main::call_api', 'borrowed::call_api'), [current.address_fact.GUIDE]),
        ('promoted-native-current-scope', reference_html.replace('Certificate authentication supplies no fresh semantic recapture.', 'Original native captures supply complete identity.'), [current.address_fact.REFERENCE])):
        try:
            native(html, blocks)
        except ValueError as error:
            controls.append({'name': name, 'refusal': str(error), 'whole_candidate': pin(html.encode())})
        else:
            raise ValueError('false-green native address publication control: ' + name)
    actual = checks['current-native-commit']
    command = commands['current-native-commit']
    for name, mutate, cause in (
        ('Boolean-current-native-status', lambda p: p.update(status=False), 'actual publication integer success'),
        ('float-current-native-status', lambda p: p.update(status=0.0), 'actual publication integer success'),
        ('borrowed-current-native-command', lambda p: p.update(command=checks['current']['command']), 'whole actual publication command'),
        ('short-current-native-output', lambda p: p.update(stdout='PASS\n'), 'whole actual publication stdout'),
        ('extra-current-native-stderr', lambda p: p.update(stderr=p['stderr'] + 'borrowed warning\n'), 'exact complete current-reader guard stream'),
        ('unknown-current-native-field', lambda p: p.update(native_identity=True), 'actual publication integer success')):
        candidate = copy.deepcopy(actual); mutate(candidate)
        need(not same(candidate, actual), 'genuine whole actual-result challenge: ' + name)
        try:
            receipt(candidate, command, current.SUCCESS)
        except ValueError as error:
            need(str(error) == cause, 'intended actual-result refusal: ' + name)
            controls.append({'name': name, 'refusal': cause, 'whole_candidate': pin(json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('false-green whole actual-result challenge: ' + name)
    proof = {'scope': product['scope'], 'revision': REVISION, 'publication': pin((BASE / 'publication.json').read_bytes()),
             'current_input': pin((BASE / 'current-input-final.json').read_bytes()), 'controls': controls,
             'programmes': {path: pin(Path(path).read_bytes()) for path in PROGRAMMES + [str(BASE / 'verify.py'), str(BASE / 'publish.py')]},
             'qualification': qualification,
             'legs': {'rederive': 'Complete fixed Git preparation/original inputs and governed beforeimages; independently parsed whole current global question language and physical/book/source allocation.',
                      'falsify': 'Genuine whole card/source/kind/query/borrowed-proof/scope/ownership/role/native interventions and complete independent current source/query/native checks.',
                      'durability': 'Full exact publication/current inputs, programme epochs, actual receipts, genuine control hashes, task/book/Git checkpoint.'},
             'missing_legs': 'Manual reviewed natural-language correspondence is not a universal theorem. Authentication is not semantic recapture. Full address-container acceptance, native identity and visual QA remain owned.'}
    target = BASE / 'final-proof.json'
    need(not target.exists() or same(json.loads(target.read_bytes()), proof), 'whole immutable independent address publication proof')
    if not target.exists():
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete atomic finite address current source/query/history/book/native publication and genuine controls; full container acceptance remains pending.')


if __name__ == '__main__':
    main()
