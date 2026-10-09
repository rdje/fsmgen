"""Independent Git-blob custody and complete original allocation reconstruction."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-original-intake-20261009')
A = Path('docs/audits')
REVISION = '390e4dda5eea6efac6637e65921524194a4aa68b'
CLASS = A / 'record-value-class-frame-join-20261006'
SOURCE = A / 'coordinate-source-hypotheses-20261009'
CAPTURE = A / 'record-value-original-candidate-20261004'
ROLE = 'Complete original raw/source custody and lossless allocation only; coordinate selection and private/framework/formatter/toolchain/address/alias meanings remain successor-owned.'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'independent fixed original source')
    return run.stdout


def load(path):
    raw = git('show', REVISION + ':' + str(path))
    need(raw == path.read_bytes(), 'independent whole original declaration')
    return json.loads(raw)


def expected_custody():
    prior, source = load(CLASS / 'binding.json'), load(SOURCE / 'qualification.json')
    selected = sorted(set(prior['inputs']) | set(source['custody']['roots']) | {
        str(CLASS), str(A / 'class-frame-join-checks-20261006'), str(SOURCE),
        str(A / 'coordinate-source-hypothesis-checks-20261009'), str(A / 'archive-transport-fact-20261009')})
    entries = {}
    for row in git('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *selected).rstrip(b'\0').split(b'\0'):
        metadata, name = row.split(b'\t',1)
        mode, kind, oid = metadata.decode().split()
        need(kind == 'blob' and mode in ('100644','100755') and name.decode() not in entries, 'independent unique regular Git membership')
        entries[name.decode()] = {'mode': mode, 'oid': oid}
    # Request and consume one object at a time. Writing all requests before
    # draining stdout could deadlock the bidirectional pipe on this corpus.
    child = subprocess.Popen(['git','--no-replace-objects','cat-file','--batch'],
                             stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    members = {}
    try:
        for name, entry in entries.items():
            child.stdin.write((entry['oid']+'\n').encode()); child.stdin.flush()
            oid, kind, amount = child.stdout.readline().split()
            need(oid.decode() == entry['oid'] and kind == b'blob', 'independent complete Git blob header')
            amount = int(amount)
            path = ROOT / name
            need(path.resolve() == path and path.is_file() and path.stat().st_dev == ROOT.stat().st_dev,
                 'independent plain same-volume original member')
            for parent in path.parents:
                if parent == ROOT:
                    break
                need(not (parent / '.git').exists(), 'independent own repository boundary')
            digest, remaining = hashlib.sha256(), amount
            with path.open('rb') as live:
                while remaining:
                    raw = child.stdout.read(min(1048576, remaining))
                    need(raw and live.read(len(raw)) == raw, 'independent whole original byte conservation')
                    digest.update(raw); remaining -= len(raw)
                need(not live.read(1) and child.stdout.read(1) == b'\n', 'independent complete original blob framing')
            members[name] = {**entry, 'identity': {'bytes': amount, 'sha256': digest.hexdigest()}}
        child.stdin.close()
        need(not child.stdout.read(1), 'independent complete Git blob stream')
        stderr = child.stderr.read(); status = child.wait()
        need(status == 0 and not stderr, 'independent actual Git blob success')
    except BaseException:
        child.terminate(); child.wait()
        raise
    finally:
        if not child.stdin.closed:
            child.stdin.close()
        child.stdout.close(); child.stderr.close()
    for name in selected:
        p = Path(name)
        live = {str(x) for x in p.rglob('*') if x.is_file() or x.is_symlink()} if p.is_dir() else {name}
        need(live == {x for x in members if x == name or x.startswith(name+'/')}, 'independent complete namespace closure')
    return {'revision': REVISION, 'roots': selected, 'members': members}


def grammar(body):
    segments, offset = [], 0
    for raw in body.splitlines(keepends=True):
        text = raw.removesuffix('\n')
        row = {'kind': 'message', 'offset_bytes': offset, 'raw': raw, 'bytes': len(raw.encode())}
        prefix, separator, tail = text.rpartition(' called at ')
        path, marker, number = tail.rpartition(' line ')
        decimal = lambda value: bool(value) and all('0' <= c <= '9' for c in value)
        if prefix.startswith('\t') and len(prefix) > 1 and separator and path and marker and decimal(number):
            row.update(kind='frame', call=prefix[1:], path=path, line=int(number))
        else:
            before, at, rest = text.partition(' at ')
            file, line, number = rest.rpartition(' line ')
            if at and file and line and number.endswith('.') and decimal(number[:-1]):
                row.update(kind='origin', path=file, line=int(number[:-1]))
            elif not text:
                row['kind'] = 'blank'
        segments.append(row); offset += row['bytes']
    need(''.join(r['raw'] for r in segments) == body and offset == len(body.encode()), 'independent exact physical body reconstruction')
    opaque = [{'start_bytes': len(body[:m.start()].encode()), 'end_bytes': len(body[:m.end()].encode()),
               'lexeme': m.group()} for m in re.finditer(r'0x[0-9a-fA-F]+', body)]
    return {'segments': segments, 'opaque_lexemes': opaque}


def raw_inventory():
    rebuilt = []
    for mode in ('ordinary','storable','controls'):
        original = load(CAPTURE / (mode+'.json'))
        domains = {}
        for domain in ('api','copies','parses','test_run'):
            rows = original[domain] if domain != 'test_run' else [original[domain]]
            empty, nonempty = [], []
            for index, row in enumerate(rows):
                error = row['error']
                need(type(error) is str, 'independent original serialized error kind')
                if error == '':
                    empty.append(index)
                else:
                    nonempty.append({'index': index, 'wire_kind': 'string', 'body': error,
                        'body_identity': pin(error.encode()),
                        'context': {k:row[k] for k in ('kind','caller','helper','parse') if k in row}, **grammar(error)})
            domains[domain] = {'population': len(rows), 'empty_string_members': empty, 'nonempty': nonempty}
        rebuilt.append({'mode': mode, 'domains': domains})
    need(rebuilt == load(CLASS / 'raw-product.json')['inventories'], 'whole independently reconstructed original raw inventory')
    result = []
    for mode in rebuilt:
        domains = {}
        for name, rows in mode['domains'].items():
            domains[name] = {k:rows[k] for k in ('population','empty_string_members')}
            domains[name]['nonempty'] = [{'index': r['index'], 'whole_body': r['body_identity'],
                'whole_record': pin(json.dumps(r,sort_keys=True).encode()), 'original_selection': None} for r in rows['nonempty']]
        result.append({'mode': mode['mode'], 'domains': domains})
    return result


def actual_readers():
    results = []
    for name,path in (('source-hypotheses',A/'coordinate-source-hypothesis-checks-20261009/verify_hypotheses.py'),
                      ('class-frame',CLASS/'verify.py'), ('archive-policy',A/'archive-transport-fact-20261009/archive.py')):
        command = ['python3','-B',str(path)]
        run = subprocess.run(command,capture_output=True,text=True)
        need(run.returncode == 0 and not run.stderr, 'independent actual unchanged reader: '+name)
        results.append({'name':name,'command':command,'status':run.returncode,
                        'stdout':run.stdout,'stderr':run.stderr,'programme':pin(path.read_bytes())})
    return results


def check(candidate, expected, modes, regenerated):
    need(set(candidate) == {'role','owner','custody','allocation','actual_readers','legs'}
         and candidate['owner'] == (BASE/'scope.txt').read_text().strip(), 'closed original-intake owner and properties')
    need(candidate['role'] == ROLE and candidate['allocation']['scope'] == ROLE, 'original-intake conditional scope')
    need(set(candidate['custody']) == {'revision','roots','members','transport'} and set(candidate['allocation']) == {
        'modes','raw_product','source_models','class_frame_qualification','source_hypotheses','complete_capture','unresolved','scope'},
        'closed complete original-intake custody and allocation')
    for key in expected:
        need(candidate['custody'][key] == expected[key], 'complete independently authenticated custody: '+key)
    transport = candidate['custody']['transport']
    need(transport == {'command':['git','--no-replace-objects','-c','tar.umask=0022','--literal-pathspecs',
        'archive','--format=tar',REVISION,'--',*expected['roots']],'status':0,'stderr':''}
        and type(transport['status']) is int, 'exact original-intake archive transport receipt')
    need(candidate['allocation']['modes'] == modes, 'complete independently reconstructed allocation')
    for mode in candidate['allocation']['modes']:
        for domain in mode['domains'].values():
            need(type(domain['population']) is int and all(type(i) is int for i in domain['empty_string_members']), 'original-intake discrete allocation kinds')
            need(all(type(r['index']) is int and r['original_selection'] is None for r in domain['nonempty']), 'unselected complete original coordinate scope')
    source = load(SOURCE / 'qualification.json')
    need(candidate['allocation']['unresolved'] == source['unresolved'], 'all original private/framework/address/alias owners retained')
    need(candidate['allocation']['complete_capture'] == load(CLASS / 'binding.json')['original_capture'], 'whole original capture custody including separately owned alias')
    for key, path in (('raw_product',CLASS/'raw-product.json'), ('source_models',CLASS/'source-models.json'),
                      ('class_frame_qualification',CLASS/'proofs.json'), ('source_hypotheses',SOURCE/'qualification.json')):
        need(candidate['allocation'][key] == pin(git('show', REVISION+':'+str(path))), 'complete original product reference: '+key)
    readers = candidate['actual_readers']
    declared = [('source-hypotheses',A/'coordinate-source-hypothesis-checks-20261009/verify_hypotheses.py'),
                ('class-frame',CLASS/'verify.py'), ('archive-policy',A/'archive-transport-fact-20261009/archive.py')]
    need(len(readers) == len(declared), 'complete actual original-intake reader population')
    for row, (name,path) in zip(readers,declared,strict=True):
        need(row['name'] == name and row['command'] == ['python3','-B',str(path)], 'exact actual original-intake reader role and command')
        need(type(row['status']) is int and row['status'] == 0 and row['stderr'] == '' and type(row['stdout']) is str and row['stdout'], 'complete actual original-intake reader success')
        need(row['programme'] == pin(path.read_bytes()), 'exact actual original-intake reader programme')
    need(readers == regenerated, 'complete independently regenerated actual reader results')


def main():
    candidate = json.loads((BASE/'admission.json').read_bytes())
    expected, modes = expected_custody(), raw_inventory()
    regenerated = actual_readers()
    check(candidate, expected, modes, regenerated)
    controls = {}
    for name, mutate, cause in (
        ('missing-member',lambda p:p['custody']['members'].pop(next(iter(p['custody']['members']))),'complete independently authenticated custody: members'),
        ('borrowed-source',lambda p:next(iter(p['custody']['members'].values()))['identity'].update(sha256='0'*64),'complete independently authenticated custody: members'),
        ('omitted-empty',lambda p:p['allocation']['modes'][0]['domains']['copies']['empty_string_members'].pop(),'complete independently reconstructed allocation'),
        ('borrowed-body',lambda p:p['allocation']['modes'][0]['domains']['api']['nonempty'][0]['whole_body'].update(sha256='0'*64),'complete independently reconstructed allocation'),
        ('coordinate-promotion',lambda p:p['allocation']['modes'][0]['domains']['api']['nonempty'][0].update(original_selection='first'),'complete independently reconstructed allocation'),
        ('Boolean-population',lambda p:p['allocation']['modes'][0]['domains']['test_run'].update(population=True),'original-intake discrete allocation kinds'),
        ('lost-private-owner',lambda p:p['allocation']['unresolved'].pop('original_private_formatter_toolchain_identity'),'all original private/framework/address/alias owners retained'),
        ('false-green-result',lambda p:p['actual_readers'][0].update(status=True),'complete actual original-intake reader success'),
        ('borrowed-stdout',lambda p:p['actual_readers'][0].update(stdout='PASS\n'),'complete independently regenerated actual reader results'),
        ('borrowed-command',lambda p:p['actual_readers'][0]['command'].append('--foreign'),'exact actual original-intake reader role and command')):
        bad = copy.deepcopy(candidate); mutate(bad)
        try:
            check(bad, expected, modes, regenerated)
        except ValueError as error:
            need(str(error) == cause, 'intended independent original-intake control: '+name)
            controls[name] = str(error)
        else:
            raise ValueError('false-green original-intake control: '+name)
    print(json.dumps({'result':'PASS complete independent original custody, lossless raw allocation and unselected scope',
        'custody':pin(json.dumps(expected,sort_keys=True).encode()), 'allocation':pin(json.dumps(modes,sort_keys=True).encode()),
        'controls':controls, 'actual_readers':regenerated},sort_keys=True))


if __name__ == '__main__':
    main()
