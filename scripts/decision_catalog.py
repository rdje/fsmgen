"""Closed decision-store preparation; production readers do not yet use it.

The caller supplies an independently authenticated transition census. This module
checks its originals and prepares a detached catalog, without publishing files,
trusting a caller's copied metadata, or choosing authority from a directory scan.
"""

import hashlib
import json
import posixpath
import re
from pathlib import Path

PARTS = ('continuity', 'language-api', 'verification')
MAX_DOCUMENT_BYTES = 1_048_576
MAX_SOURCE_RECORDS = 256
MAX_CURRENT_RECORDS = 128
MAX_RECORD_BYTES = 65_536
MAX_RECORD_LINES = 640
MAX_LINE_BYTES = 1_024
ID = re.compile(r'[0-9]{4}')
NAME = r'([0-9]{4})(?:-[a-z0-9]+)+\.md'
FLAT = re.compile(r'docs/decisions/' + NAME)
CURRENT = re.compile(r'docs/decisions/current/(' + '|'.join(PARTS) + ')/' + NAME)
LINK = re.compile(r'(\[[^\]\n]*\]\()([^\s)]+)(\))')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def exact_keys(value, keys, label):
    require(type(value) is dict and set(value) == set(keys), f'{label}: unexpected fields')


def bounded_string(value, label, maximum=MAX_LINE_BYTES):
    require(type(value) is str and 0 < len(value.encode('utf-8')) <= maximum
            and not any(c in value for c in '\x00\r\n'), f'{label}: invalid string')
    return value


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f'duplicate JSON key: {key}')
        result[key] = value
    return result


def decode_document(data):
    require(type(data) is bytes and len(data) <= MAX_DOCUMENT_BYTES,
            'catalog document exceeds byte bound')
    return json.loads(data.decode('utf-8'), object_pairs_hook=unique_object)


def detached(value):
    """A plain JSON snapshot prevents mutations or shared references escaping."""
    return decode_document(json.dumps(value, ensure_ascii=False, allow_nan=False).encode('utf-8'))


def read_bytes(root, relative):
    """Reject every symlink component and noncanonical/escaping relative path."""
    bounded_string(relative, 'file path', 512)
    parts = relative.split('/')
    require(not relative.startswith(('/', '~')) and '\\' not in relative
            and all(part and part not in ('.', '..') for part in parts),
            f'unsafe path: {relative}')
    path = Path(root)
    for part in parts:
        path /= part
        require(not path.is_symlink(), f'symlink is not a retained file: {relative}')
    require(path.is_file(), f'unresolved regular source: {relative}')
    with path.open('rb') as stream:
        data = stream.read(MAX_DOCUMENT_BYTES + 1)
    require(len(data) <= MAX_DOCUMENT_BYTES, f'file exceeds reader bound: {relative}')
    return data


def location(path, identity, *, current):
    bounded_string(path, 'decision path', 512)
    require(type(identity) is str and ID.fullmatch(identity) and identity != '0000',
            'invalid decision ID')
    match = (CURRENT if current else FLAT).fullmatch(path)
    require(match is not None, f'unsupported decision location: {path}')
    require(match[2 if current else 1] == identity, f'path borrows another decision ID: {path}')
    return match[1] if current else None


def dimensions(data):
    require(type(data) is bytes, 'record content must be bytes')
    return {'bytes': len(data), 'lines': data.count(b'\n'),
            'line_bytes': max(map(len, data.splitlines()), default=0),
            'sha256': hashlib.sha256(data).hexdigest()}


def verify_content(data, declared, label):
    exact_keys(declared, ('bytes', 'lines', 'line_bytes', 'sha256'), label)
    for key, maximum in (('bytes', MAX_RECORD_BYTES), ('lines', MAX_RECORD_LINES),
                         ('line_bytes', MAX_LINE_BYTES)):
        require(type(declared[key]) is int and 0 < declared[key] <= maximum,
                f'{label}: invalid {key} dimension')
    require(type(declared['sha256']) is str
            and re.fullmatch(r'[0-9a-f]{64}', declared['sha256']), f'{label}: invalid digest')
    require(data.endswith(b'\n') and b'\r' not in data and b'\x00' not in data,
            f'{label}: record must be LF-terminated UTF-8 text')
    text = data.decode('utf-8')
    require(dimensions(data) == declared, f'{label}: record dimensions or digest changed')
    return text


def scalar(text):
    text = text.strip()
    if text.startswith('"'):
        return json.loads(text)
    if text.startswith("'"):
        require(text.endswith("'"), 'unterminated quoted metadata')
        return text[1:-1].replace("''", "'")
    return text


def normalize_links(text, path):
    def replace(match):
        target = match[2]
        if target.startswith(('#', '/')) or re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:', target):
            return match[0]
        destination = posixpath.normpath(posixpath.join(posixpath.dirname(path), target))
        return match[1] + destination + match[3]
    return LINK.sub(replace, text)


def visible_lines(text):
    """Keep Markdown identity outside fenced examples, with exact closing runs."""
    fence = None
    for line in text.splitlines():
        marker = re.match(r'^ {0,3}(`{3,}|~{3,})', line)
        if fence is not None:
            if re.fullmatch(r' {0,3}' + re.escape(fence[0]) + '{' + str(len(fence)) + r',}[ \t]*', line):
                fence = None
            continue
        if marker:
            if marker[1][0] == '`' and '`' in line[marker.end():]:
                yield line
                continue
            fence = marker[1]
            continue
        yield line
    require(fence is None, 'unterminated decision/navigation code fence')


def record_facts(text, path, identity):
    """Extract identity/status/questions and actual headings, excluding code fences."""
    lines = text.splitlines()
    front = {}
    questions = []
    body_start = 0
    if lines and lines[0] == '---':
        require('---' in lines[1:], 'unterminated decision front matter')
        body_start = lines.index('---', 1) + 1
        active = None
        for line in lines[1:body_start - 1]:
            require('\t' not in line, 'tab in decision front matter')
            match = re.fullmatch(r'([a-zA-Z_][a-zA-Z0-9_]*): *(.*)', line)
            if match:
                active, rest = match.groups()
                require(active not in front, f'duplicate front-matter key: {active}')
                front[active] = rest
                if active == 'answers' and rest:
                    questions = json.loads(rest)
            elif active == 'answers':
                item = re.fullmatch(r' +- +(.*)', line)
                require(item is not None, 'malformed decision question list')
                questions.append(scalar(item[1]))
    knowledge_id = scalar(front['id']) if 'id' in front else None
    knowledge_status = scalar(front.get('status', 'current')) if questions else None
    require(type(questions) is list and len(questions) <= 64, 'invalid question population')
    for question in questions:
        bounded_string(question, 'question')
    require(len(set(questions)) == len(questions), 'duplicate decision question')
    require((knowledge_id is None) == (not questions), 'incomplete decision fact identity')
    if knowledge_id is not None:
        bounded_string(knowledge_id, 'knowledge ID', 128)
        require(re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', knowledge_id), 'invalid knowledge ID')
        bounded_string(knowledge_status, 'knowledge status', 128)
    headings, statuses = [], []
    for line in visible_lines('\n'.join(lines[body_start:])):
        if re.match(r'^ {0,3}#{1,6}[ \t]+\S', line):
            bounded_string(line, 'heading')
            headings.append(line)
        if re.match(r'^(?:- )?(?:\*\*)?Status:(?:\*\*)? ', line):
            statuses.append(normalize_links(line, path))
    require(headings and re.match(r'^# (?:Decision )?' + identity + r'(?:\b|:)', headings[0]),
            f'body borrows another decision ID: {identity}')
    require(len(headings) <= 128 and len(statuses) <= 16, 'heading/status population exceeds bound')
    return {'knowledge_id': knowledge_id, 'knowledge_status': knowledge_status,
            'questions': questions, 'authority_status': statuses}, headings


def document_rows(document, label, maximum):
    exact_keys(document, ('schema_version', 'source_revision', 'records'), label)
    require(type(document['schema_version']) is int and document['schema_version'] == 1,
            f'{label}: unsupported schema')
    revision = document['source_revision']
    require(type(revision) is str and re.fullmatch(r'[0-9a-f]{40}', revision),
            f'{label}: invalid source revision')
    rows = document['records']
    require(type(rows) is list and 0 < len(rows) <= maximum, f'{label}: invalid record population')
    identities = [row.get('id') if type(row) is dict else None for row in rows]
    require(all(type(value) is str and ID.fullmatch(value) and value != '0000'
                for value in identities), f'{label}: invalid decision ID')
    require(identities == sorted(set(identities)), f'{label}: duplicate or reordered identities')
    return rows


def prepare(root, source, originals, catalog, *, reader=None):
    """Validate independent source/original closure, then current record bindings.

    `reader` is a bounded bytes accessor for a selected Git snapshot or fixture;
    the default reads regular files beneath `root`. Authentication of the fixed
    source census belongs to the integrating caller, not this preparation API.
    """
    source, originals, catalog = map(detached, (source, originals, catalog))
    source_rows = document_rows(source, 'source census', MAX_SOURCE_RECORDS)
    original_rows = document_rows(originals, 'originals', MAX_SOURCE_RECORDS)
    current_rows = document_rows(catalog, 'current catalog', MAX_CURRENT_RECORDS)
    require(source['source_revision'] == originals['source_revision'] == catalog['source_revision'],
            'source revision substitution')
    require([row['id'] for row in source_rows] == [row['id'] for row in original_rows],
            'original membership differs from source census')
    compatibility, original_text, source_fact_ids = {}, {}, set()
    for row, original in zip(source_rows, original_rows):
        identity = row['id']
        exact_keys(row, ('id', 'path', 'kind', 'part', 'type', 'metadata', 'headings', 'content'), 'source row')
        exact_keys(original, ('id', 'path', 'text'), 'original row')
        location(row['path'], identity, current=False)
        require(row['kind'] in ('sealed', 'current'), 'unknown source record kind')
        require((row['kind'] == 'sealed') == (identity <= '0050'),
                'source kind substitutes published sealed identity')
        require(row['part'] is None if row['kind'] == 'sealed' else row['part'] in PARTS,
                'invalid source semantic partition')
        bounded_string(row['type'], 'decision type', 128)
        require(original['path'] == row['path'] and type(original['text']) is str,
                f'original source path/text substitution: {identity}')
        text = verify_content(original['text'].encode('utf-8'), row['content'], 'original ' + identity)
        metadata, headings = record_facts(text, row['path'], identity)
        require(row['metadata'] == metadata and row['headings'] == headings,
                f'original metadata/headings changed: {identity}')
        knowledge_id = metadata['knowledge_id']
        require(knowledge_id is None or knowledge_id not in source_fact_ids, 'duplicate source knowledge ID')
        if knowledge_id is not None:
            source_fact_ids.add(knowledge_id)
        compatibility[identity] = row
        original_text[identity] = text
    required = {row['id'] for row in source_rows if row['kind'] == 'current'}
    require(required <= {row['id'] for row in current_rows}, 'current catalog omits transition identities')
    read = reader or (lambda path: read_bytes(root, path))
    current, knowledge_ids = {}, set()
    for row in current_rows:
        exact_keys(row, ('id', 'path', 'type', 'metadata', 'content'), 'current row')
        identity = row['id']
        part = location(row['path'], identity, current=True)
        bounded_string(row['type'], 'decision type', 128)
        old = compatibility.get(identity)
        if old:
            require(old['kind'] == 'current', f'current path borrows sealed identity: {identity}')
            require(Path(old['path']).name == Path(row['path']).name and row['type'] == old['type'],
                    f'current path/type substitutes source identity: {identity}')
            require(part == old['part'], f'current path misroutes source semantic partition: {identity}')
        else:
            require(identity > source_rows[-1]['id'], f'fresh path borrows transition ID space: {identity}')
        text = verify_content(read(row['path']), row['content'], 'current ' + identity)
        metadata, _ = record_facts(text, row['path'], identity)
        require(row['metadata'] == metadata, f'current metadata differs from record: {identity}')
        if old:
            prior = old['metadata']
            require(metadata['knowledge_id'] == prior['knowledge_id']
                    and set(prior['questions']) <= set(metadata['questions']),
                    f'current record loses source fact identity/questions: {identity}')
        knowledge_id = metadata['knowledge_id']
        require(knowledge_id is None or knowledge_id not in knowledge_ids, 'duplicate current knowledge ID')
        if knowledge_id is not None:
            knowledge_ids.add(knowledge_id)
        current[identity] = {**row, 'text': text}
    return {'source_revision': source['source_revision'], 'compatibility': compatibility,
            'originals': original_text, 'current': current}


def verify_transition_metadata(prepared):
    """Initial rollover preserves status and complete ordered question metadata."""
    for identity, row in prepared['compatibility'].items():
        if row['kind'] == 'current':
            require(prepared['current'][identity]['metadata'] == row['metadata'],
                    f'transition metadata changed: {identity}')
